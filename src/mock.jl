"""
    @mockable

Annotate a function definition such that the function can be mocked later.
"""
macro mockable(ex)

    # If the expression contains a macro, then expand that first.
    ex = auto_expand_macro(ex, __module__)

    # If it looks like a call then it must be referring to a third party method.
    # e.g. @mockable Base.sin(x::Real)
    ex.head === :call && return mock_thirdparty_function(ex, __module__)

    # parse function definition
    def = splitdef(ex)
    populate_unnamed_args!(def)
    func = parse_function_name(def)
    types, names, slurp_name = parse_function_args(def)
    kw_names, kw_slurp_name = parse_function_kwargs(def)

    # Prepare expressions for interpolation into generated code
    args_expr = [k == slurp_name ? :($k...) : :($k) for k in names]
    kwargs_expr = [k == kw_slurp_name ? :($k...) : :($k = $k) for k in kw_names]

    # ensure macro hygiene
    patch_store, patch, val = [gensym() for _ in 1:3]

    def[:body] = quote
        if Pretend.activated()
            # spy
            Pretend.record_call($func, ($(args_expr...),); $(kwargs_expr...))

            # apply patch
            $patch_store = Pretend.default_patch_store()
            $patch = Pretend.find($patch_store, $func, ($(types...),))
            if $patch !== nothing
                # @debug "found patch" $func $(names)
                $val = $(patch)($(args_expr...); $(kwargs_expr...))
                $val isa Pretend.Fallback || return $val
            end
        end
        $(def[:body])
    end
    expanded = esc(combinedef(def))
    return expanded
end

"""
    auto_expand_macro(ex::Expr, mod::Module)

Auto-expand macro expression if necessary.
See https://github.com/invenia/ExprTools.jl/issues/10
"""
function auto_expand_macro(ex::Expr, mod::Module)
    return ex.head === :macrocall ? macroexpand(mod, ex) : ex
end

"""
    mock_thirdparty_function(ex::Expr, mod::Module)

Mock a thirdparty function by defining a local function that delegates
to the thirdparty function.
"""
function mock_thirdparty_function(ex::Expr, mod::Module)
    ret = delegate_method(ex, mod)
    ret === nothing && error("@mockable should be used at function definition")
    expanded = postwalk(rmlines, macroexpand(mod, ret))
    return esc(expanded)
end

"""
    populate_unnamed_args!(def)

Populate unnamed arg expressions in the function defintion `def` with random name.
"""
function populate_unnamed_args!(def::FunctionDef)
    haskey(def, :args) || return
    for x in def[:args]
        if x isa Expr && x.head == :(::) && length(x.args) == 1
            pushfirst!(x.args, gensym())
        end
    end
end

parse_function_name(def::FunctionDef) = def[:name]

function parse_function_args(def::FunctionDef)
    has_args = haskey(def, :args)
    types = has_args ? arg_types(def[:args]) : ()
    names = has_args ? arg_names(def[:args]) : ()
    slurp_name = has_args ? slurp_arg_name(def[:args]) : nothing
    return (types, names, slurp_name)
end

function parse_function_kwargs(def::FunctionDef)
    has_kwargs = haskey(def, :kwargs)
    kw_names = has_kwargs ? arg_names(def[:kwargs]) : []
    kw_slurp_name = has_kwargs ? slurp_arg_name(def[:kwargs]) : nothing
    return (kw_names, kw_slurp_name)
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
arg_name(e::Expr, ::Val{:(...)}) = arg_name(e.args[1])  # slurp (handles both typed/untyped)

"""
    slurp_arg_name(args)

Find the name of the function argument that uses the slurping syntax.
This function should work for both regular arguments and keyword arguments.
"""
function slurp_arg_name(args)
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

