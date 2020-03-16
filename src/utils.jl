concatenate(v::Union{Tuple, NamedTuple}...) = map(concatenate, v...)
concatenate(v::AbstractArray...) = vcat(v...)

ncols(v::Tuple) = length(v)
ncols(v::AbstractVector) = 1

extract_view(v::Union{Tuple, NamedTuple}, idxs) = map(x -> extract_view(x, idxs), v)
extract_view(v::AbstractVector, idxs) = view(v, idxs)

function extract_view(v::Select, idxs)
    Select(
           map(x -> extract_view(x, idxs), v.args)...;
           map(x -> extract_view(x, idxs), v.kwargs)...
          )
end

extract_view(v::Union{Tuple, NamedTuple}, idxs, n) = extract_view(v[n], idxs)
extract_view(v::AbstractVector, idxs, n) = view(v, idxs)

function extract_view(v::Select, idxs, n)
    Select(
           map(x -> extract_view(x, idxs, n), v.args)...;
           map(x -> extract_view(x, idxs, n), v.kwargs)...
          )
end

extract_column(t, c::Union{Tuple, NamedTuple}) = map(x -> extract_column(t, x), c)
extract_column(t, col::AbstractVector) = col
extract_column(t, col::Symbol) = getproperty(t, col)
extract_column(t, col::Integer) = getindex(t, col)

_extract_columns(t, tup::Union{Tuple, NamedTuple}) = map(col -> extract_column(t, col), tup)

function _extract_columns(t, select::Select)
    Select(
           _extract_columns(t, select.args)...;
           _extract_columns(t, select.kwargs)...
          )
end

_extract_columns(t, grp::Group) = Group(; _extract_columns(t, grp.columns)...)

function extract_columns(d::Data, g)
    t = d.table
    t === nothing ? g : _extract_columns(t, g)
end

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

# TupleUtils

keeptype(t::Tuple{T, Vararg}, ::Type{T}) where {T} = (first(t), keeptype(tail(t), T)...)
keeptype(t::Tuple, ::Type{T}) where {T} = keeptype(tail(t), T)
keeptype(t::Tuple{}, ::Type{T}) where {T} = ()

droptype(t::Tuple{T, Vararg}, ::Type{T}) where {T} = droptype(tail(t), T)
droptype(t::Tuple, ::Type{T}) where {T} = (first(t), droptype(tail(t), T)...)
droptype(t::Tuple{}, ::Type{T}) where {T} = ()

struct Class
    i::Int
end
Base.isless(a::Class, b::Class) = isless(a.i, b.i)
+(a::Class, i::Int) = Class(a.i+i)

struct Counter{S}
    nt::S
end
function Base.iterate(c::Counter, st = c.nt)
    st += 1
    return map(_ -> st, c.nt), st 
end
Base.eltype(::Type{Counter{T}}) where {T} = T
Base.IteratorSize(::Type{<:Counter}) = Base.IsInfinite()

Counter(syms::Symbol...) = Counter(NamedTuple{syms}(map(_ -> Class(0), syms)))

function _compare(nt1::NamedTuple, nt2::NamedTuple, fields::Tuple)
    f = first(fields)
    haskey(nt2, f) && (getproperty(nt1, f) != getproperty(nt2, f)) && return false
    return _compare(nt1, nt2, tail(fields))
end
_compare(nt1::NamedTuple, nt2::NamedTuple, fields::Tuple{}) = true

consistent(a, b) = consistent(Select(a), Select(b))

function consistent(s1::Select, s2::Select)
    nt1, nt2 = s1.o, s2.o
    return !any(pairs(s1.o)) do (key, val)
        isa(val, Class) && val != get(s2.o, key, val)
    end
end

