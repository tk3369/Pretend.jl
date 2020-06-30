const PATCHES = PatchStore(Dict(), Dict())

default_patch_store() = PATCHES

function find(store::PatchStore, args...)
    return get(store.dct, args, nothing)
end

function register(store::PatchStore, f::Callable, args)
    # @info "Register" f args
    store.dct[args] = f
    return nothing
end

function unregister(store::PatchStore, args)
    # @info "Unregister" args
    pop!(store.dct, args)
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