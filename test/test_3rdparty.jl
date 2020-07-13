module ThirdPartyMock
    using Pretend, Test
    Pretend.activate()

    @mockable Base.sin(x::Real)

    fakesin(x::Real) = 10

    function test()
        apply(sin => fakesin) do
            @test sin(1.0) == 10
        end
        @test sin(1.0) ≈ 0.8414709848078965
    end
end

using .ThirdPartyMock
ThirdPartyMock.test()
