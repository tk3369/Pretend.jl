using Pretend
using Test

Pretend.activate()

@testset "Pretend.jl" begin
    include("test_basic.jl")
    include("test_spy.jl")
    include("test_misc.jl")
    include("test_3rdparty.jl")
end
