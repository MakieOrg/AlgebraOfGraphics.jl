const Tup = Union{Tuple, NamedTuple, MixedTuple}

struct DimsSelector{T}
    x::T
end
dims(args...) = DimsSelector(args)

Base.isless(a::DimsSelector, b::DimsSelector) = isless(a.x, b.x)

_adjust(x::Tup, shape) = map(t -> _adjust(t, shape), x)
_adjust(x, shape) = x
_adjust(d::DimsSelector, shape) = [_adjust(d, c) for c in CartesianIndices(shape)]
_adjust(d::DimsSelector, c::CartesianIndex) = c[d.x...]

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

# ranking

jointable(ts) = jointable(ts, foldl(merge, ts))

function jointable(ts, ::NamedTuple{names}) where names
    vals = map(names) do name
        vcat((get(table, name, Union{}[]) for table in ts)...)
    end
    NamedTuple{names}(vals)
end

rankdict(d) = Dict(val => i for (i, val) in enumerate(uniquesorted(vec(d))))

function rankdicts(ts)
    trace_list = Iterators.flatten(ts)
    ps = [key for tr in trace_list for (key, _) in keyvalue(tr)]
    tables = jointable(ps)
    return map(rankdict, tables)
end

# tabular utils

addnames(::NamedTuple{names}, args...) where {names} = NamedTuple{names}(args)
addnames(m::MixedTuple, args...) = addnames(m.kwargs, args...)

function aos(m::MixedTuple)
    res = MixedTuple.(tuple.(m.args...), addnames.(Ref(m), m.kwargs...))
    res isa MixedTuple ? fill(res) : res
end
function aos(n::NamedTuple)
    res = addnames.(Ref(n), n...)
    res isa NamedTuple ? fill(res) : res
end

function mapcols(f, t)
    cols = columns(t)
    itr = (name => f(getcolumn(cols, name)) for name in columnnames(cols))
    return OrderedDict{Symbol, AbstractVector}(itr)
end
coldict(t) = mapcols(identity, t)
coldict(t, idxs) = mapcols(v -> view(v, idxs), t)

