"""
    @mockable

Annotate a function definition such that the function can be mocked later.
"""
macro mockable(ex)

    # Auto-expand macro expression if necessary
    # See https://github.com/invenia/ExprTools.jl/issues/10
    ex = ex.head === :macrocall ? macroexpand(__module__, ex) : ex

    # If it looks like a call then it must be referring to a third party method.
    # e.g. @mockable Base.sin(x::Real)
    if ex.head === :call
        ret = delegate_method(ex, __module__)
        ret === nothing && error("@mockable should be used at function definition")
        expanded = postwalk(rmlines, macroexpand(__module__, ret))
        return esc(expanded)
    end

    # parse function definition
    def = splitdef(ex)
    func = def[:name]
    types = haskey(def, :args) ? arg_types(def[:args]) : ()
    names = haskey(def, :args) ? arg_names(def[:args]) : ()

    # Keyword args
    kwnames = haskey(def, :kwargs) ? arg_names(def[:kwargs]) : []
    kwsplat = haskey(def, :kwargs) ? splat_arg_name(def[:kwargs]) : nothing
    kwexpr = Expr[k == kwsplat ? :($k...) : :($k = $k) for k in kwnames]

    #@show func types names kwnames kwexpr kwsplat

    # ensure macro hygiene
    patch_store = gensym()
    patch = gensym()
    val = gensym()

    def[:body] = quote
        if Pretend.activated()
            # spy
            Pretend.record_call($func, ($(names...),); $(kwexpr...))

            # apply patch
            $patch_store = Pretend.default_patch_store()
            $patch = Pretend.find($patch_store, $func, ($(types...),))
            if $patch !== nothing
                @debug "found patch" $func
                $val = $(patch)($(names...); $(kwexpr...))
                $val isa Pretend.Fallback || return $val
            end
        end
        $(def[:body])
    end
    expanded = esc(combinedef(def))
    return expanded
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
    # @show ps
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
    delegate_method(ex::Expr, mod::Module)

Returns an expression that defines a mockable function such that it can be
defined in module `mod`.  The mockable function just delegates the call to
the underlying method referenced in `ex`.

# Example

```julia-repl
julia> MacroTools.postwalk(rmlines, Pretend.delegate_method(:(Base.sin(x::Real)), @__MODULE__))
quote
    @mockable sin(x::Real) = Base.sin(x)
end
```
"""
function delegate_method(ex::Expr, mod::Module)
    # Try to resolve the provided name (e.g. Base.sin)
    func = try
        Base.eval(mod, ex.args[1])
    catch e
        rethrow(e)
    end

    # The module must be different since otherwise we should expect a full function
    # defintiion rather than just a reference to a method.
    parentmodule(func) === mod && return nothing

    # Derive the function body that delegates the call to the thirdparty function.
    body = delegate_function_body(ex)

    # Remove package prefix e.g. Base.sin => sin
    ex.args[1] = base_symbol(ex.args[1])

    return quote
        @mockable $ex = $body
    end
end

"""
    delegate_function_body(cs::Expr)

Returns an expression that delegates the call to the underlying function based upon
the signature in the expression `cs`.

# Examples

```julia-repl
julia> Pretend.delegate_function_body(:(Base.sin(x::Real)))
:(Base.sin(x))

julia> Pretend.delegate_function_body(:(Base.round(x; digits::Integer, base)))
:(Base.round(x; digits = digits, base = base))
```
"""
function delegate_function_body(cs::Expr)
    cs.head === :call || error("Argument is not a :call expression: $cs")
    newargs = Any[cs.args[1]]   # build a new args array; start with function name
    for arg in cs.args[2:end]   # start with 2 to skip the function name
        if arg isa Expr
            if arg.head === :parameters          # kwargs
                kwargs = Any[                    # make (x = x, y = y, ...)
                    let name = arg_name(arg)
                        Expr(:kw, name, name)
                    end for arg in arg.args]
                push!(newargs, Expr(:parameters, kwargs...))
            elseif arg.head === :(::)            # typed positional args x::T
                push!(newargs, arg_name(arg))
            else
                error("Unknown argument: arg.head=$(arg.head)")
            end
        elseif arg isa Symbol
            push!(newargs, arg)
        else
            error("Unknown argument: arg=$arg")
        end
    end
    return Expr(:call, newargs...)
end

"""
    base_symbol(ex::Expr)

Returns the base symbol of an expression.
"""
function base_symbol(ex::Expr)
    ex.head === :(.) && return ex.args[2].value
    error("Expression does not refer to an object in module: $ex")
end

"""
    signatures(orig::Function, f::Function)

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

arg_name(s::Symbol) = s
arg_name(e::Expr) = arg_name(e, Val(e.head))

arg_name(e::Expr, ::Val{:(::)}) = length(e.args) > 1 ? e.args[1] : gensym()
arg_name(e::Expr, ::Val{:kw}) = arg_name(e.args[1])     # kwarg
arg_name(e::Expr, ::Val{:(...)}) = arg_name(e.args[1])  # splat (handles both typed/untyped)

"""
    splat_arg_name(args)

Find the name of the function argument that uses the splatting syntax.
This function should work for both regular arguments and keyword arguments.
"""
function splat_arg_name(args)
    idx = findfirst(x -> x isa Expr && x.head === :(...), args)
    return idx !== nothing ? arg_name(args[idx]) : nothing
end

"""
    arg_types(args)

Return types of the arguments. An argument is expected to be a Symbol
or an Expr e.g. `x::T` or `::T`.

See also: [`arg_names`](@ref)
"""
arg_types(args) = [arg_type(arg) for arg in args]

arg_type(s::Symbol) = :Any
arg_type(e::Expr) = arg_type(e, Val(e.head))

arg_type(e::Expr, ::Val{:(::)}) = length(e.args) > 1 ? e.args[2] : e.args[1]
arg_type(e::Expr, ::Val{:kw}) = arg_type(e.args[1])  # kwarg

function arg_type(e::Expr, ::Val{:(...)})
    # dump(e)
    if e.args[1] isa Symbol
        # Example: k...
        # Expr
        #     head: Symbol ...
        #     args: Array{Any}((1,))
        #     1: Symbol k
        return :(Vararg{Any,N} where N)
    elseif e.args[1] isa Expr
        # Example: k::Int...
        # Expr
        #     head: Symbol ...
        #     args: Array{Any}((1,))
        #         1: Expr
        #         head: Symbol ::
        #         args: Array{Any}((2,))
        #             1: Symbol k
        #             2: Symbol Int
        return :(Vararg{$(e.args[1].args[2]),N} where N)
    end
end

