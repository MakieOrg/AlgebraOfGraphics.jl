const KeyType = Union{Symbol, Int}

const Arguments = Vector{Any}
const NamedArguments = Dictionary{Symbol, Any}

arguments(x) = collect(Any, x)
namedarguments(x) = NamedArguments(keys(x), values(x))

function separate(f, d::AbstractDictionary)
    d1, d2 = empty(d), empty(d)
    for (k, v) in pairs(d)
        target = ifelse(f(v), d1, d2)
        insert!(target, k, v)
    end
    return d1, d2
end

# `f` takes a pair and returns a unique value
function map_pairs(f, s)
    ks, vs = keys(s), values(s)
    res = collect(Any, Iterators.map(f∘Pair,  ks, vs))
    return eltype(ks) <: Symbol ? NamedArguments(collect(Symbol, ks), res) : res
end
