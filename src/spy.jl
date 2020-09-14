
const STATS = Dict()

# Verifications

"""
    spy(f::Function)

Run the function without any patches. Using `spy` is more efficient than [`apply`](@ref)
due to the zero patch overhead.
"""
function spy(f::Function)
    reset_statistics()
    f()
end

"""
    called_exactly_once(f::Function, args...; kwargs...)

Return `true` if the function `f` with the provided `args` and `kwargs` was called
exactly once. This can be used after any executing a test script with mockable functions.
"""
called_exactly_once(f::Function, args...; kwargs...) = count_calls(f, args; kwargs...) == 1

"""
    called_at_least_once(f::Function, args...; kwargs...)

Return `true` if the function `f` with the provided `args` and `kwargs` was called
at least once. This can be used after any executing a test script with mockable functions.
"""
called_at_least_once(f::Function, args...; kwargs...) = count_calls(f, args; kwargs...) >= 1

"""
    was_not_called(f::Function, args...; kwargs...)

Return `true` if the function `f` with the provided `args` and `kwargs` was not called
at all. This can be used after any executing a test script with mockable functions.
"""
was_not_called(f::Function, args...; kwargs...)        = count_calls(f, args; kwargs...) == 0

# Spy recordings

materialize_kwargs(kwargs) = Any[p for p in kwargs]

function record_call(f::Function, args; kwargs...)
    kwargs = materialize_kwargs(kwargs)
    @debug "record_call" f args kwargs
    key = (f, args, kwargs)
    if haskey(STATS, key)
        STATS[key] += 1
    else
        STATS[key] = 1
    end
end

function count_calls(f::Function, args; kwargs...)
    kwargs = materialize_kwargs(kwargs)
    @debug "count_calls" f args kwargs
    key = (f, args, kwargs)
    return get(STATS, key, 0)
end

function reset_statistics()
    empty!(STATS)
end
