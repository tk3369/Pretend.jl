module Pretend

using Base: Callable
using ExprTools: splitdef, combinedef

export @mockable
export apply, spy
export Fallback

export
    verify_at_least_once,
    verify_exact_count,
    verify_exactly_once,
    verify_none

include("types.jl")
include("activation.jl")
include("patchstore.jl")
include("mock.jl")
include("spy.jl")

end
