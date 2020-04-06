struct DimsSelector{N} <: AbstractContextual
    dims::NTuple{N, Int}
end
dims(args...) = DimsSelector(args)

Broadcast.broadcastable(d::DimsSelector) = fill(d)

Base.:(==)(s1::DimsSelector, s2::DimsSelector) = s1.dims == s2.dims
Base.isless(s1::DimsSelector, s2::DimsSelector) = isless(s1.dims, s2.dims)

function extract_column(t, col::Union{Symbol, Int})
    colname = col isa Symbol ? col : columnnames(t)[col]
    return NamedDimsArray{(colname,)}(getcolumn(t, col))
end
extract_column(t, c::Union{Tuple, NamedTuple}) = map(x -> extract_column(t, x), c)
extract_column(t, c::Style) = Style(extract_column(t, c.nt))
extract_column(t, v::AbstractArray) = v
extract_column(t, v::Ref) = fill(v[], length(extract_column(t, 1)))

clamp(x, l) = l == 1 ? clamp(x) : x
clamp(x::AbstractRange) = Base.OneTo(1)
clamp(x::Integer) = 1

extract(v::NamedTuple, I) = map(t -> extract(t, I), v)
function extract(v, I)
    if isempty(axes(v))
        val = v[]
        val isa DimsSelector || return val
        if any(i -> !isa(i, Integer), I)
            fi = map(first, I)
            fill(Tuple(fi[d] for d in val.dims), filter(i -> isa(i, AbstractRange), I)...)
        else
            # TODO: use something that has isless
            Ref(Tuple(I[d] for d in val.dims))
        end
    else
        itr = (clamp(I[i], length(ax)) for (i, ax) in enumerate(axes(v)))
        v[itr...]
    end
end

function expand(s::Style)
    any(t -> isa(t, DimsSelector), s.nt) || return [s]
    nt = map(Broadcast.broadcastable, s.nt)
    shape = Broadcast.combine_axes(nt...)
    seldims = ntuple(length(shape)) do i
        any(t -> isa(t, DimsSelector) && (i in t.dims), s.nt)
    end
    indices = map((a, b) -> ifelse(a, b, (b,)), seldims, shape)
    nts = map(Iterators.product(indices...)) do I
        extract(nt, I)
    end
    return vec(map(Style, nts))
end

function expand(g::GraphicalOrContextual)
    l = layers(g)
    dict = LayerDict()
    for (key, val) in pairs(l)
        dict[key] = reduce(vcat, expand.(val))
    end
    return Layers(dict)
end

function (s::GraphicalOrContextual)(t)
    l = layers(expand(s))
    cols = coldict(t)
    dict = LayerDict()
    for (sp, styles) in pairs(l)
        dict[sp] = map(style -> extract_column(cols, style), styles)
    end
    return Layers(dict)
end

function (s::GraphicalOrContextual)(c::AbstractFeatureCollection)
    cols = OrderedDict{Symbol, AbstractVector}()
    cols[:geometry] = Vector{Vector{Point2f0}}(undef, 0)
    for f in c.features
        geom = GeoInterface.geometry(f)
        coords = geom isa AbstractMultiPolygon ? coordinates(geom) : [coordinates(geom)]
        polies = [Point2f0.(first(c)) for c in coords]
        append!(cols[:geometry], polies)
        np = length(polies)
        for (key, val) in pairs(GeoInterface.properties(f))
            k = Symbol(key)
            v = get(cols, k, Union{}[])
            vs = fill(val, np)
            cols[k] = val isa eltype(v) ? append!(v, vs) : vcat(v, vs)
        end
    end
    return s(cols)
end
