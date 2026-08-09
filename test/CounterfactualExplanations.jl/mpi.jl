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

# Initialize MPI
using MPI
MPI.Init()
parallelizer = TaijaParallel.MPIParallelizer(MPI.COMM_WORLD)

data = TaijaData.load_linearly_separable()
counterfactual_data = CounterfactualData(data[1], data[2])

# Select factuals:
M = fit_model(counterfactual_data, :MLP)
conv = MaxIterConvergence(10)
generator = GenericGenerator()
factual = 1
target = 2
chosen = rand(findall(predict_label(M, counterfactual_data) .== factual), 1000)
xs = select_factual(counterfactual_data, chosen)
target = fill(2, length(xs))

ces = TaijaParallel.parallelize(
    parallelizer,
    CounterfactualExplanations.generate_counterfactual,
    xs,
    target,
    counterfactual_data,
    M,
    generator;
    convergence = conv,
    initialization = :identity,
)

nsteps = (ce -> total_steps(ce)).(ces)
if MPI.Comm_rank(MPI.COMM_WORLD) == 0
    println("Total steps: ", nsteps)
end
@test allequal(nsteps)

# Benchmark CE with MPI
with_logger(NullLogger()) do
    bmk = benchmark(counterfactual_data; parallelizer = parallelizer)
end
MPI.Finalize()
@test MPI.Finalized()
