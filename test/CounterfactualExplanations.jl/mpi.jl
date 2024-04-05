using CounterfactualExplanations.DataPreprocessing: CounterfactualData
using CounterfactualExplanations.Evaluation: benchmark
using LaplaceRedux
using Logging
using TaijaData
using TaijaParallel
using Test

# Initialize MPI
using MPI
MPI.Init()

data = TaijaData.load_linearly_separable()
counterfactual_data = CounterfactualData(data[1], data[2])
parallelizer = TaijaParallel.MPIParallelizer(MPI.COMM_WORLD)
with_logger(NullLogger()) do
    bmk = benchmark(counterfactual_data; parallelizer = parallelizer)
end
MPI.Finalize()
@test MPI.Finalized()
