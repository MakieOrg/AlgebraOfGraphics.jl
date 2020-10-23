abstract type AbstractContext <: AbstractElement end

struct Mapping <: AbstractElement
    context::Union{AbstractContext, Nothing}
    value::NamedTuple
end
Mapping(s::NamedTuple=NamedTuple()) = Mapping(nothing, s)
Mapping(c::AbstractContext) = Mapping(c, NamedTuple())
Mapping(s::Mapping) = s

function Base.show(io::IO, s::Mapping)
    print(io, "Mapping with entries ")
    show(io, keys(s.value))
end

mapping(args...; kwargs...) = Mapping(namedtuple(args...; kwargs...))

@deprecate style(args...; kwargs...) mapping(args...; kwargs...)

function Base.:*(s1::Union{Mapping, AbstractContext}, s2::Union{Mapping, AbstractContext})
    merge(Mapping(s1), Mapping(s2))
end

function Base.merge(s1::Mapping, s2::Mapping)
    c1, c2 = s1.context, s2.context
    c = c2 === nothing ? c1 : c2
    if c !== c1 && !isempty(s1.value)
        @warn "Changing context on a non empty mapping"
    end
    return _merge(c, s1, s2)
end
Base.pairs(s::Mapping) = _pairs(s.context, s)

# interface and fallbacks

# Must return a Mapping
_merge(c, s1::Mapping, s2::Mapping) = Mapping(c, merge(s1.value, s2.value))

# Must return a vector of NamedTuple => Mapping pairs
_pairs(c, s::Mapping) = [NamedTuple() => s]

## Dims context

struct DimsSelector{N} <: AbstractContext
    dims::NTuple{N, Int}
end
dims(args...) = DimsSelector(args)

Broadcast.broadcastable(d::DimsSelector) = fill(d)

Base.isless(s1::DimsSelector, s2::DimsSelector) = isless(s1.dims, s2.dims)

function aos(d::NamedTuple{names}) where names
    v = broadcast((args...) -> NamedTuple{names}(args), d...)
    return v isa NamedTuple ? fill(v) : v
end

function adjust(val::DimsSelector, c, nts)
    is = collect(val.dims)
    ax, cf = axes(nts)[is], Tuple(c)[is]
    return LinearIndices(ax)[cf...]
end

# make it a pair list
function _pairs(::DimsSelector{0}, s::Mapping)
    nts = aos(s.value)
    ps = map(CartesianIndices(nts)) do c
        nt = nts[c]
        dskeys = filter(keys(nt)) do key
            nt[key] isa DimsSelector
        end
        dsvalues = map(dskeys) do key
            val = nt[key]
            return adjust(val, c, nts)
        end
        ds = (; zip(dskeys, dsvalues)...)
        nds = Base.structdiff(nt, ds)
        return ds => Mapping(nds)
    end
    return vec(ps)
end

function _pairs(d::DimsSelector, s::Mapping)
    value = map(s.value) do v
        v isa AbstractArray ? mapslices(x -> [x], v; dims=d.dims) : v
    end
    return pairs(Mapping(dims(), value))
end

# data context: integers and symbols are columns

struct DataContext{NT, I<:AbstractVector{Int}} <: AbstractContext
    data::ColumnDict
    pkeys::NT
    perm::I
end

function DataContext(data)
    col = getcolumn(data, 1)
    DataContext(data, NamedTuple(), axes(col, 1))
end

data(x) = DataContext(ColumnDict(x))

iscategorical(v) = !(eltype(v) <: Union{Number,Geometry})

iswrappedcategorical(::Any) = false
iswrappedcategorical(v::AbstractArray{<:Any, 0}) = iscategorical(v[])

# unwrap categorical vectors from the 0-dim array that contains them
function unwrap_categorical(values)
    iter = (k => v[] for (k, v) in pairs(values) if iswrappedcategorical(v))
    return (; iter...)
end

function refine_perm(perm, pc, n)
    if n == length(pc)
        perm
    elseif n == 0
        sortperm(StructArray(pc))
    else
        x, y = pc[n], pc[n+1]
        refine_perm!(copy(perm), pc, n, x, y, 1, length(x))
    end
end

optimize_cols(v::NamedDimsArray) = refs(parent(v))
optimize_cols(v::Union{Tuple, NamedTuple}) = map(optimize_cols, v)

function _merge(c::DataContext, s1::Mapping, s2::Mapping)
    data, pkeys, perm = c.data, c.pkeys, c.perm
    nt = map(val -> extract_columns(data, val), s2.value)
    newpkeys = unwrap_categorical(keyword(nt))
    @assert isempty(intersect(keys(pkeys), keys(newpkeys)))
    allpkeys = merge(pkeys, newpkeys)
    # unwrap from NamedDimsArray to perform the sorting
    allperm = refine_perm(perm, optimize_cols(allpkeys), length(pkeys))
    ctx = DataContext(data, allpkeys, allperm)
    return Mapping(ctx, merge(s1.value, Base.structdiff(nt, newpkeys)))
end

function _pairs(c::DataContext, s::Mapping)
    data, pkeys, perm = c.data, c.pkeys, c.perm
    isempty(pkeys) && return pairs(Mapping(dims(), s.value))
    # unwrap for sorting computations
    itr = GroupPerm(StructArray(optimize_cols(pkeys)), perm)
    sa = StructArray(pkeys)
    nestedpairs = map(itr) do idxs
        i1 = perm[first(idxs)]
        # keep value categorical and preserve name by taking a mini slice (document this!)
        # consider using these levels directly in discrete scales
        k = map(col -> col[i1:i1], pkeys)
        cols = map(s.value) do val
            extract_views(val, perm[idxs])
        end
        [merge(k, p) => v for (p, v) in pairs(Mapping(dims(), cols))]
    end
    return reduce(vcat, nestedpairs)
end

extract_views(cols, idxs) = map(t -> view(t, idxs), cols)
extract_views(cols::DimsSelector, idxs) = cols

function extract_column(t, (nm, f)::Pair)
    colname = nm isa Symbol ? nm : columnnames(t)[nm]
    vals = f(getcolumn(t, nm))
    p = iscategorical(vals) ? categorical(vals) : vals
    return NamedDimsArray{(colname,)}(p)
end
extract_column(t, nm::Union{Symbol, Int}) = extract_column(t, nm => identity)

extract_columns(t, val::DimsSelector) = val
extract_columns(t, val::Union{Tuple, AbstractArray}) = map(v -> extract_column(t, v), val)
extract_columns(t, val) = fill(extract_column(t, val))
