
const STATS = Dict()

# Verifications

function spy(f::Function)
    reset_statistics()
    f()
end

verify_none(args...)           = count_calls(args...) ==0
verify_exactly_once(args...)   = count_calls(args...) == 1
verify_at_least_once(args...)  = count_calls(args...) > 0
verify_exact_count(args...; n) = count_calls(args...) == n

# Spy recordings

function record_call(mod, func, args...)
    key = (mod, func, args...)
    if haskey(STATS, key)
        STATS[key] += 1
    else
        STATS[key] = 1
    end
end

function count_calls(mod, func, args...)
    key = (mod, func, args...)
    return get(STATS, key, 0)
end

function reset_statistics()
    empty!(STATS)
end
