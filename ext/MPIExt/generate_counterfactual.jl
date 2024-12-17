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
    storage_path = mkpath(joinpath(parallelizer.save_dir,parallelizer.rank))

    # For each chunk:
    for (i, chunk) in enumerate(chunks)
        worker_chunk = TaijaParallel.split_obs(chunk, parallelizer.n_proc)
        worker_chunk = MPI.scatter(worker_chunk, parallelizer.comm)
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
        MPI.Barrier(parallelizer.comm)

        # Collect output from all processe in rank 0:
        collected_output = MPI.gather(output, parallelizer.comm)
        output = vcat(collected_output...)
        Serialization.serialize(joinpath(storage_path, "output_$i.jls"), output)
        MPI.Barrier(parallelizer.comm)
    end

    # Collect all chunks in rank 0:
    MPI.Barrier(parallelizer.comm)

    outputs = []
    for i = 1:length(chunks)
        output = Serialization.deserialize(joinpath(storage_path, "output_$i.jls"))
        push!(outputs, output)
    end
    # Collect output from all processes in rank 0:
    output = vcat(outputs...)
    
    MPI.Barrier(parallelizer.comm)

    return final_output
end
