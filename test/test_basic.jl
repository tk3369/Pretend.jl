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
end
