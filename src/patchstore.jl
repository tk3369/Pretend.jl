const PATCHES = PatchStore(Dict(), Dict())

default_patch_store() = PATCHES

function find(store::PatchStore, args...)
    @debug "finding patch" args
    patch = get(store.dct, args, nothing)
    patch !== nothing && @debug "found patch" store.dct patch
    return patch
end

function register(store::PatchStore, f::Callable, args)
    # @info "Register" f args
    store.dct[args] = f
    return nothing
end

function preserve(store::PatchStore)
    empty!(store.prev)
    copy!(store.prev, store.dct)
end

function restore(store::PatchStore)
    empty!(store.dct)
    copy!(store.dct, store.prev)
end
