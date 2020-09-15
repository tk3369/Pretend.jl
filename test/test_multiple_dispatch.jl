@testset "Multiple Dispatch" begin

    @mockable foo(x::Int, y::Int) = 1
    @mockable foo(x::Int, y::Float64) = 2

    # Patch some methods
    apply(foo => (x::Int, y::Int) -> 3) do
        @test foo(1, 1) == 3
        @test foo(1, 2.0) == 2
    end

    # Patch all methods
    apply(foo => (x::Int, y::Int) -> 3,
          foo => (x::Int, y::Float64) -> 4) do
        @test foo(1, 1) == 3
        @test foo(1, 2.0) == 4
    end
end
