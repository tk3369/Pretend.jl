
const STATS = Dict()

# Verifications

function spy(f::Function)
    reset_statistics()
    f()
end

called_exactly_once(f::Function, args...)      = count_calls(f, args) == 1
called_at_least_once(f::Function, args...)     = count_calls(f, args) >= 1
called_exactly_n(f::Function, args...; n::Int) = count_calls(f, args) == n
was_not_called(f::Function, args...)           = count_calls(f, args) == 0

# Spy recordings

function record_call(f::Function, args)
    key = (f, args)
    if haskey(STATS, key)
        STATS[key] += 1
    else
        STATS[key] = 1
    end
end

function count_calls(f::Function, args)
    key = (f, args)
    return get(STATS, key, 0)
end

function reset_statistics()
    empty!(STATS)
end
