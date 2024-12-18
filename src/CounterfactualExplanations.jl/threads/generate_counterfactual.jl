import TaijaBase

"""
    TaijaBase.parallelize(
        parallelizer::ThreadsParallelizer,
        f::typeof(CounterfactualExplanations.generate_counterfactual),
        args...;
        kwargs...,
    )

Parallelizes the evaluation of `f` using `Threads.@threads`. This function is used to generate counterfactual explanations.
"""
function TaijaBase.parallelize(
    parallelizer::ThreadsParallelizer,
    f::typeof(CounterfactualExplanations.generate_counterfactual),
    args...;
    verbose::Bool = true,
    kwargs...,
)

    # Extract positional arguments:
    counterfactuals = args[1] |> x -> TaijaBase.vectorize_collection(x)
    target = args[2] |> x -> isa(x, AbstractArray) ? x : fill(x, length(counterfactuals))
    data = args[3] |> x -> isa(x, AbstractArray) ? x : fill(x, length(counterfactuals))
    M = args[4] |> x -> isa(x, AbstractArray) ? x : fill(x, length(counterfactuals))
    generator = args[5] |> x -> isa(x, AbstractArray) ? x : fill(x, length(counterfactuals))

    # Break down into chunks:
    args = zip(counterfactuals, target, data, M, generator)

    # Preallocate a vector for storing results in the original order
    ces = Vector{CounterfactualExplanations.AbstractCounterfactualExplanation}(undef, length(args))

    # Verbosity setup:
    if verbose
        prog = ProgressMeter.Progress(
            length(args);
            desc="Generating counterfactuals using multi-threading ...",
            showspeed=true,
            color=:green,
        )
    end

    # Training: Use @spawn to dynamically schedule tasks
    tasks = []

    # Iterate with index to preserve order
    for (i, (x, target, data, M, generator)) in enumerate(args)
        # Each task will execute this function dynamically on an available thread
        task = Threads.@spawn begin
            ce = with_logger(NullLogger()) do
                f(x, target, data, M, generator; kwargs...)
            end
            ces[i] = ce  # Store result in the correct position
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

    return ces
end
