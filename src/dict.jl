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

function Base.map(f, d::BasicDict, ds::BasicDict...)
    return BasicDict(d.keys, map(f, map(values, (d, ds...))...))
end

Base.length(d::BasicDict) = length(d.values)
Base.eltype(::Type{BasicDict{K, V}}) where {K, V} = V

Base.iterate(d::BasicDict) = Base.iterate(d.values)
Base.iterate(d::BasicDict, st) = Base.iterate(d.values, st)

findkey(d::BasicDict, key) = findfirst(isequal(key), d.keys)

Base.haskey(d::BasicDict, key) = !isnothing(findkey(d, key))

function Base.get(f::Base.Callable, d::BasicDict, key)
    idx = findkey(d, key)
    return isnothing(idx) ? f() : d.values[idx]
end

function Base.get(d::BasicDict, key, default)
    idx = findkey(d, key)
    return isnothing(idx) ? default : d.values[idx]
end

function Base.getindex(d::BasicDict, key)
    return get(d, key) do
        throw(KeyError(key))
    end
end

function set!(d::BasicDict, key, value)
    idx = findkey(d, key)
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

function splice_if!(f, d::BasicDict)
    idxs = findall(f, d.values)
    return BasicDict(splice!(d.keys, idxs), splice!(d.values, idxs))
end

function Base.convert(::Type{BasicDict{K, V}}, d::BasicDict) where {K, V}
    keys = convert(Vector{K}, d.keys)
    values = convert(Vector{V}, d.values)
    return BasicDict{K, V}(keys, values)
end

Base.convert(::Type{BasicDict{K, V}}, d::BasicDict{K, V}) where {K, V} = d

## Parameter-free version

const SimpleDict = BasicDict{Symbol, Any}

# `f` takes a pair and returns a unique value
function map_pairs(f, s)
    ks, vs = keys(s), values(s)
    res = collect(Any, Iterators.map(f∘Pair,  ks, vs))
    return eltype(ks) <: Symbol ? SimpleDict(collect(Symbol, ks), res) : res
end
