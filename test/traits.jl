using TaijaParallel: ProcessStyle, IsParallel, parallelizable

ProcessStyle(::Type{<:typeof(sum)}) = IsParallel()
ProcessStyle(::Type{<:typeof(prod)}) = NotParallel()

@test parallelizable(sum) == true
@test parallelizable(product) == false
