const MOCKING = Ref{Bool}(false)

activate() = MOCKING[] = true
deactivate() = MOCKING[] = false

const PATCHES = Dict()

function find_patch(args...)
    return get(PATCHES, args, nothing)
end

function register_patch(f, args...)
    # @info "Register" f args
    PATCHES[args] = f
end

function unregister_patch(args...)
    # @info "Unregister" args
    PATCHES[args] = nothing
end

#=
@mockable function add(x::Int, y::Int)
    x + y
end
=#
macro mockable(ex)
    def = splitdef(ex)
    func = QuoteNode(def[:name])
    types = arg_types(def[:args])
    names = arg_names(def[:args])
    mod = __module__

    # dump(def[:args])
    # @info "mockable" mod func types
    def[:body] = quote
        if Pretend.MOCKING[]
            patch = Pretend.find_patch($mod, $func, ($(types...),))
            if patch !== nothing
                # @info "found patch" patch
                val = patch($(names...))
                val isa Pretend.Fallback || return val
            else
                # @info "cannot find patch" $mod $func $(tuple(types...))
            end
        end
        $(def[:body])
    end
    # @info combinedef(def)
    return esc(combinedef(def))
end

function apply(f::Function, patches::Pair...) #{T,S}...) where {T <: Callable, S <: Callable}
    ps = []
    for p in patches
        orig, patch = p
        mod = parentmodule(orig)
        name = nameof(orig)
        method = first(methods(patch))
        method_args = tuple(method.sig.types[2:end]...)
        push!(ps, patch => (mod, name, method_args))
    end
    orig_state = copy(PATCHES)
    try
        for p in ps 
            patch = first(p)
            args = last(p)
            register_patch(patch, args...)
        end
        # @show PATCHES
        f()
    finally
       empty!(PATCHES)
       copy!(PATCHES, orig_state)
    end
    return nothing
end

# Extract x or T from x::T  
arg_names(args) = [arg_name(arg) for arg in args]
arg_types(args) = [arg_type(arg) for arg in args]

arg_name(s::Symbol) = s
arg_name(e::Expr) = e.head === :(::) && length(e.args) > 1 ? e.args[1] : gensym()

arg_type(s::Symbol) = :Any
arg_type(e::Expr) = e.head === :(::) && length(e.args) > 1 ? e.args[2] : e.args[1]

