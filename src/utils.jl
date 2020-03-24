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
    f, ls = first(t), NamedTuple{tail(names)}(t)
    ff = f isa AbstractVector ? NamedTuple{(first(names),)}((f,)) : NamedTuple()
    return merge(ff, keepvectors(ls))
end
keepvectors(::NamedTuple{()}) = NamedTuple()
