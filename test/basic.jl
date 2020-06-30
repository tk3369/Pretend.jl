@testset "Basic" begin
    # duck typing
    @mockable add(x, y) = x + y

    # applying a patch to the add function
    apply(add => (x, y) -> 0) do
        @test add(1, 2) == 0
    end

    # fallback mechanism (conditional patch)
    apply(add => (x, y) -> x == 1 ? 0 : Fallback()) do
        @test add(1, 2) == 0          # patch returend value
        @test add(2, 2) == 4          # fall back to default
    end

    # multiple patches
    @mockable add(x, y::Float64) = x + y

    apply(add => (x, y) -> x == 1 ? 0 : Fallback(),
          add => (x, y::Float64) -> x ^ y) do
        @test add(1, 2) == 0          # patch returend value
        @test add(2, 2) == 4          # fall back to default
        @test add(2, 3.0) == 8.0      # Float64 patch
        @test add(3.0, 3.0) == 27.0   # Float64 patch
    end
end
