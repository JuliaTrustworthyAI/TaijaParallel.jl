var documenterSearchIndex = {"docs":
[{"location":"","page":"Home","title":"Home","text":"CurrentModule = TaijaParallel","category":"page"},{"location":"#TaijaParallel","page":"Home","title":"TaijaParallel","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for TaijaParallel.","category":"page"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [TaijaParallel]","category":"page"},{"location":"#TaijaParallel.IsParallel","page":"Home","title":"TaijaParallel.IsParallel","text":"Processes that can be parallelized have this trait.\n\n\n\n\n\n","category":"type"},{"location":"#TaijaParallel.NotParallel","page":"Home","title":"TaijaParallel.NotParallel","text":"By default all types of have this trait.\n\n\n\n\n\n","category":"type"},{"location":"#TaijaParallel.ProcessStyle","page":"Home","title":"TaijaParallel.ProcessStyle","text":"A base type for a style of process.\n\n\n\n\n\n","category":"type"},{"location":"#TaijaParallel.ProcessStyle-Tuple{Type{<:typeof(CounterfactualExplanations.Evaluation.evaluate)}}","page":"Home","title":"TaijaParallel.ProcessStyle","text":"The evaluate function is parallelizable.\n\n\n\n\n\n","category":"method"},{"location":"#TaijaParallel.ProcessStyle-Tuple{Type{<:typeof(CounterfactualExplanations.generate_counterfactual)}}","page":"Home","title":"TaijaParallel.ProcessStyle","text":"The generate_counterfactual method is parallelizable.\n\n\n\n\n\n","category":"method"},{"location":"#TaijaParallel.ThreadsParallelizer","page":"Home","title":"TaijaParallel.ThreadsParallelizer","text":"The ThreadsParallelizer type is used to parallelize the evaluation of a function using Threads.@threads.\n\n\n\n\n\n","category":"type"},{"location":"#TaijaBase.parallelize-Tuple{ThreadsParallelizer, typeof(CounterfactualExplanations.Evaluation.evaluate), Vararg{Any}}","page":"Home","title":"TaijaBase.parallelize","text":"TaijaBase.parallelize(\n    parallelizer::ThreadsParallelizer,\n    f::typeof(CounterfactualExplanations.Evaluation.evaluate),\n    args...;\n    kwargs...,\n)\n\nParallelizes the evaluation of f using Threads.@threads. This function is used to evaluate counterfactual explanations.\n\n\n\n\n\n","category":"method"},{"location":"#TaijaBase.parallelize-Tuple{ThreadsParallelizer, typeof(CounterfactualExplanations.generate_counterfactual), Vararg{Any}}","page":"Home","title":"TaijaBase.parallelize","text":"TaijaBase.parallelize(\n    parallelizer::ThreadsParallelizer,\n    f::typeof(CounterfactualExplanations.generate_counterfactual),\n    args...;\n    kwargs...,\n)\n\nParallelizes the evaluation of f using Threads.@threads. This function is used to generate counterfactual explanations.\n\n\n\n\n\n","category":"method"},{"location":"#TaijaParallel.MPIParallelizer","page":"Home","title":"TaijaParallel.MPIParallelizer","text":"MPIParallelizer\n\nExposes the MPIParallelizer function from the MPIExt extension.\n\n\n\n\n\n","category":"function"},{"location":"#TaijaParallel.chunk_obs-Tuple{Any, Integer, Integer}","page":"Home","title":"TaijaParallel.chunk_obs","text":"chunk_obs(obs::AbstractVector, n_each::Integer, n_groups::Integer)\n\nSplit the vector of observations obs into chunks such that each chunk has n_each observations for each available CPU core (i.e. n_groups).\n\n\n\n\n\n","category":"method"},{"location":"#TaijaParallel.split_by_counts-Tuple{AbstractVector, AbstractVector}","page":"Home","title":"TaijaParallel.split_by_counts","text":"split_by_counts(obs::AbstractVector, counts::AbstractVector)\n\nReturn a vector of vectors of obs split by counts.\n\n\n\n\n\n","category":"method"},{"location":"#TaijaParallel.split_count-Tuple{Integer, Integer}","page":"Home","title":"TaijaParallel.split_count","text":"split_count(N::Integer, n::Integer)\n\nReturn a vector of n integers which are approximately equally sized and sum to N. Lifted from https://juliaparallel.org/MPI.jl/v0.20/examples/06-scatterv/.\n\n\n\n\n\n","category":"method"},{"location":"#TaijaParallel.split_obs-Tuple{AbstractVector, Integer}","page":"Home","title":"TaijaParallel.split_obs","text":"split_obs(obs::AbstractVector, n::Integer)\n\nReturn a vector of n group indices for obs.\n\n\n\n\n\n","category":"method"},{"location":"#TaijaParallel.@with_parallelizer-Tuple{Any, Any}","page":"Home","title":"TaijaParallel.@with_parallelizer","text":"@with_parallelizer(parallelizer, expr)\n\nThis macro can be used to parallelize a function call or block of code. The macro will check that the function is parallelizable and then call parallelize with the supplied parallelizer and expr.\n\n\n\n\n\n","category":"macro"}]
}
