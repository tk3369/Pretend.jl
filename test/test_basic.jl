@testset "Basic" begin

# test mock that accepts no args
    @mockable quack() = "quack"
    apply(quack => () -> "woof") do
        @test quack() == "woof"
    end

    # test mock that accepts some args
    @mockable add(x, y) = x + y
    apply(add => (x, y) -> 0) do
        @test add(1, 2) == 0
    end

    # test mock with fallback (conditional patch)
    apply(add => (x, y) -> x == 1 ? 0 : Fallback()) do
        @test add(1, 2) == 0          # patch returend value
        @test add(2, 2) == 4          # fall back to default
    end

    # test multiple patches
    @mockable mul2(x, y::Int)     = x * y + 2
    @mockable mul2(x, y::Float64) = x * y - 2
    apply(mul2 => (x, y::Int)     -> x == 1 ? 0 : Fallback(),
          mul2 => (x, y::Float64) -> x ^ y) do
        @test mul2(1, 2) == 0          # value returned from patch
        @test mul2(2, 2) == 6          # fall back to default
        @test mul2(2, 3.0) == 8.0      # Float64 patch
    end

    # test functions that uses kwargs
    @mockable div2(x; n = 2) = x / n
    @test div2(10) == 5                # without patch
    apply(div2 => (x; n = 3) -> n) do  # patched
        @test div2(10) == 3
        # @test div2(10; n = 4) == 4     # TODO @mockable not passing kwargs yet
    end
    apply(div2 => (x) -> 0) do         # patched; kwarg not needed!
        @test div2(10) == 0
    end

    # test splatting
    @mockable splat1(k...) = 1
    apply(splat1 => (k...) -> 2) do
        @test splat1(1,2,3) == 2
    end

    # TODO This does not work because the patch store has Vararg but we have Int,Int,Int here
    # @mockable splat2(k::Int...) = 1
    # apply(splat2 => (k::Int...) -> 2) do
    #     @test splat2(1,2,3) == 2
    # end

    @mockable splat3(; kwargs...) = -1
    apply(splat3 => (; kwargs...) -> length(kwargs)) do
        @test splat3()               == 0
        # @test splat3(; x = 1)        == 1   # TODO @mockable not passing kwargs yet
        # @test splat3(; x = 1, y = 2) == 2   # TODO @mockable not passing kwargs yet
    end

    # TODO This does not work because the @mockable code does not pass kwargs
    # @mockable splat4(; kwargs::Int...) = 1
    # apply(splat4 => (; kwargs::Int...) -> 2) do
    #     @test splat4() == 2
    # end

end
