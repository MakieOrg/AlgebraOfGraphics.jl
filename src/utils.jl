# PooledArrays utils

function pool(v)
    s = refarray(v)
    pv = PooledArray(s)
    map(pv) do el
        refvalue(v, el)
    end
end

pool(v::PooledVector) = v

pool(v::AbstractVector{<:Integer}) = v

# tabular utils

wrapif(v::T, ::Type{T}) where {T} = fill(v)
wrapif(v, ::Type) = v

addnames(::NamedTuple{names}, args...) where {names} = NamedTuple{names}(args)

function aos(n::NamedTuple)
    res = addnames.(Ref(n), n...)
    return wrapif(res, NamedTuple)
end

function mapcols(f, t)
    cols = columns(t)
    itr = (name => f(getcolumn(cols, name)) for name in columnnames(cols))
    return OrderedDict{Symbol, AbstractVector}(itr)
end
coldict(t) = mapcols(identity, t)
coldict(t, idxs) = mapcols(v -> view(v, idxs), t)

function keepvectors(t::NamedTuple{names}) where names
    f, ls = first(t), NamedTuple{Base.tail(names)}(t)
    ff = f isa AbstractVector ? NamedTuple{(first(names),)}((f,)) : NamedTuple()
    return merge(ff, keepvectors(ls))
end
keepvectors(::NamedTuple{()}) = NamedTuple()

# ranking

jointable(ts) = jointable(ts, foldl(merge, ts))

function jointable(ts, ::NamedTuple{names}) where names
    vals = map(names) do name
        vcat((get(table, name, Union{}[]) for table in ts)...)
    end
    NamedTuple{names}(vals)
end

rankdict(d) = Dict(val => i for (i, val) in enumerate(uniquesorted(vec(d))))

primarytable(t) = fieldarrays(StructArray(p for (p, _) in pairs(t)))

rankdicts(ts) = map(rankdict, jointable(map(primarytable, ts)))

# integer naming utils

function namedtuple(args::Vararg{Any, N}; kwargs...) where N
    syms = ntuple(Symbol, N)
    return merge(NamedTuple{syms}(args), values(kwargs))
end

integerlike(x::Symbol) = tryparse(Int, String(x)) !== nothing
integerlike(x::Integer) = true

positional(ps) = (val for (key, val) in pairs(ps) if integerlike(key))
keyword(ps) = (key => val for (key, val) in pairs(ps) if !integerlike(key))

# naming utils

struct NamedEntry{T}
    name::Symbol
    value::T
end

function Base.isless(n1::NamedEntry, n2::NamedEntry)
    if n1.name != n2.name
        error("Cannot sort named entries with different names")
    end
    isless(n1.value, n2.value)
end

Base.:(==)(n1::NamedEntry, n2::NamedEntry) = n1.name == n2.name && n1.value == n2.value
Base.hash(n::NamedEntry, h::UInt64) = hash((n.name, n.value), hash(NamedEntry, h))
get_name(v::NamedDimsArray) = dimnames(v)[1]
get_name(v::NamedEntry) = v.name

Base.string(n::NamedEntry) = string(s.value)
