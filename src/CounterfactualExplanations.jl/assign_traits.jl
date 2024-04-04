"The `generate_counterfactual` method is parallelizable."
TaijaBase.ProcessStyle(
    ::Type{<:typeof(CounterfactualExplanations.generate_counterfactual)},
) = TaijaBase.IsParallel()

"The `evaluate` function is parallelizable."
function TaijaBase.ProcessStyle(
    ::Type{<:typeof(CounterfactualExplanations.Evaluation.evaluate)},
)
    return TaijaBase.IsParallel()
end
