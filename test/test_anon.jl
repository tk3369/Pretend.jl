@testset "Anonymous Functions" begin

    add_curry(n) = (x) -> x + n

    add1 = mocked(add_curry(1))

    # make sure that normal call works
    @test add1(1) == 2

    # able to apply patch?
    apply(add1 => (x) -> x + 10) do
        @test add1(1) == 11
    end

    # test conditional patch
    apply(add1 => (x) -> x > 5 ? Fallback() : x) do
        @test add1(1) == 1  # no fallback
        @test add1(6) == 7  # fallback
    end

    # anonymous functions have no multiple dispatch so we can patch
    # with anything! This should not be a normal use case, however.
    apply(add1 => (x,y,z) -> x + y + z) do
        @test_throws MethodError add1(1)
        @test add1(1, 2, 3) == 6
    end

end
