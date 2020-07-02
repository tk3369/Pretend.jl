"""
    @mockable

Annotate a function definition such that the function can be mocked later.
"""
macro mockable(ex)
    def = splitdef(ex)
    func = def[:name]
    types = haskey(def, :args) ? arg_types(def[:args]) : ()
    names = haskey(def, :args) ? arg_names(def[:args]) : ()

    def[:body] = quote
        if Pretend.TESTING[]
            # spy
            Pretend.record_call($func, ($(names...),))

            # apply patch
            patch_store = Pretend.default_patch_store()
            patch = Pretend.find(patch_store, $func, ($(types...),))
            if patch !== nothing
                val = patch($(names...))
                val isa Pretend.Fallback || return val
            end
        end
        $(def[:body])
    end
    return esc(combinedef(def))
end

"""
    apply(f::Function, patches::Pair...)

Run function `f` with the specified `patches` applied. Note
that the patches are only effective when the global switch
is activated. See also [`Pretend.activate`](@ref).

Each patch in the `patches` argument is a pair of the original
function and the patch function. If the patch functtion returns
the singleton object `Fallback()` then the original function will
be executed.  This provides an easy mechanism of implementing
conditional patches.

# Example

```
@mockable add(x, y) = x + y

apply(add => (x,y) -> x - y) do
    @test add(1, 2) == -1
end

apply(add => (x,y) -> x == y ? 0 : Fallback()) do
    @test add(1, 2) == 3
    @test add(5, 5) == 0
end
```
"""
function apply(f::Function, patches::Pair...)
    reset_statistics()
    ps = []
    for (orig, patch) in patches
        for sig in signatures(orig, patch)
            push!(ps, (sig = sig, patch = patch))
        end
    end
    patch_store = default_patch_store()
    preserve(patch_store)
    try
        for p in ps
            register(patch_store, p.patch, p.sig)
        end
        return f()
    finally
       restore(patch_store)
    end
end

"""
    signatures(f::Callable)

Return signatures that can be used to register in the patch store.
A signature is tuple of (f, argtype1, argtype2, ...).  This function
returns an array because there can be multiple methods per function.
"""
function signatures(orig::Function, f::Function)
    return Any[tuple(orig, tuple(m.sig.types[2:end]...)) for m in methods(f)]
end

"""
    arg_names(args)

Return names of the arguments. An argument is expected to be a Symbol
or an Expr e.g. `x::T` or `::T`.

See also: [`arg_types`](@ref)
"""
arg_names(args) = [arg_name(arg) for arg in args]

"""
    arg_types(args)

Return types of the arguments. An argument is expected to be a Symbol
or an Expr e.g. `x::T` or `::T`.

See also: [`arg_names`](@ref)
"""
arg_types(args) = [arg_type(arg) for arg in args]

arg_name(s::Symbol) = s
arg_name(e::Expr) = e.head === :(::) && length(e.args) > 1 ? e.args[1] : gensym()

arg_type(s::Symbol) = :Any
arg_type(e::Expr) = e.head === :(::) && length(e.args) > 1 ? e.args[2] : e.args[1]

