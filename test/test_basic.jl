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
        @test_throws MethodError div2(10) == 0
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

    # TODO
    # This does not work because `kwargs` comes back as the name of keywords args
    # So, rather than passing via the syntax of x = x, y = y, etc., we need to pass
    # to the patch function with `kwargs...` syntax
    # Technically speaking, it does PASS the information but it's one more indirection.
    # To get to the kwargs pairs, you have to get the first element of the kwargs.
    # This causes unintutive behavior as shown in the erroneous code below where
    # you see `length(kwargs[:kwargs]))`.
    #
    # @mockable splat3(; kwargs...) = -1
    # apply(splat3 => (; kwargs...) -> length(kwargs[:kwargs])) do
    #     @test splat3()               == 0
    #     @test splat3(; x = 1)        == 1
    #     @test splat3(; x = 1, y = 2) == 2
    # end

    # TODO This does not work because the @mockable code does not pass kwargs
    # @mockable splat4(; kwargs::Int...) = 1
    # apply(splat4 => (; kwargs::Int...) -> 2) do
    #     @test splat4() == 2
    # end

end
