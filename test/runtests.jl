using TaijaParallel
using Test

@testset "TaijaParallel.jl" begin

    @testset "Quality Assurance" begin
        include("aqua.jl")
    end

    @testset "CounterfactualExplanations.jl" begin
        include("CounterfactualExplanations.jl/CounterfactualExplanations.jl")
    end

end
