using TaijaParallel: ProcessStyle, IsParallel, parallelizable

ProcessStyle(::Type{<:typeof(sum)}) = IsParallel()
ProcessStyle(::Type{<:typeof(Base.prod)}) = NotParallel()

@test parallelizable(sum) == true
@test parallelizable(Base.prod) == false
