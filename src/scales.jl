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

rescale(values, ::Nothing) = values

default_scale(::Nothing, palette) = nothing

function default_scale(summary::Tuple, palette)
    f = palette isa Function ? palette : identity
    return ContinuousScale(f, summary)
end

function default_scale(summary::AbstractVector, palette)
    plot = apply_palette(palette, summary)
    return CategoricalScale(summary, plot)
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

## Scale helpers

const ArrayLike = Union{AbstractArray, Tuple}
const StringLike = Union{AbstractString, Symbol}

function cycle(v::AbstractVector, i::Int)
    ax = axes(v, 1)
    return v[first(ax) + mod(i - first(ax), length(ax))]
end

"""
    iscontinuous(v)

Determine whether `v` should be treated as a continuous or categorical vector.
"""
function iscontinuous(u)
    v = Broadcast.broadcastable(u)
    return !haszerodims(v) && eltype(v) <: Union{Number, Date, DateTime}
end

isgeometry(::AbstractArray{<:AbstractGeometry}) = true
isgeometry(::AbstractArray{T}) where {T} = eltype(T) <: AbstractGeometry

extend_extrema((l1, u1), (l2, u2)) = min(l1, l2), max(u1, u2)

push_different!(v, val) = !isempty(v) && isequal(last(v), val) || push!(v, val) 

function mergesorted(v1, v2)
    issorted(v1) && issorted(v2) || throw(ArgumentError("arguments must be sorted"))
    T = promote_type(eltype(v1), eltype(v2))
    v = sizehint!(T[], length(v1) + length(v2))
    i1, i2 = 1, 1
    while i2 ≤ length(v2)
        while i1 ≤ length(v1) && isless(v1[i1], v2[i2])
            push_different!(v, v1[i1])
            i1 += 1
        end
        push_different!(v, v2[i2])
        i2 += 1
    end
    while i1 ≤ length(v1)
        push_different!(v, v1[i1])
        i1 += 1
    end
    return v
end
