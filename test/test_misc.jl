using ExprTools

@testset "parsing" begin

    # kwargs
    let kwargs = splitdef(:( foo(a; b=2, c::Int=1, d::Int, e) = a + b + c))[:kwargs]
        @test Pretend.arg_names(kwargs) == [:b, :c, :d, :e]
    end

end
