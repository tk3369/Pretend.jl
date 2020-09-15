module MacroTest

using Test
using ExprTools: splitdef, combinedef
using Pretend: Pretend, apply, @mockable

# Define a macro that also does splitdef/combinedef
macro before(ex)
    def = splitdef(ex)
    pushfirst!(def[:body].args, :(print("Entry: ")))
    return esc(combinedef(def))
end

function test()
    Pretend.activate()
    @testset "Inner Macro" begin
        # Set up mock for function that is defined with another macro
        @mockable @before hello() = 1

        # Should be patched properly
        apply(hello => () -> 2) do
            @test hello() == 2
        end
    end
end

end # module

using .MacroTest: test
MacroTest.test()
