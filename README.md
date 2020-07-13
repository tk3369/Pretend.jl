# Pretend.jl


[![Travis Build Status](https://travis-ci.com/tk3369/Pretend.jl.svg?branch=master)](https://travis-ci.org/tk3369/Pretend.jl)
[![codecov.io](http://codecov.io/github/tk3369/Pretend.jl/coverage.svg?branch=master)](http://codecov.io/github/tk3369/Pretend.jl?branch=master)
![Project Status](https://img.shields.io/badge/status-experimental-red)

Pretend is a mocking library. The main idea is that you can annotate any functions
as `@mockable`.  Then, you can easily stub out calls to the function with your
own patch using `apply`.  You must activate the framework using `Pretend.activate`;
otherwise, patches will not be applied (for performance reasons).

## Motivation

The following examples demonstrate the basic usage of the Pretend framework.

```julia
# Annotate any function with @mockable macro
@mockable add(x, y) = x + y

# Apply a patch
apply(add => (x,y) -> x - y) do
    @test add(1, 2) == -1
end

# Apply a patch conditionally
apply(add => (x,y) -> x == y ? 0 : Fallback()) do
    @test add(1, 2) == 3
    @test add(5, 5) == 0
end

# Verification
@mockable foo() = bar(1,2)
@mockable bar(x,y) = x * y
spy() do
    foo()
    @test called_exactly_once(bar, 1, 2)
end

# Mocking thirdparty methods!
@mockable Base.sin(x::Real)
fakesin(x::Real) = 10
apply(sin => fakesin) do
    @test sin(1.0) == 10
end
```

## Related projects

* [Mocking.jl](https://github.com/invenia/Mocking.jl)
* [SimpleMock.jl](https://github.com/JuliaTesting/SimpleMock.jl)
* [ExpectationStubs.jl](https://github.com/oxinabox/ExpectationStubs.jl)
