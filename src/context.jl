abstract type AbstractContext <: AbstractElement end

struct Style <: AbstractElement
    context::Union{AbstractContext, Nothing}
    value::NamedTuple
end
Style(s::NamedTuple=NamedTuple()) = Style(nothing, s)
Style(c::AbstractContext) = Style(c, NamedTuple())
Style(s::Style) = s

function Base.show(io::IO, s::Style)
    print(io, "Style with entries ")
    show(io, keys(s.value))
end

style(args...; kwargs...) = Style(namedtuple(args...; kwargs...))

function Base.:*(s1::Union{Style, AbstractContext}, s2::Union{Style, AbstractContext})
    merge(Style(s1), Style(s2))
end

function Base.merge(s1::Style, s2::Style)
    c1, c2 = s1.context, s2.context
    c = c2 === nothing ? c1 : c2
    if c !== c1 && !isempty(s1.value)
        @warn "Changing context on a non empty style"
    end
    return _merge(c, s1, s2)
end
Base.pairs(s::Style) = _pairs(s.context, s)

# interface and fallbacks

# Must return a Style
_merge(c, s1::Style, s2::Style) = Style(c, merge(s1.value, s2.value))

# Must return a vector of NamedTuple => Style pairs
_pairs(c, s::Style) = [NamedTuple() => s]

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
function _pairs(::DimsSelector{0}, s::Style)
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
        return ds => Style(nds)
    end
    return vec(ps)
end

function _pairs(d::DimsSelector, s::Style)
    value = map(s.value) do v
        v isa AbstractArray ? mapslices(x -> [x], v; dims=d.dims) : v
    end
    return pairs(Style(dims(), value))
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

iscategorical(v) = !(eltype(v) <: Number)

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

function _merge(c::DataContext, s1::Style, s2::Style)
    data, pkeys, perm = c.data, c.pkeys, c.perm
    nt = map(val -> extract_columns(data, val), s2.value)
    newpkeys = unwrap_categorical(keyword(nt))
    @assert isempty(intersect(keys(pkeys), keys(newpkeys)))
    allpkeys = merge(pkeys, newpkeys)
    # unwrap from NamedDimsArray to perform the sorting
    allperm = refine_perm(perm, optimize_cols(allpkeys), length(pkeys))
    ctx = DataContext(data, allpkeys, allperm)
    return Style(ctx, merge(s1.value, Base.structdiff(nt, newpkeys)))
end

function _pairs(c::DataContext, s::Style)
    data, pkeys, perm = c.data, c.pkeys, c.perm
    isempty(pkeys) && return pairs(Style(dims(), s.value))
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
        [merge(k, p) => v for (p, v) in pairs(Style(dims(), cols))]
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
