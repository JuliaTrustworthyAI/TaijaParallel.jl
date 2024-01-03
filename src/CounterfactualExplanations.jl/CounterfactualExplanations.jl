using CounterfactualExplanations
using CounterfactualExplanations: generate_counterfactual
using CounterfactualExplanations.Evaluation: evaluate
using Logging
using ProgressMeter

include("assign_traits.jl")
include("threads/threads.jl")