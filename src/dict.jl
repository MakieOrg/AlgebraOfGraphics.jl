# Extremely basic dict-like type

struct BasicDict{K, V}
    keys::Vector{K}
    values::Vector{V}
end

function BasicDict{K, V}(pairs=()) where {K, V}
    keys, values = K[], V[]
    for (key, value) in pairs
        push!(keys, key)
        push!(values, value)
    end
    return BasicDict{K, V}(keys, values)
end

Base.copy(d::BasicDict) = BasicDict(copy(d.keys), copy(d.values))

Base.pairs(d::BasicDict) = Iterators.map(Pair, d.keys, d.values)
Base.keys(d::BasicDict) = d.keys
Base.values(d::BasicDict) = d.values

Base.map(f, d::BasicDict) = BasicDict(d.keys, map(f, d.values))
function Base.get(d::BasicDict, key, default)
    idx = findfirst(isequal(key), d.keys)
    return isnothing(idx) ? default : d.values[idx]
end

Base.getindex(d::BasicDict, key) = get(d, key, nothing)

function set!(d::BasicDict, key, value)
    idx = findfirst(d.keys, key)
    if isnothing(idx)
        push!(d.keys, key)
        push!(d.values, value)
    else
        d.keys[idx] = key
        d.values[idx] = value
    end
    return d
end

function Base.merge(d1::BasicDict, d2::BasicDict)
    d = copy(d1)
    for (key, value) in pairs(d2)
        set!(d, key, value)
    end
    return d
end

## Parameter-free version

const SimpleDict = BasicDict{Symbol, Any}

map_pairs(f, v::AbstractVector) = collect(Any, Iterators.map(f, pairs(v)))
map_pairs(f, s::SimpleDict) = SimpleDict(Iterators.map(f, pairs(s)))

function splice_if!(f, d::BasicDict)
    idxs = findall(f, d.values)
    return BasicDict(splice!(d.keys, idxs), splice!(d.values, idxs))
end
