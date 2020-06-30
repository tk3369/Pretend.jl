# Pretend.jl


[![Travis Build Status](https://travis-ci.org/tk3369/Pretend.jl.svg?branch=master)](https://travis-ci.org/tk3369/Pretend.jl)
[![codecov.io](http://codecov.io/github/tk3369/Pretend.jl/coverage.svg?branch=master)](http://codecov.io/github/tk3369/Pretend.jl?branch=master)
![Project Status](https://img.shields.io/badge/status-experimental-red)

Pretend is a mocking library.

## Motivation

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
```

## Related projects

The [Mocking.jl]() project has a similar goal but has a different design.
