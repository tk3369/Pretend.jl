struct Fallback end

struct PatchStore{K,V}
    dct::Dict{K,V}
    prev::Dict{K,V}
end
