# PooledArrays utils

pool(v::AbstractVector) = pool(v, eltype(v))
pool(v::PooledVector) = v

function pool(v::AbstractVector, ::Type)
    s = refarray(v)
    pv = PooledArray(s)
    map(pv) do el
        refvalue(v, el)
    end
end

pool(v::Vector, ::Type{<:Integer}) = v
pool(v::AbstractVector, ::Type{<:Integer}) = collect(v)

# tabular utils

function mapcols(f, t)
    cols = columns(t)
    itr = (name => f(getcolumn(cols, name)) for name in columnnames(cols))
    return OrderedDict{Symbol, AbstractVector}(itr)
end
coldict(t) = mapcols(identity, t)
coldict(t, idxs) = mapcols(v -> view(v, idxs), t)

# integer naming utils

function namedtuple(args::Vararg{Any, N}; kwargs...) where N
    syms = ntuple(Symbol, N)
    return merge(NamedTuple{syms}(args), values(kwargs))
end

function remove_intkeys(nt::NamedTuple, t::NTuple{N, Any}) where N
    Base.structdiff(nt, NamedTuple{ntuple(Symbol, N)}(t))
end
remove_intkeys(nt) = remove_intkeys(nt, Tuple(nt))
reorder(nt::NamedTuple) = Tuple(nt[Symbol(i)] for i in keys(keys(nt)))

function split(ps::NamedTuple)
    nt = remove_intkeys(ps)
    t = Base.structdiff(ps, nt)
    return reorder(t), nt
end
positional(ps::NamedTuple) = first(split(ps))
keyword(ps::NamedTuple) = last(split(ps))

# naming utils

get_name(v::NamedDimsArray) = dimnames(v)[1]
strip_name(v::NamedDimsArray) = parent(v)
get_name(v) = Symbol("")
strip_name(v) = v

function extract_names(d::Union{NamedTuple, Tuple})
    ns = map(get_name, d)
    vs = map(strip_name, d)
    return ns, vs
end

function extract_names(s::Style)
    ns, vs = extract_names(s.nt)
    return ns, Style(vs)
end
