using CounterfactualExplanations
using CounterfactualExplanations.Convergence
using CounterfactualExplanations.Evaluation
using CounterfactualExplanations.Models
using TaijaData
using TaijaParallel: ThreadsParallelizer, @with_parallelizer

counterfactual_data =
    TaijaData.load_linearly_separable() |>
    data ->
        counterfactual_data =
            CounterfactualExplanations.DataPreprocessing.CounterfactualData(
                Float32.(data[1]),
                data[2],
            )
M = fit_model(counterfactual_data, :MLP)
conv = DecisionThresholdConvergence(decision_threshold = 0.95)
generator = GenericGenerator()
factual = 1
target = 2
chosen = rand(findall(predict_label(M, counterfactual_data) .== factual), 1000)
xs = select_factual(counterfactual_data, chosen)

parallelizer = ThreadsParallelizer()
ces = @with_parallelizer parallelizer begin
    generate_counterfactual(xs, target, counterfactual_data, M, generator; convergence = conv)
end

@test all(CounterfactualExplanations.factual.(ces) .== (x -> x[1]).(collect(xs)))

evals = @with_parallelizer parallelizer begin
    evaluate(ces)
end

@test true
