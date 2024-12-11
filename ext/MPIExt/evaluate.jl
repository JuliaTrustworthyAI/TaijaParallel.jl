"""
    TaijaBase.parallelize(
        parallelizer::MPIParallelizer,
        f::typeof(CounterfactualExplanations.Evaluation.evaluate),
        args...;
        kwargs...,
    )

Parallelizes the evaluation of the `CounterfactualExplanations.Evaluation.evaluate` function. This function is used to evaluate the performance of a counterfactual explanation method. 
"""
function TaijaBase.parallelize(
    parallelizer::MPIParallelizer,
    f::typeof(CounterfactualExplanations.Evaluation.evaluate),
    args...;
    verbose::Bool = false,
    kwargs...,
)

    # Setup:
    n_each = parallelizer.n_each

    # Extract positional arguments:
    counterfactuals = args[1] |> x -> TaijaBase.vectorize_collection(x)
    # Get meta data if supplied:
    if length(args) > 1
        meta_data = args[2]
    else
        meta_data = nothing
    end
    meta_data =
        isa(meta_data, AbstractArray) ? meta_data : fill(meta_data, length(counterfactuals))

    # Break down into chunks:
    args = zip(counterfactuals, meta_data)
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
            worker_chunk = stack(worker_chunk; dims=1)
            @info "Rank $(parallelizer.rank) is evaluating $(length(worker_chunk)) samples..."
            @info "Rank $(parallelizer.rank) using multi-threading: parallelizer.threaded"
            if !parallelizer.threaded
                if parallelizer.rank == 0 && verbose
                    # Generating counterfactuals with progress bar:
                    output = []
                    @showprogress desc = "Evaluating counterfactuals ..." for x in zip(
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
            @info "Rank $(parallelizer.rank): Output generated. Gathering ..."
        else
            @info "No data to evaluate for worker $(parallelizer.rank)"
            output = nothing
        end
        @info "Rank $(parallelizer.rank): Output generated and gathered. Waiting at barrier ..."
        MPI.Barrier(parallelizer.comm)

        # Collect output from all processe in rank 0:
        @info "Rank $(parallelizer.rank): Collecting output ..."
        collected_output = MPI.gather(output, parallelizer.comm)
        if parallelizer.rank == 0
            output = vcat(collected_output...)
            output = filter(!isnothing, output)
            Serialization.serialize(joinpath(storage_path, "output_$i.jls"), output)
        end
        # MPI.Barrier(parallelizer.comm)
    end

    # Collect all chunks in rank 0:
    MPI.Barrier(parallelizer.comm)

    # Load output from rank 0:
    if parallelizer.rank == 0
        output = []
        for i = 1:length(chunks)
            batch = Serialization.deserialize(joinpath(storage_path, "output_$i.jls"))
            output = vcat(output..., batch)
        end
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
            batch = MPI.bcast(batch, parallelizer.comm; root=0)
            push!(final_output, batch)
        else
            batch = MPI.bcast(nothing, parallelizer.comm; root=0)
        end
    end

    MPI.Barrier(parallelizer.comm)

    return final_output
end
