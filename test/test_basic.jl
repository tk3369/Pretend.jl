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
        # This case may be unintutive. Because `n` is not specified,
        # the original value of `n` is passed (n = 2). Hence, the absense
        # of `n` in the call isn't really absent and therefore overrides
        # the different default value in the patch. Hence, it should be
        # advised that
        @test div2(10) == 2
        @test div2(10; n = 4) == 4
    end

    # This is the correct way; patch should not have any default values for kwargs
    apply(div2 => (x; n) -> n) do
        @test div2(10) == 2
        @test div2(10; n = 4) == 4
    end

    # Expect failure when patch does not take kwargs
    apply(div2 => (x) -> 0) do
        if VERSION >= v"1.2"
            @test_throws MethodError div2(10) == 0
        else
            @test_throws ErrorException div2(10) == 0
        end
    end

    # test splatting with Any type
    @mockable splat1(k...) = 1
    apply(splat1 => (k...) -> 2) do
        @test splat1(1,2,3) == 2
    end

    # test splatting with specific type
    @mockable splat2(k::Int...) = 1
    apply(splat2 => (k::Int...) -> 2) do
        @test splat2(1,2,3) == 2
    end

    # Negative test: signature does not match so it cannot be applied
    @mockable splat3(x, y) = x + y
    apply(splat3 => (args...) -> 10) do
        @test splat3(1, 2) == 3
    end

    # Test keyword arg splatting
    @mockable splat_kwarg(; kwargs...) = -1
    apply(splat_kwarg => (; kwargs...) -> length(kwargs)) do
        @test splat_kwarg()               == 0
        @test splat_kwarg(; x = 1)        == 1
        @test splat_kwarg(; x = 1, y = 2) == 2
    end

end
