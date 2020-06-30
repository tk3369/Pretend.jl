module Pretend

using Base: Callable
using ExprTools: splitdef, combinedef

export @mockable
export apply
export Fallback

include("types.jl")
include("activation.jl")
include("patchstore.jl")
include("mock.jl")

end
