using CounterfactualExplanations
using CounterfactualExplanations: counterfactual
using CounterfactualExplanations.DataPreprocessing: CounterfactualData
using CounterfactualExplanations.Convergence
using CounterfactualExplanations.Evaluation: benchmark
using CounterfactualExplanations.Models
using Logging
using TaijaData
using TaijaParallel
using Test

data = TaijaData.load_linearly_separable()
counterfactual_data = CounterfactualData(data[1], data[2])

M = fit_model(counterfactual_data, :MLP)
conv = DecisionThresholdConvergence(decision_threshold = 0.95)
generator = GenericGenerator()
factual = 1
target = 2
chosen = rand(findall(predict_label(M, counterfactual_data) .== factual), 1000)
xs = select_factual(counterfactual_data, chosen)

# No parallelizer
parallelizer = nothing
ces = @with_parallelizer parallelizer begin
    generate_counterfactual(
        xs,
        target,
        counterfactual_data,
        M,
        generator;
        convergence = conv,
        initialization = :identity,
    )
end

# Threads
parallelizer = ThreadsParallelizer()
ces_threads = @with_parallelizer parallelizer begin
    generate_counterfactual(
        xs,
        target,
        counterfactual_data,
        M,
        generator;
        convergence = conv,
        initialization = :identity,
    )
end

# MPI
using MPI
MPI.Init()
parallelizer = TaijaParallel.MPIParallelizer(MPI.COMM_WORLD)
ces_mpi = @with_parallelizer parallelizer begin
    generate_counterfactual(
        xs,
        target,
        counterfactual_data,
        M,
        generator;
        convergence = conv,
        initialization = :identity,
    )
end

@test all(counterfactual.(ces) .== counterfactual.(ces_threads))
@test all(counterfactual.(ces) .== counterfactual.(ces_mpi))
