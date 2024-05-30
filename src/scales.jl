## Aesthetics

abstract type Aesthetic end

struct AesX <: Aesthetic end
struct AesY <: Aesthetic end
struct AesZ <: Aesthetic end
struct AesLayout <: Aesthetic end
struct AesRow <: Aesthetic end
struct AesCol <: Aesthetic end
struct AesGroup <: Aesthetic end
struct AesColor <: Aesthetic end
struct AesMarker <: Aesthetic end

# helper to dissociate scales belonging to the same Aesthetic type
struct ScaleID
    id::Symbol
end

## Categorical Scales

mutable struct Cycler{K, V}
    keys::Vector{K}
    values::Vector{V}
    defaults::Vector{Any}
    idx::Int
end

function Cycler(p)
    defaults = vec(collect(Any, p))
    pairs = splice!(defaults, findall(val -> val isa Pair, defaults))
    return Cycler(map(first, pairs), map(last, pairs), defaults, 0)
end

function (c::Cycler)(u)
    i = findfirst(isequal(u), c.keys)
    return if isnothing(i)
        l = length(c.defaults)
        l == 0 && throw(ArgumentError("Key $(repr(u)) not found and no default values are present"))
        c.defaults[mod1(c.idx += 1, l)]
    else
        c.values[i]
    end
end

# Use `Iterators.map` as `map` does not guarantee order
apply_palette(p::Union{AbstractArray, AbstractColorList}, uv) = collect(Iterators.map(Cycler(p), uv))
apply_palette(::Automatic, uv) = eachindex(uv)
apply_palette(p, uv) = map(p, uv)

# TODO: add more customizations?
struct Wrap end

const wrap = Wrap()

function apply_palette(::Wrap, uv)
    ncols = ceil(Int, sqrt(length(uv)))
    return [fldmod1(idx, ncols) for idx in eachindex(uv)]
end

struct CategoricalScale{S, T, U}
    data::S
    plot::T
    palette::U
    label::Union{AbstractString, Nothing}
end

function CategoricalScale(data, palette, label::Union{AbstractString, Nothing})
    return CategoricalScale(data, nothing, palette, label)
end

# Final processing step of a categorical scale
function fitscale(c::CategoricalScale)
    data = c.data
    palette = c.palette
    plot = apply_palette(c.palette, c.data)
    return CategoricalScale(data, plot, palette, c.label)
end

datavalues(c::CategoricalScale) = c.data
plotvalues(c::CategoricalScale) = c.plot
getlabel(c::CategoricalScale) = something(c.label, "")

## Continuous Scales

struct ContinuousScale{T}
    extrema::NTuple{2, T}
    label::Union{AbstractString, Nothing}
    force::Bool
end

ContinuousScale(extrema, label; force=false) = ContinuousScale(extrema, label, force)

getlabel(c::ContinuousScale) = something(c.label, "")

# recentering hack to avoid Float32 conversion errors on recent dates
# TODO: remove once Makie supports dates
datetime2float(x::Union{DateTime, Date}) = datetime2float(DateTime(x) - DateTime(2020, 01, 01))
datetime2float(x::Time) = datetime2float(x - Time(0))
datetime2float(x::Period) = Millisecond(x) / Millisecond(1)

"""
    datetimeticks(datetimes::AbstractVector{<:TimeType}, labels::AbstractVector{<:AbstractString})

Generate ticks matching `datetimes` to the corresponding `labels`.
The result can be passed to `xticks`, `yticks`, or `zticks`.
"""
function datetimeticks(datetimes::AbstractVector{<:TimeType}, labels::AbstractVector{<:AbstractString}) 
    return map(datetime2float, datetimes), labels
end

"""
    datetimeticks(f, datetimes::AbstractVector{<:TimeType})

Compute ticks for the given `datetimes` using a formatting function `f`.
The result can be passed to `xticks`, `yticks`, or `zticks`.
"""
function datetimeticks(f, datetimes::AbstractVector{<:TimeType})
    return datetimeticks(datetimes, map(string∘f, datetimes))
end

# Rescaling methods that do not depend on context
elementwise_rescale(value::Union{TimeType, Period}) = datetime2float(value) 
elementwise_rescale(value::Verbatim) = value[]
elementwise_rescale(value) = value

contextfree_rescale(values) = map(elementwise_rescale, values)

rescale(values, ::Nothing) = values

function rescale(values, c::CategoricalScale)
    # Do not rescale continuous data with categorical scale
    scientific_eltype(values) === categorical || return values
    idxs = indexin(values, datavalues(c))
    return plotvalues(c)[idxs]
end

Base.length(c::CategoricalScale) = length(datavalues(c))

function mergelabels(label1, label2)
    return if isnothing(label1)
        nothing
    elseif isequal(label1, label2)
        label1
    elseif isempty(label1)
        label2
    elseif isempty(label2)
        label1
    else
        nothing # no reasonable label found
    end
end

function mergescales(c1::CategoricalScale, c2::CategoricalScale)
    data = mergesorted(c1.data, c2.data)
    palette = assert_equal(c1.palette, c2.palette)
    label = mergelabels(c1.label, c2.label)
    return CategoricalScale(data, palette, label)
end

function mergescales(c1::ContinuousScale, c2::ContinuousScale)
    c1.force && c2.force && assert_equal(c1.extrema, c2.extrema)
    i = findfirst((c1.force, c2.force))
    force = !isnothing(i)
    extrema = force ? (c1.extrema, c2.extrema)[i] : extend_extrema(c1.extrema, c2.extrema)
    label = mergelabels(c1.label, c2.label)
    return ContinuousScale(extrema, label, force)
end

# Logic to create ticks from a scale
# Should take current tick to incorporate information
function ticks(scale::CategoricalScale)
    u = map(to_string, datavalues(scale))
    return (axes(u, 1), u)
end

ticks(scale::ContinuousScale) = ticks(scale.extrema)

ticks((min, max)::NTuple{2, Any}) = automatic

temporal_resolutions(::Type{Date}) = (Year, Month, Day)
temporal_resolutions(::Type{Time}) = (Hour, Minute, Second, Millisecond)
temporal_resolutions(::Type{DateTime}) = (temporal_resolutions(Date)..., temporal_resolutions(Time)...)

function optimal_datetime_range((x_min, x_max)::NTuple{2, T}; k_min=2, k_max=5) where {T<:TimeType}
    local P, start, stop
    for outer P in temporal_resolutions(T)
        start, stop = trunc(x_min, P), trunc(x_max, P)
        (start == x_min) || (start += P(1))
        n = length(start:P(1):stop)
        n ≥ k_min && return start:P(fld1(n, k_max)):stop
    end
    return start:P(1):stop
end

function format_datetimes(datetimes::AbstractVector{DateTime})
    dates, times = Date.(datetimes), Time.(datetimes)
    (dates == datetimes) && return string.(dates)
    isequal(extrema(dates)...) && return string.(times)
    return string.(datetimes)
end

format_datetimes(datetimes::AbstractVector) = string.(datetimes)

function ticks(limits::NTuple{2, TimeType})
    datetimes = optimal_datetime_range(limits)
    return datetime2float.(datetimes), format_datetimes(datetimes)
end

@enum ScientificType categorical continuous geometrical

"""
    scientific_type(T::Type)

Determine whether `T` represents a continuous, geometrical, or categorical variable.
"""
function scientific_type(::Type{T}) where T
    T <: Bool && return categorical
    T <: Union{Number, TimeType} && return continuous
    T <: Verbatim && return geometrical
    T <: Union{Makie.StaticVector, Point, AbstractGeometry} && return geometrical
    T <: AbstractArray && eltype(T) <: Union{Point, AbstractGeometry} && return geometrical
    isgeometry(T) && return geometrical
    return categorical
end

"""
    scientific_eltype(v)

Determine whether `v` should be treated as a continuous, geometrical, or categorical array.
"""
scientific_eltype(v::AbstractArray) = scientific_type(eltype(v))

# TODO: Needed for pregrouped data, but ideally should be removed.
scientific_eltype(::Any) = categorical

iscategoricalcontainer(u) = any(el -> scientific_eltype(el) === categorical, u)
iscontinuous(u) = scientific_eltype(u) === continuous

extend_extrema((l1, u1), (l2, u2)) = min(l1, l2), max(u1, u2)

function extrema_finite(v::AbstractArray)
    iter = Iterators.filter(isfinite, skipmissing(v))
    init = typemax(eltype(iter)), typemin(eltype(iter))
    return mapreduce(t -> (t, t), extend_extrema, iter; init)
end

nested_extrema_finite(iter) = mapreduce(extrema_finite, extend_extrema, iter)

push_different!(v, val) = !isempty(v) && isequal(last(v), val) || push!(v, val)

function mergesorted(v1, v2)
    issorted(v1) && issorted(v2) || throw(ArgumentError("Arguments must be sorted"))
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
