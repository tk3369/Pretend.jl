using Pretend
using Test

Pretend.activate()

@testset "Pretend.jl" begin

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


    # Design changes
    # - ???

    # Features:
    # - Allow patch function to return a special value to fall back to original function
    # - Support multiple patches in a single `apply` call
    # - Support spy, recording all calls/results for later verification
    #
    # Not supported:
    # - thread safety (cannot run mocked processes concurrently)

    #= 
    Syntax: @when macro to apply patch only for specific value or type of arguments
    @when add [x = 1] => 0
    @when add [x isa Int, y isa Float64] => 0
    =#

    # Get ideas from Mockito

end
