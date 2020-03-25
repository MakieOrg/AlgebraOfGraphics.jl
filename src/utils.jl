# MixedTuple

struct MixedTuple{T<:Tuple, NT<:NamedTuple}
    args::T
    kwargs::NT
end

const Tup = Union{Tuple, NamedTuple, MixedTuple}

function mixedtuple(args...; kwargs...)
    nt = values(kwargs)
    MixedTuple(args, nt)
end

Base.iterate(m::MixedTuple) = Base.iterate((m.args..., m.kwargs...))
Base.iterate(m::MixedTuple, i) = Base.iterate((m.args..., m.kwargs...), i)
Base.length(m::MixedTuple) = length(m.args) + length(m.kwargs)

function Base.eltype(::Type{MixedTuple{T, NT}}) where {T, NT}
    Base.promote_typejoin(eltype(T), eltype(NT))
end

function Base.map(f, m::MixedTuple, ms::MixedTuple...)
    args = map(t -> t.args, (m, ms...))
    kwargs = map(t -> t.kwargs, (m, ms...))
    return MixedTuple(map(f, args...), map(f, kwargs...))
end

function Base.show(io::IO, mt::MixedTuple)
    print(io, "MixedTuple")
    args, kwargs = mt.args, mt.kwargs
    print(io, "(")
    kwargs = values(kwargs)
    na, nk = length(args), length(kwargs)
    for i in 1:na
        show(io, args[i])
        if i < na + nk
            print(io, ", ")
        end
    end
    for i in 1:nk
        print(io, keys(kwargs)[i])
        print(io, " = ")
        show(io, kwargs[i])
        if i < nk
            print(io, ", ")
        end
    end
    print(io, ")")
end

function Base.merge(a::MixedTuple, b::MixedTuple)
    tup = (a.args..., b.args...)
    nt = merge(a.kwargs, b.kwargs)
    return MixedTuple(tup, nt)
end

function Base.:(==)(m1::MixedTuple, m2::MixedTuple)
    m1.args == m2.args && m1.kwargs == m2.kwargs
end
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
addnames(m::MixedTuple, args...) = addnames(m.kwargs, args...)

function aos(m::MixedTuple)
    res = MixedTuple.(tuple.(m.args...), addnames.(Ref(m), m.kwargs...))
    return wrapif(res, MixedTuple)
end
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

rankdicts(ts) = map(rankdict, jointable(map(primarytable, ts)))
