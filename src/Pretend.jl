module Pretend

using Base: Callable
using ExprTools: splitdef, combinedef

export @mockable
export register_patch, apply
export Fallback

include("types.jl")
include("mock.jl")

end
