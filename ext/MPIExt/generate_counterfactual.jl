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
    @assert !isa(args[3], AbstractArray) "Cannot generate counterfactuals for mutliple datasets in parallel."
    @assert !isa(args[4], AbstractArray) "Cannot generate counterfactuals for mutliple models in parallel."
    generator = args[5] |> x -> isa(x, AbstractArray) ? x : fill(x, length(counterfactuals))

    # Break down into chunks:
    args = zip(counterfactuals, target, generator)
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
        worker_chunk = stack(worker_chunk; dims = 1)
        _x, _target, _generator = worker_chunk
        if !parallelizer.threaded
            if parallelizer.rank == 0 && verbose
                # Generating counterfactuals with progress bar:
                output = []
                @showprogress desc = "Generating counterfactuals using MPI ..." for x in zip(
                    _x, _target, fill(data, length(_generator)), fill(M, length(_generator)), _generator,
                )
                    with_logger(NullLogger()) do
                        push!(output, f(x...; kwargs...))
                    end
                end
            else
                # Generating counterfactuals without progress bar:
                output = with_logger(NullLogger()) do
                    f.(_x, _target, data, M, _generator; kwargs...)
                end
            end
        else
            # Parallelize further with `Threads.@threads`:
            second_parallelizer = ThreadsParallelizer()
            output = TaijaBase.parallelize(
                second_parallelizer,
                f,
                _x, _target, data, M, _generator;
                kwargs...,
            )
        end
        MPI.Barrier(parallelizer.comm)

        # Collect output from all processe in rank 0:
        collected_output = MPI.gather(output, parallelizer.comm)
        if parallelizer.rank == 0
            output = vcat(collected_output...)
            Serialization.serialize(joinpath(storage_path, "output_$i.jls"), output)
        end
        MPI.Barrier(parallelizer.comm)
    end

    # Collect all chunks in rank 0:
    MPI.Barrier(parallelizer.comm)

    # Load output from rank 0:
    if parallelizer.rank == 0
        outputs = []
        for i = 1:length(chunks)
            output = Serialization.deserialize(joinpath(storage_path, "output_$i.jls"))
            push!(outputs, output)
        end
        # Collect output from all processes in rank 0:
        output = vcat(outputs...)
    else
        output = nothing
    end

    # Broadcast output to all processes:
    final_output = MPI.bcast(output, parallelizer.comm; root = 0)
    MPI.Barrier(parallelizer.comm)

    return final_output
end
