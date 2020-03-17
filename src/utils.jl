const Tup = Union{Tuple, NamedTuple, MixedTuple}

concatenate(v::Tup...) = map(concatenate, v...)
concatenate(v::AbstractArray...) = vcat(v...)

extract_view(v::Tup, idxs) = map(x -> extract_view(x, idxs), v)
extract_view(v::AbstractVector, idxs) = view(v, idxs)

extract_column(t, c::Tup) = map(x -> extract_column(t, x), c)
extract_column(t, col::AbstractVector) = col
extract_column(t, col::Symbol) = getproperty(t, col)
extract_column(t, col::Integer) = getindex(t, col)

# show utils

function _show(io::IO, args...; kwargs...)
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

consistent(a::Spec, b::Spec) = consistent(a.primary.kwargs, b.primary.kwargs)

function consistent(nt1::NamedTuple, nt2::NamedTuple)
    all(((key, val),) -> val == get(nt2, key, val), pairs(nt1))
end

# TupleUtils
# TODO what is needed here? consider wide data case and facet!

struct Counter{S}
    nt::S
end
function Base.iterate(c::Counter, st = c.nt)
    st = map(x -> x + 1, st)
    return st, st
end
Base.eltype(::Type{Counter{T}}) where {T} = T
Base.IteratorSize(::Type{<:Counter}) = Base.IsInfinite()

Counter(syms::Symbol...) = Counter(NamedTuple{syms}(map(_ -> 0, syms)))

## counting tools

function jointable(ts)
    tables = map(columntable, ts)
    return jointable(tables, foldl(merge, tables))
end

function jointable(tables, ::NamedTuple{names}) where names
    vals = map(names) do name
        vcat((get(table, name, Union{}) for table in tables)...)
    end
    NamedTuple{names}(vals)
end

rankdict(d) = Dict(val => i for (i, val) in enumerate(uniquesorted(d)))
rankdicts(ts) = map(rankdict, jointable(ts))

