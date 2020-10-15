# tabular utils

struct ColumnDict <: AbstractColumns
    names::Vector{Symbol}
    columns::Vector{AbstractVector}
end

Tables.columnnames(c::ColumnDict) = getfield(c, 1)
Tables.getcolumn(c::ColumnDict, i::Int) = getfield(c, 2)[i]
function Tables.getcolumn(c::ColumnDict, s::Symbol)
    i::Int = findfirst(==(s), columnnames(c))
    getcolumn(c, i)
end

function ColumnDict(t)
    t_cols = columns(t)
    names = collect(columnnames(t_cols))
    cols = map(name -> getcolumn(t_cols, name), names)
    return ColumnDict(names, cols)
end

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
strip_name(v::NamedDimsArray) = unname(v)
get_name(v) = Symbol(" ")
strip_name(v) = v

function extract_names(d::Union{NamedTuple, Tuple})
    ns = map(get_name, d)
    vs = map(strip_name, d)
    return ns, vs
end

function fast_sortable(v)
    v1 = strip_name(v)
    return iscategorical(v1) ? refs(categorical(v1)) : v1
end

fast_sortable(v::StructArray) = StructArray(map(fast_sortable, fieldarrays(v)))