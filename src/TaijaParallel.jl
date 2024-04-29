module TaijaParallel

# Package extensions:
using PackageExtensionCompat
function __init__()
    @require_extensions
end

using Reexport
using TaijaBase

@reexport import TaijaBase: parallelize, AbstractParallelizer
export ThreadsParallelizer,
    IsParallel, NotParallel, ProcessStyle, parallelizable, @with_parallelizer

"The `ThreadsParallelizer` type is used to parallelize the evaluation of a function using `Threads.@threads`."
struct ThreadsParallelizer <: AbstractParallelizer end

include("utils.jl")
include("traits.jl")

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

    Meta.show_sexpr(expr)
    println("")

    # Unpack arguments:
    pllr = esc(parallelizer)
    f = esc(expr.args[1])
    args = expr.args[2:end]

    # Split args into positional and keyword arguments:
    aargs = []
    kwargs_names = []
    kwargs_values = []
    for el in args
        if Meta.isexpr(el, :parameters)
            for kw in el.args
                k = kw.args[1]      # parameter name
                v = kw.args[2]      # parameter value
                # v = typeof(v) == QuoteNode ? v.value : v
                push!(kwargs_names, k)
                push!(kwargs_values, v)
            end
        else
            push!(aargs, el)
        end
    end

    # Escape arguments and create a tuple:
    escaped_args = Expr(:tuple, esc.(aargs)...)
    kwargs_names = tuple(kwargs_names...,)
    sym = QuoteNode.(kwargs_names)
    kwargs_values = tuple(kwargs_values...,)

    # Parallelize:
    output = quote
        if !TaijaParallel.parallelizable($f)
            throw(AssertionError("$($f) is not a parallelizable process."))
        else
            @info "Parallelizing with $($pllr)"
        end
        escaped_kwargs = $NamedTuple{($(sym...),)}(($(esc.(kwargs_values)...),)) 
        output = TaijaBase.parallelize($pllr, $f, $escaped_args...; escaped_kwargs...) 
        output
    end
    return output
end

include("CounterfactualExplanations.jl/CounterfactualExplanations.jl")

include("extensions/extensions.jl")

end
