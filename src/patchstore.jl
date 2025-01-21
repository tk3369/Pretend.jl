const PATCHES = PatchStore(Dict(), Dict())

default_patch_store() = PATCHES

"""
    find(store::PatchStore, args...)

Find a patch from the `store` given the argument types.
"""
function find(store::PatchStore, args...)
    isempty(store.dct) && return nothing
    @debug "finding patch" dctkeys=collect(keys(store.dct))[1] args
    patch = get(store.dct, args, nothing)
    patch !== nothing && @debug "found patch" store.dct patch
    return patch
end

"""
    register(store::PatchStore, f::Callable, args)

Register a patch `f` in the `store` for the respective argument types.
"""
function register(store::PatchStore, f::Callable, args)
    # @info "Register" f args
    store.dct[args] = f
    return nothing
end

"""
    preserve(store::PatchStore)

Make a copy of the current state in the store.
"""
function preserve(store::PatchStore)
    empty!(store.prev)
    copy!(store.prev, store.dct)
end

"""
    restore(store::PatchStore)

Restore the previous state in the store.
"""
function restore(store::PatchStore)
    empty!(store.dct)
    copy!(store.dct, store.prev)
end
