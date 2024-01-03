using TaijaParallel
using Test

@testset "TaijaParallel.jl" begin
    
    @testset "CounterfactualExplanations.jl" begin
        include("CounterfactualExplanations.jl/CounterfactualExplanations.jl")
    end

end
