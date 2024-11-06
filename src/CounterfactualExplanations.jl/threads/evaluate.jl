import TaijaBase

"""
    TaijaBase.parallelize(
        parallelizer::ThreadsParallelizer,
        f::typeof(CounterfactualExplanations.Evaluation.evaluate),
        args...;
        kwargs...,
    )

Parallelizes the evaluation of `f` using `Threads.@threads`. This function is used to evaluate counterfactual explanations.
"""
function TaijaBase.parallelize(
    parallelizer::ThreadsParallelizer,
    f::typeof(CounterfactualExplanations.Evaluation.evaluate),
    args...;
    verbose::Bool = true,
    kwargs...,
)

    # Setup:
    counterfactuals = args[1] |> x -> TaijaBase.vectorize_collection(x)

    # Get meta data if supplied:
    if length(args) > 1
        meta_data = args[2]
    else
        meta_data = nothing
    end

    # Check meta data:
    if typeof(meta_data) <: AbstractArray
        meta_data = TaijaBase.vectorize_collection(meta_data)
        @assert length(meta_data) == length(counterfactuals) "The number of meta data must match the number of counterfactuals."
    else
        meta_data = fill(meta_data, length(counterfactuals))
    end

    # Bundle arguments:
    args = zip(counterfactuals, meta_data)

    # Preallocate:
    evaluations = Vector{Vector}(undef, length(args))

    # Verbosity:
    if verbose
        prog = ProgressMeter.Progress(
            length(counterfactuals);
            desc = "Evaluating counterfactuals ...",
            showspeed = true,
            color = :green,
        )
    end

    # Training: Use @spawn to dynamically schedule tasks
    tasks = []

    # Iterate with index to preserve order
    for (i, (ce, meta)) in enumerate(args)
        # Each task will execute this function dynamically on an available thread
        task = Threads.@spawn begin
            evaluation = f(ce, meta; kwargs...)
            evaluations[i] = evaluation         # Store result in the correct position
            if verbose
                ProgressMeter.next!(prog)
            end
        end
        push!(tasks, task)
    end

    # Wait for all tasks to complete
    for task in tasks
        fetch(task)
    end

    return evaluations
end
