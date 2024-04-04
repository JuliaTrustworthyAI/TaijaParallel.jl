module TaijaParallel

using Reexport
using TaijaBase

export ThreadsParallelizer
@reexport import TaijaBase:
    parallelize, parallelizable, AbstractParallelizer, ProcessStyle, IsParallel, NotParallel

"The `ThreadsParallelizer` type is used to parallelize the evaluation of a function using `Threads.@threads`."
struct ThreadsParallelizer <: AbstractParallelizer end

include("utils.jl")

"""
    @with_parallelizer(parallelizer, expr)

This macro can be used to parallelize a function call or block of code. The macro will check that the function is parallelizable and then call `parallelize` with the supplied `parallelizer` and `expr`.
"""
macro with_parallelizer(parallelizer, expr)
    if !(expr.head ∈ (:block, :call))
        throw(AssertionError("Expected a block or function call."))
    end
    if expr.head == :block
        expr = expr.args[end]
    end

    # Unpack arguments:
    pllr = esc(parallelizer)
    f = esc(expr.args[1])
    args = expr.args[2:end]

    # Split args into positional and keyword arguments:
    aargs = []
    aakws = Pair{Symbol,Any}[]
    for el in args
        if Meta.isexpr(el, :parameters)
            for kw in el.args
                k = kw.args[1]      # parameter name
                v = kw.args[2]      # parameter value
                v = typeof(v) == QuoteNode ? v.value : v
                push!(aakws, Pair(k, v))
            end
        else
            push!(aargs, el)
        end
    end

    # Escape arguments:
    escaped_args = Expr(:tuple, esc.(aargs)...)

    # Parallelize:
    output = quote
        if !parallelizable($f)
            throw(AssertionError("$($f) is not a parallelizable process."))
        end
        output = parallelize($pllr, $f, $escaped_args...; $aakws...)
        output
    end
    return output
end

include("CounterfactualExplanations.jl/CounterfactualExplanations.jl")

include("extensions/extensions.jl")

end
