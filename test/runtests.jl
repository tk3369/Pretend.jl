using Pretend
using Test

@testset "Pretend.jl" begin
    include("test_basic.jl")
    include("test_spy.jl")
end
