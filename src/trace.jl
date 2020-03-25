struct Spec{T}
    args::Tuple
    kwargs::NamedTuple
end

to_spec(args...; kwargs...) = Spec{Any}(args, values(kwargs))
to_spec(::Type{T}, args...; kwargs...) where {T} = Spec{T}(args, values(kwargs))
plottype(::Spec{T}) where {T} = T

function Base.merge(t1::Spec{T1}, t2::Spec{T2}) where {T1, T2}
    T = T2 === Any ? T1 : T2
    args = (t1.args..., t2.args...)
    kwargs = merge(t1.kwargs, t2.kwargs)
    return Spec{T}(args, kwargs)
end

# Trace

abstract type AbstractTrace end

primarytable(t::AbstractTrace) = fieldarrays(StructArray(p for (p, _) in pairs(t)))

# Interface: 
# key-value iterator (pairs)
# trace
# support (t2::Trace)(t1::MyTrace) (returns a `MyTrace`)

struct Trace{P<:NamedTuple, D<:MixedTuple, T} <: AbstractTrace
    primary::P
    data::D
    spec::Spec{T}
end

function Trace(;
               primary=NamedTuple(),
               data=mixedtuple(),
               spec=to_spec()
              )
    return Trace(primary, data, spec)
end

primary(s::Trace) = s.primary
data(s::Trace)    = s.data
spec(s::Trace)    = s.spec

primary(; kwargs...)     = tree(Trace(primary=values(kwargs)))
data(args...; kwargs...) = tree(Trace(data=mixedtuple(args...; kwargs...)))
spec(args...; kwargs...) = tree(Trace(spec=to_spec(args...; kwargs...)))

struct DimsSelector{T}
    x::T
end
dims(args...) = DimsSelector(args)

_adjust(x::Tup, shape) = map(t -> _adjust(t, shape), x)
_adjust(x, shape) = x
_adjust(d::DimsSelector, shape) = [_adjust(d, c) for c in CartesianIndices(shape)]
_adjust(d::DimsSelector, c::CartesianIndex) = c[d.x...]

function Base.pairs(s::Trace)
    d = aos(data(s))
    p = aos(_adjust(primary(s), axes(d)))
    return wrapif(p .=> d, Pair)
end

function (t::Trace)(s::T) where {T<:AbstractTrace}
    error("No method implemented to call a `Trace` on $T")
end
function (s2::Trace)(s1::Trace) 
    p1, p2 = primary(s1), primary(s2)
    if !isempty(keys(p1) ∩ keys(p2))
        error("Cannot combine with overlapping primary keys")
    end
    d1, d2 = data(s1), data(s2)
    m1, m2 = spec(s1), spec(s2)
    p = merge(p1, p2)
    d = merge(d1, d2)
    m = merge(m1, m2)
    return Trace(p, d, m)
end

function Base.show(io::IO, s::Trace)
    print(io, "Trace {...}")
end

struct DataTrace{L<:AbstractArray, T} <: AbstractTrace
    list::L
    spec::Spec{T}
end
spec(t::DataTrace) = t.spec
function Base.pairs(t::DataTrace)
    itr = (pairs(Trace(primary=p, data=d)) for (_, (p, d)) in t.list)
    return collect(Iterators.flatten(itr))
end

function Base.show(io::IO, s::DataTrace)
    print(io, "DataTrace of length $(length(pairs(s)))")
end

function extract_column(t, col::Union{Symbol, Int}, wrap=false)
    v = getcolumn(t, col)
    return wrap ? fill(v) : v
end
extract_column(t, c::Tup, wrap=false) = map(x -> extract_column(t, x, wrap), c)
extract_column(t, c::AbstractArray, wrap=false) = map(x -> extract_column(t, x, false), c)
extract_column(t, c::DimsSelector, wrap=false) = c

function group(cols, p, d)
    pv = keepvectors(p)
    list = if isempty(pv)
        [(cols, p => d)]
    else
        sa = StructArray(map(pool, pv))
        map(finduniquesorted(sa)) do (k, idxs)
            v = map(t -> map(x -> view(x, idxs), t), d)
            subtable = coldict(cols, idxs)
            (subtable, merge(p, map(fill, k)) => v)
        end
    end
end

function (s2::Trace)(s1::DataTrace)
    # TODO: add labels to spec
    itr = Base.Generator(s1.list) do (cols, (p, d))
        p2 = extract_column(cols, primary(s2))
        d2 = extract_column(cols, data(s2), true)
        return group(cols, merge(p, p2), merge(d, d2))
    end
    return DataTrace(collect(Iterators.flatten(itr)), merge(spec(s1), spec(s2)))
end

function table(x)
    t = coldict(x)
    dt = DataTrace([(t, NamedTuple() => mixedtuple())], to_spec())
    return tree(dt)
end

