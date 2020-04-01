# Recursive utils

function merge_rec(a::NamedTuple, b::NamedTuple)
    s = merge(a, b)
    vals = map(keys(s)) do key
        merge_rec(get(a, key, missing), get(b, key, missing))
    end
    return (; zip(keys(s), vals)...)
end
merge_rec(a, b) = coalesce(b, a)

# PooledArrays utils

function pool(v::AbstractVector)
    s = refarray(v)
    pv = PooledArray(s)
    map(pv) do el
        refvalue(v, el)
    end
end

pool(v::PooledVector) = v

pool(v::AbstractVector{<:Integer}) = v

# tabular utils

function mapcols(f, t)
    cols = columns(t)
    itr = (name => f(getcolumn(cols, name)) for name in columnnames(cols))
    return OrderedDict{Symbol, AbstractVector}(itr)
end
coldict(t) = mapcols(identity, t)
coldict(t, idxs) = mapcols(v -> view(v, idxs), t)

# ranking

rankdict(d) = Dict(val => i for (i, val) in enumerate(uniquesorted(vec(d))))
rankdict(d::NamedTuple) = map(rankdict, d)

# TODO: is this a performance issue in practice?
jointables(ts) = foldl(merge_vcat, ts)
merge_vcat(a, b) = vcat(a, b)
function merge_vcat(t1::NamedTuple, t2::NamedTuple)
    t3 = merge(t1, t2)
    names = keys(t3)
    res = map(names) do key
        haskey(t1, key) || return t2
        haskey(t2, key) || return t1
        return merge_vcat(t1[key], t2[key])
    end
    return NamedTuple{names}(res)
end

fieldarrays_rec(s::StructArray) = map(fieldarrays_rec, fieldarrays(s))
fieldarrays_rec(v) = v

function primarytable(t)
    s = StructArray(
                    (p for (p, _) in pairs(t)),
                    unwrap = t -> t <: NamedTuple
                   )
    return fieldarrays_rec(s)
end

function rankdicts(ts)
    t = jointables(map(primarytable, ts))
    return rankdict(t)
end

# integer naming utils

function namedtuple(args::Vararg{Any, N}; kwargs...) where N
    syms = ntuple(Symbol, N)
    return merge(NamedTuple{syms}(args), values(kwargs))
end

integerlike(x::Symbol) = tryparse(Int, String(x)) !== nothing
integerlike(x::Integer) = true

# TODO: keep order from parsed symbols
positional(ps) = (val for (key, val) in pairs(ps) if integerlike(key))
keyword(ps) = (key => val for (key, val) in pairs(ps) if !integerlike(key))

# naming utils

struct NamedEntry{T}
    name::Symbol
    value::T
end
NamedEntry(name, value) = NamedEntry(Symbol(name), value)

function Base.isless(n1::NamedEntry, n2::NamedEntry)
    if n1.name != n2.name
        error("Cannot sort named entries with different names")
    end
    isless(n1.value, n2.value)
end

Base.:(==)(n1::NamedEntry, n2::NamedEntry) = n1.name == n2.name && n1.value == n2.value
Base.hash(n::NamedEntry, h::UInt64) = hash((n.name, n.value), hash(NamedEntry, h))

get_name(v::NamedDimsArray) = dimnames(v)[1]
strip_name(v::NamedDimsArray) = parent(v)
get_name(v::NamedEntry) = v.name
strip_name(v::NamedEntry) = v.value
get_name(v) = Symbol("")
strip_name(v) = v

Base.string(n::NamedEntry) = string(n.value)
