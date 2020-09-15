struct Fallback end

struct PatchStore{K,V}
    dct::Dict{K,V}
    prev::Dict{K,V}
end

"Data type for object returned by `Expr.splitdef` function."
const FunctionDef = Dict{Symbol, Any}
