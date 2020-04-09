const scales = Observable{Any}(Dict())

abstract type AbstractScale end

struct DiscreteScale
    options::Union{AbstractVector, Nothing}
    function DiscreteScale(x)
        options = x isa AbstractVector ? x : nothing
        return new(options)
    end
end
DiscreteScale(v::AbstractObservable) = DiscreteScale(v[])

rank(c) = levelcode(c)
rank(n::Integer) = n

function get_attr(d::DiscreteScale, value, unique)
    v = strip_name(value)
    # Could be tricky in case of many datasets
    n = sum(t -> !isless(rank(v), rank(t)), unique)
    scale = d.options
    val = scale === nothing ? n : scale[mod1(n, length(scale))]
    LegendEntry(v, Observable(val), name=get_name(value))
end

struct ContinuousScale
    extrema::Union{NTuple{2, Float64}, Nothing}
    function ContinuousScale(x)
        extrema = x isa NTuple{2, Number} ? map(Float64, x) : nothing
        return new(extrema)
    end
end

function get_attr(c::ContinuousScale, value, extrema)
    scale = c.extrema
    scale === nothing && return value
    min, max = extrema
    smin, smax = scale
    @. smin + value * (smax - smin) / (max - min)
end

struct LegendEntry{T}
    name::Symbol
    key::T
    value::Observable
end
get_name(l::LegendEntry) = l.name
strip_name(l::LegendEntry) = l.key

rank(n::LegendEntry) = rank(strip_name(n))

function LegendEntry(key, value=Observable{Any}(nothing); name=Symbol(""))
    return LegendEntry(name, key, value)
end

function get_extrema(layers::AlgebraicDict)
    d = Dict{Symbol, NTuple{2, Float64}}()
    for value in values(layers)
        for stl in values(value)
            for (k, val) in pairs(stl.value)
                a, b = get(d, k, (Inf, - Inf))
                a′, b′ = val isa AbstractVector ? extrema(val) : (Inf, -Inf)
                d[k] = (min(a, a′), max(b, b′))
            end
        end
    end
    return d
end

function get_unique(layers::AlgebraicDict)
    d = Dict{Symbol, Set{Any}}()
    for value in values(layers)
        for pkey in keys(value)
            for (k, val) in pairs(pkey)
                grp = strip_name(val)
                v = get!(d, k, Set())
                push!(v, grp)
            end
        end
    end
    return d
end

function computescales(s::AlgebraicDict)
    unique = get_unique(s)
    extrema = get_extrema(s)
    AlgebraicDict(key => computescales(key, val, unique, extrema) for (key, val) in s)
end
function computescales(s::Spec, dict::AbstractDict, unique, extrema)
    # temporary! Should have a sensible default scales set, both
    # discrete and continuous
    scales[] = (; AbstractPlotting.current_default_theme()[:palette]...)
    l = (layout_x = nothing, layout_y = nothing)
    discrete_scales = map(DiscreteScale, merge(scales[], s.value, l))
    continuous_scales = map(ContinuousScale, s.value)
    ks = [applytheme(discrete_scales, ds, unique) for ds in keys(dict)]
    vs = [Style(applytheme(continuous_scales, cs.value, extrema)) for cs in values(dict)]
    return AlgebraicDict(ks, vs)
end

function applytheme(scales, grp::NamedTuple{names}, metadata) where names
    res = map(names) do key
        haskey(scales, key) ? get_attr(scales[key], grp[key], metadata[key]) : grp[key]
    end
    return NamedTuple{names}(res)
end
