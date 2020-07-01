@testset "Spy" begin

    @mockable caller(x, y) = double(x) + double(y)
    @mockable double(x) = 2x
    @mockable triple(x) = 3x

    spy() do
        @test caller(1,2) == 6
        @test verify_exactly_once(Main, :double, 2)
    end

    spy() do
        @test caller(2,2) == 8
        @test verify_exact_count(Main, :double, 2; n = 2)
        @test verify_none(Main, :triple, 2)
    end

end
