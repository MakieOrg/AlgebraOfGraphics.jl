apply_palette(p::AbstractVector, uv) = [cycle(p, idx) for idx in eachindex(uv)]
apply_palette(::Automatic, uv) = eachindex(uv)
apply_palette(p, uv) = map(p, eachindex(uv))

# TODO: add more customizations?
struct Wrap end

const wrap = Wrap()

function apply_palette(::Wrap, uv)
    ncols = ceil(Int, sqrt(length(uv)))
    return [fldmod1(idx, ncols) for idx in eachindex(uv)]
end

struct ContinuousScale{T, F}
    f::F
    extrema::Tuple{T, T}
end

rescale(values::AbstractArray{<:Number}, c::ContinuousScale) = values # Is this ideal?
function rescale(values::AbstractArray{<:Union{Date, DateTime}}, c::ContinuousScale)
    @assert c.f === identity
    min, max = c.extrema
    return @. convert(Millisecond, DateTime(values) - DateTime(min)) / Millisecond(1)
end

struct CategoricalScale{S, T}
    data::S
    plot::T
end

function rescale(values, c::CategoricalScale)
    idxs = indexin(values, c.data)
    return c.plot[idxs]
end

Base.length(c::CategoricalScale) = length(c.data)

function default_scale(summary, palette)
    iscont = summary isa Tuple
    return if iscont
        f = palette isa Function ? palette : identity
        ContinuousScale(f, summary)
    else
        plot = apply_palette(palette, summary)
        return CategoricalScale(summary, plot)
    end
end

# Logic to infer good scales
function default_scales(summaries, palettes)
    defaults = Dict{KeyType, Any}()
    for (key, val) in pairs(summaries)
        # ensure `palette === automatic` for integer keys
        palette = key in propertynames(palettes) ? palettes[key] : automatic
        defaults[key] = default_scale(val, palette)
    end
    return defaults
end

# Logic to create ticks from a scale
# Should take current tick to incorporate information
function ticks(scale::CategoricalScale)
    u = map(string, scale.data)
    return (axes(u, 1), u)
end

function ticks(scale::ContinuousScale)
    return continuousticks(scale.extrema...)
end

continuousticks(min, max) = automatic

function continuousticks(min::T, max::T) where T<:Union{Date, DateTime}
    min_ms::Millisecond, max_ms::Millisecond = DateTime(min), DateTime(max)
    min_pure, max_pure = min_ms/Millisecond(1), max_ms/Millisecond(1)
    dates, labels = optimize_datetime_ticks(min_pure, max_pure)
    return (dates .-  min_pure, labels)
end
