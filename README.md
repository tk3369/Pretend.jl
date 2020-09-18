# Pretend.jl

[![Travis Build Status](https://travis-ci.com/tk3369/Pretend.jl.svg?branch=master)](https://travis-ci.org/tk3369/Pretend.jl)
[![codecov.io](http://codecov.io/github/tk3369/Pretend.jl/coverage.svg?branch=master)](http://codecov.io/github/tk3369/Pretend.jl?branch=master)
![Project Status](https://img.shields.io/badge/status-new-orange)

Pretend.jl is a mocking library. The main idea is that you can annotate any functions
as `@mockable`.  Then, you can easily stub out calls to the function with your
own patch using `apply`.  You must activate the framework using `Pretend.activate()`; otherwise,
patches will not be applied (for performance reasons).

P.S. This package has been somewhat battle-tested for a production-quality enterprise application.

## Usage

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

# Mocking thirdparty methods
@mockable Base.sin(x::Real)
fakesin(x::Real) = 10
apply(sin => fakesin) do
    @test sin(1.0) == 10
end

# Mocking anonymous functions
add_curry(n) = (x) -> x + n
add1 = mocked(add_curry(1))  # function, not macro
apply(add1 => (x) -> x + 10) do
    @test add1(1) == 11
end
```

## Design Notes

### How does it work?

The `@mockable` macro rewrites a method definition by wrapping around the logic that is
switched on when `Pretend.activated()` returns `true`.  The logic basically looks up
a patch in the "patch store" having the same method signature.  If a patch is found
then it will be called.  However, if a patch is not found or if the patch returns
the `Fallback()` singleton object, the existing method body will be executed.

The `apply` function sets up the "patch store" with the user-supplied patch functions before
running the body.  As it exits the current scope, the patch store is unwound to the previous
state; hence, no more patch will be applied.  This ensures a clean slate whenever patches
are applied.

Both `apply` and `spy` functions keep track of executions of mockable functions. The
difference is that `apply` expects a set of patches while `spy` does not take any patch.

### Mocking third-party methods

Because the `@mockable` macro needs to be used at the function definition, it's a little tricky
if you want to mock a third party function that you do not own.  To overcome this issue, you may
define a function in your own package and delegate the call to the third party function, and then
you can annotate this function as mockable.

For convenience, when you put `@mockable` just in front of a third-party method signature then
it will be expanded to a delegate function having the same function name.

### Mocking anonymous functions

Functions are first-class in Julia, and a function can be created at any time on-the-fly.
A common usage is high-order functions or closures. Consider the following function:
```julia
add_curry(n) = (x) -> x + n
```

It's easy to annotate `add_curry` with `@mockable` but perhaps I
don't want to mock `add_curry` itself but the function that it returns:
```julia
add1 = add_curry(1)
```

In order to mock `add1`, I would use the `mocked` *function* as follows:
```julia
add1 = mocked(add_curry(1))
```

## Related projects

There are several mocking libraries available. If Pretend.jl does not fit your needs, take a look
at these alternatives:

[Mocking.jl](https://github.com/invenia/Mocking.jl) has a different design such that the mocks are
annotated at the call site rather than at the function definition. Pretend.jl's design is heavily
influenced by this.

[SimpleMock.jl](https://github.com/JuliaTesting/SimpleMock.jl) is a very cool package that
implements mocking using Cassette.jl's machinery.

