@testset "Spy" begin

    @mockable caller(x, y) = double(x) + double(y)
    @mockable double(x) = 2x
    @mockable triple(x) = 3x

    spy() do
        @test caller(1,2) == 6
        @test called_exactly_once(double, 2)
    end

    spy() do
        @test caller(2,2) == 8
        @test called_exactly_n(double, 2; n = 2)
        @test was_not_called(triple, 2)
    end

end
