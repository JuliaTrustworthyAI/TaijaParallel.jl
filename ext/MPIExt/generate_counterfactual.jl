using CounterfactualExplanations
using MLUtils: stack
using Serialization

"""
    TaijaBase.parallelize(
        parallelizer::MPIParallelizer,
        f::typeof(CounterfactualExplanations.generate_counterfactual),
        args...;
        kwargs...,
    )

Parallelizes the `CounterfactualExplanations.generate_counterfactual` function using `MPI.jl`. This function is used to generate counterfactual explanations.
"""
function TaijaBase.parallelize(
    parallelizer::MPIParallelizer,
    f::typeof(CounterfactualExplanations.generate_counterfactual),
    args...;
    verbose::Bool=false,
    kwargs...,
)

    # Setup:
    n_each = parallelizer.n_each

    # Extract positional arguments:
    counterfactuals = args[1] |> x -> TaijaBase.vectorize_collection(x)
    target = args[2] |> x -> isa(x, AbstractArray) ? x : fill(x, length(counterfactuals))
    data = args[3] |> x -> isa(x, AbstractArray) ? x : fill(x, length(counterfactuals))
    M = args[4] |> x -> isa(x, AbstractArray) ? x : fill(x, length(counterfactuals))
    generator = args[5] |> x -> isa(x, AbstractArray) ? x : fill(x, length(counterfactuals))

    # Break down into chunks:
    args = zip(counterfactuals, target, data, M, generator)
    if !isnothing(n_each)
        chunks = chunk_obs(args, n_each, parallelizer.n_proc)
    else
        chunks = [collect(args)]
    end

    @debug "Rank $(parallelizer.rank): Total number of chunks: $(length(chunks))"
    meminfo_julia()
    @debug "Rank $(parallelizer.rank): Waiting at barrier ..."
    MPI.Barrier(parallelizer.comm)

    # Setup:
    storage_path = parallelizer.storage_dir

    # For each chunk:
    for (i, chunk) in enumerate(chunks)
        @debug "Rank $(parallelizer.rank): Number elements in `chunk`: $(length(chunk))."
        worker_chunks = TaijaParallel.split_obs(chunk, parallelizer.n_proc)
        worker_chunk = worker_chunks[parallelizer.rank+1]
        @debug "Rank $(parallelizer.rank): Number elements in `worker_chunk`: $(length(worker_chunk))."
        @debug "Rank $(parallelizer.rank): Generating ..."
        if !isempty(worker_chunk)
            worker_chunk = stack(worker_chunk; dims=1)
            if !parallelizer.threaded
                if parallelizer.rank == 0 && verbose
                    # Generating counterfactuals with progress bar:
                    output = []
                    @showprogress desc = "Generating counterfactuals ..." for x in zip(
                        eachcol(worker_chunk)...,
                    )
                        with_logger(NullLogger()) do
                            push!(output, f(x...; kwargs...))
                        end
                    end
                else
                    # Generating counterfactuals without progress bar:
                    output = with_logger(NullLogger()) do
                        f.(eachcol(worker_chunk)...; kwargs...)
                    end
                end
            else
                # Parallelize further with `Threads.@threads`:
                second_parallelizer = ThreadsParallelizer()
                output = TaijaBase.parallelize(
                    second_parallelizer,
                    f,
                    eachcol(worker_chunk)...;
                    kwargs...,
                )
            end
        else
            @debug "No data to process for worker $(parallelizer.rank)"
            output = nothing
        end
        local_storage = mkpath(joinpath(storage_path, "local"))
        Serialization.serialize(joinpath(local_storage, "output_rank_$(parallelizer.rank).jls"), output)
        @debug "Rank $(parallelizer.rank) waiting at barrier ..."
        MPI.Barrier(parallelizer.comm)

        # Collect output from all processe in rank 0:
        if parallelizer.rank == 0
            collected_output = []
            for fname in readdir(local_storage)
                _output = Serialization.deserialize(joinpath(local_storage, fname))
                push!(collected_output, _output)
            end
            rm(local_storage; recursive=true)
            @debug "Rank $(parallelizer.rank): length of collected_output: $(length(collected_output))"
            output = reduce(vcat, collected_output)
            output = filter(!isnothing, output)
            @debug "Rank $(parallelizer.rank): Length of filtered output: $(length(output))"
            for j in 1:parallelizer.n_proc
                Serialization.serialize(joinpath(storage_path, "output_$(i)_$(j-1).jls"), output)
            end
            collected_output = nothing
        end

        output = nothing
        worker_chunks = nothing
    end

    n_chunks = length(chunks)
    chunks = nothing
    args = nothing
    @debug "Rank $(parallelizer.rank) Done processing all iterations. Processing output data..."
    meminfo_julia()
    MPI.Barrier(parallelizer.comm)

    outputs = []
    for i = 1:n_chunks
        batch = Serialization.deserialize(joinpath(storage_path, "output_$(i)_$(parallelizer.rank).jls"))
        rm(joinpath(storage_path, "output_$(i)_$(parallelizer.rank).jls"))
        @debug "Rank $(parallelizer.rank): Batch ($i/$(n_chunks)) has length: $(length(batch))"
        push!(outputs, batch)
    end
    # Collect output from all processes in rank 0:
    output = vcat(outputs...)

    return output

end