@testset "Spy" begin

    @mockable caller(x, y) = double(x) + double(y)
    @mockable double(x) = 2x
    @mockable triple(x) = 3x

    # basic statistics
    spy() do
        @test caller(1,2) == 6
        @test called_exactly_once(double, 1)
        @test called_exactly_once(double, 2)
        @test was_not_called(triple, 2)
    end

    # stats are gathered with `apply` as well
    apply() do
        @test caller(1,2) == 6
        @test called_exactly_once(double, 1)
        @test called_exactly_once(double, 2)
    end

    # stats for functions with kwargs
    @mockable div2(x; n = 2) = x / n
    spy() do
        @test div2(10) == 5
        @test div2(10; n = 5) == 2
        @test called_exactly_once(div2, 10; n = 2)
        @test called_exactly_once(div2, 10; n = 5)
    end
end
