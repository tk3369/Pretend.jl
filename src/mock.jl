"""
    @mockable

Annotate a function defintion such that the function can be mocked
later.
"""
macro mockable(ex)
    def = splitdef(ex)
    func = QuoteNode(def[:name])
    types = arg_types(def[:args])
    names = arg_names(def[:args])
    mod = __module__

    # @info "mockable" mod func types
    def[:body] = quote
        if Pretend.MOCKING[]
            patch_store = Pretend.default_patch_store()
            patch = Pretend.find(patch_store, $mod, $func, ($(types...),))
            # @show patch
            if patch !== nothing
                val = patch($(names...))
                val isa Pretend.Fallback || return val
            end
        end
        $(def[:body])
    end
    # @info combinedef(def)
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
    ps = []
    for (orig, patch) in patches
        for sig in signatures(nameof(orig), patch)
            push!(ps, (sig = sig, patch = patch))
        end
    end
    patch_store = default_patch_store()
    preserve(patch_store)
    try
        for p in ps 
            register(patch_store, p.patch, p.sig)
        end
        f()
    finally
       restore(patch_store)
    end
    return nothing
end

"""
    signatures(name::Symbol, f::Callable)

Return signatures that can be used to register in the patch store.
A signature is tuple of (module, name, arg1, arg2, ...).  This function
returns an array because there can be multiple methods per function.
"""
function signatures(name::Symbol, f::Callable)
    return Any[tuple(m.module, name, tuple(m.sig.types[2:end]...))
                for m in methods(f)]
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

