abstract type AbstractContext end

# Fallbacks

apply_context(::Union{Nothing, AbstractContext}, t::Trace) = t
group(::Union{Nothing, AbstractContext}, t::Trace) = Traces([t])

traces(::Union{Nothing, AbstractContext}, t::Trace) = [t]

function combine(c::Union{Nothing, AbstractContext}, s1::Trace, s2::Trace)
    s2 = apply_context(c, s2)
    p1, p2 = primary(s1), primary(s2)
    if !isempty(keys(p1) ∩ keys(p2))
        error("Cannot combine with overlapping primary keys")
    end
    d1, d2 = data(s1), data(s2)
    m1, m2 = metadata(s1), metadata(s2)
    p = merge(p1, p2)
    d = merge(d1, d2)
    m = merge(m1, m2)
    return group(c, Trace(c, p, d, m))
end

# Broadcast context (default)

function keyvalue(p::NamedTuple, d::MixedTuple)
    isempty(p) && isempty(d) && error("Both arguments are empty")
    isempty(p) && return ((NamedTuple(), el) for el in aos(d))
    isempty(d) && return ((el, mixedtuple()) for el in StructArray(p))
    data = aos(d)
    primary = StructArray(_adjust(p, axes(data)))
    return zip(primary, data)
end

struct BroadcastContext <: AbstractContext end

function traces(c::Union{Nothing, BroadcastContext}, t::Trace)
    return [Trace(c, p, d, metadata(t)) for (p, d) in keyvalue(primary(t), data(t))]
end

# Column Context

struct ColumnContext{T} <: AbstractContext
    table::T
end
table(x) = context(ColumnContext(coldict(x)))

extract_column(t, col::Union{Symbol, Int}) = getcolumn(t, col)
extract_column(t, c::Union{Tup}) = map(x -> extract_column(t, x), c)

function apply_context(c::ColumnContext, tr::Trace)
    cols = columns(c.table)
    p = extract_column(cols, primary(tr))
    d = extract_column(cols, data(tr))
    m = metadata(tr) # TODO: add labels here
    return Trace(c, p, d, m)
end

function keepvectors(t::NamedTuple{names}) where names
    f, ls = first(t), NamedTuple{tail(names)}(t)
    ff = f isa AbstractVector ? NamedTuple{(first(names),)}((f,)) : NamedTuple()
    return merge(ff, keepvectors(ls))
end
keepvectors(::NamedTuple{()}) = NamedTuple()

function group(c::ColumnContext, tr::Trace)
    p, d, m = primary(tr), data(tr), metadata(tr)
    pv = keepvectors(p)
    list = if isempty(pv)
        [Trace(c, p, d, m)]
    else
        pv = keepvectors(p)
        sa = StructArray(map(pool, pv))
        map(finduniquesorted(sa)) do (k, idxs)
            v = map(t -> view(t, idxs), d)
            subtable = ColumnContext(coldict(c.table, idxs))
            Trace(subtable, merge(p, k), v, m)
        end
    end
    return Traces(list)
end
