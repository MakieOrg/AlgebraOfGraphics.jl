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

function jointable(tables, ::NamedTuple{names}) where names
    vals = map(names) do name
        vcat((get(table, name, Union{}[]) for table in tables)...)
    end
    NamedTuple{names}(vals)
end

rankdict(d) = Dict(val => i for (i, val) in enumerate(uniquesorted(vec(d))))

function rankdicts(ts)
    tables = map(t -> primary(group(t)).kwargs, ts) |> jointable
    return map(rankdict, tables)
end

# StructArray utils

_unwrap(::Type) = false
_unwrap(::Type{<:Union{Tuple, NamedTuple}}) = true
_unwrap(::Type{<:Union{Tuple{}, NamedTuple{(), Tuple{}}}}) = false

function soa(m)
    res = StructArray(m, unwrap=_unwrap)
    args = res.args isa StructArray ? fieldarrays(res.args) : ()
    kwargs = res.kwargs isa StructArray ? fieldarrays(res.kwargs) : NamedTuple()
    return MixedTuple(args, kwargs)
end

function aos(m::MixedTuple)
    res = broadcast(m.args..., m.kwargs...) do args...
        _rename(args, m)
    end
    res isa MixedTuple ? fill(res) : res
end

function keyvalue(p::MixedTuple, d::MixedTuple)
    isempty(p) && isempty(d) && error("Both arguments are empty")
    isempty(p) && return ((mixedtuple(), el) for el in aos(d))
    isempty(d) && return ((el, mixedtuple()) for el in aos(p))
    return zip(aos(p), aos(d))
end

wrap_cols(s::AbstractArray) = fill(s)
wrap_cols(s::AbstractArray{<:AbstractArray}) = s

_append!!(v, itr) = append!!(v, itr)
_append!!(v::StructArray{NamedTuple{(),Tuple{}}}, itr) = collect_structarray(itr)

collect_structarray_flattened(itr) = foldl(_append!!, itr, init = StructArray())

