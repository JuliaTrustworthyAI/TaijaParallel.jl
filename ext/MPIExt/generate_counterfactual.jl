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
    verbose::Bool = false,
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

    # Setup:
    storage_path = tempdir()

    # For each chunk:
    for (i, chunk) in enumerate(chunks)
        worker_chunk = TaijaParallel.split_obs(chunk, parallelizer.n_proc)
        worker_chunk = MPI.scatter(worker_chunk, parallelizer.comm)
        if !isempty(worker_chunk)
            worker_chunk = stack(worker_chunk; dims = 1)
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
            @info "No data to process for worker $(parallelizer.rank)"
            output = nothing
        end
        MPI.Barrier(parallelizer.comm)

        # Collect output from all processe in rank 0:
        @info "Rank $(parallelizer.rank): Collecting output ..."
        collected_output = MPI.gather(output, parallelizer.comm)
        if parallelizer.rank == 0
            @info "Rank $(parallelizer.rank): length of collected_output: $(length(collected_output))"
            output = reduce(vcat, collected_output)
            output = filter(!isnothing, output)
            @info "Rank $(parallelizer.rank): Length of filtered output: $(length(output))"
            Serialization.serialize(joinpath(storage_path, "output_$i.jls"), output)
        end
        # MPI.Barrier(parallelizer.comm)
    end

    MPI.Barrier(parallelizer.comm)

    # Load output from rank 0:
    if parallelizer.rank == 0
        output = []
        for i = 1:length(chunks)
            batch = Serialization.deserialize(joinpath(storage_path, "output_$i.jls"))
            @info "Rank $(parallelizer.rank): Batch $i has length: $(length(batch))"
            output = vcat(output..., batch...)
        end
        @info "Rank $(parallelizer.rank): Length of loaded output: $(length(output))"
    else
        output = nothing
    end

    # Broadcast total number of outputs first
    num_outputs = parallelizer.rank == 0 ? length(output) : 0
    num_outputs = MPI.bcast(num_outputs, parallelizer.comm; root=0)

    # Broadcast each output
    final_output = []
    for i = 1:num_outputs
        if parallelizer.rank == 0
            @info "Rank $(parallelizer.rank): Broadcasting output ($i/$num_outputs) to all processes ..."
            batch = output[i]
            @info "Batch shape: $(size(batch))"
            batch = MPI.bcast(batch, parallelizer.comm; root = 0)
        else
            batch = MPI.bcast(nothing, parallelizer.comm; root=0)
        end
        push!(final_output, batch)
    end

    MPI.Barrier(parallelizer.comm)

    return final_output
end