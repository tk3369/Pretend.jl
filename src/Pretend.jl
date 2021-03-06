module Pretend

using Base: Callable
using ExprTools: splitdef, combinedef
using MacroTools: postwalk, rmlines

export @mockable
export apply, mocked, spy
export Fallback

export
    called_at_least_once,
    called_exactly_once,
    was_not_called

include("types.jl")
include("activation.jl")
include("patchstore.jl")
include("mock.jl")
include("spy.jl")

end
