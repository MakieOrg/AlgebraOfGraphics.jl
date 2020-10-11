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
rank(v::AbstractArray) = rank(only(v))

function get_attr(d::DiscreteScale, value, unique)
    v = strip_name(value)
    # Could be tricky in case of many datasets
    n = sum(t -> !isless(rank(v), rank(t)), unique)
    scale = d.options
    return scale === nothing ? n : scale[mod1(n, length(scale))]
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

function get_extrema(specs::AbstractVector{<:AbstractElement})
    d = Dict{Symbol, NTuple{2, Float64}}()
    for spec in specs
        bind = spec.bind
        for (k, val) in pairs(bind.value)
            a, b = get(d, k, (Inf, - Inf))
            a′, b′ = val isa AbstractVector{<:Number} ? extrema(val) : (Inf, -Inf)
            d[k] = (min(a, a′), max(b, b′))
        end
    end
    return d
end

function get_unique(specs::AbstractVector{<:AbstractElement})
    d = Dict{Symbol, Set{Any}}()
    for spec in specs
        pkeys = spec.pkeys
        for (k, val) in pairs(pkeys)
            grp = strip_name(val)
            v = get!(d, k, Set())
            push!(v, grp)
        end
    end
    return d
end

function computescales(specs)
    unique_dict = get_unique(specs)
    extrema_dict = get_extrema(specs)
    [computescales(spec, unique_dict, extrema_dict) for spec in specs]
end

function computescales(spec::Spec{T}, unique_dict, extrema_dict) where {T}
    # temporary! Should have a sensible default scales set,
    # both discrete and continuous
    scales[] = (; AbstractPlotting.current_default_theme()[:palette]...)
    l = (layout_x = nothing, layout_y = nothing)
    discrete_scales = map(DiscreteScale, merge(scales[], spec.options, l))
    continuous_scales = map(ContinuousScale, spec.options)
    disc_options = applytheme(discrete_scales, spec.pkeys, unique_dict)
    cont_options = applytheme(continuous_scales, spec.bind, extrema_dict)
    options = foldl(merge, (spec.options, disc_options, cont_options))
    return Spec{T}(pkeys=spec.pkeys, bind=spec.bind, options=options)
end

applytheme(scales, bind::Bind, metadata) = applytheme(scales, bind.value, metadata)
function applytheme(scales, grp::NamedTuple{names}, metadata) where names
    res = map(names) do key
        haskey(scales, key) ? get_attr(scales[key], grp[key], metadata[key]) : grp[key]
    end
    return NamedTuple{names}(res)
end
