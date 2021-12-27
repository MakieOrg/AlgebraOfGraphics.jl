const KeyType = Union{Symbol, Int}

const Arguments = Vector{Any}
const NamedArguments = Dictionary{Symbol, Any}
const MixedArguments = Dictionary{KeyType, Any}

# make a copy with distinct keys
function dictcopy(d::AbstractDictionary)
    out = similar(copy(keys(d)), eltype(d))
    return copyto!(out, d)
end

function set(d::AbstractDictionary, ps::Pair...)
    res = dictcopy(d)
    for (k, v) in ps
        set!(res, k, v)
    end
    return res
end

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

function valid_options(nt)
    ks = filter(k -> nt[k] !== automatic, keys(nt))
    return NamedTuple{ks}(nt)
end