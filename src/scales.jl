## Aesthetics

abstract type Aesthetic end

struct AesX <: Aesthetic end
struct AesY <: Aesthetic end
struct AesZ <: Aesthetic end
struct AesDeltaX <: Aesthetic end
struct AesDeltaY <: Aesthetic end
struct AesDeltaZ <: Aesthetic end
struct AesLayout <: Aesthetic end
struct AesRow <: Aesthetic end
struct AesCol <: Aesthetic end
struct AesGroup <: Aesthetic end
struct AesColor <: Aesthetic end
struct AesMarker <: Aesthetic end
struct AesMarkerSize <: Aesthetic end
struct AesDodge <: Aesthetic end
struct AesStack <: Aesthetic end
struct AesLineStyle <: Aesthetic end

# helper to dissociate scales belonging to the same Aesthetic type
struct ScaleID
    id::Symbol
end
scale(id::Symbol) = ScaleID(id)
Base.broadcastable(s::ScaleID) = Ref(s)

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

abstract type CategoricalAesProps end
struct CategoricalScaleProps
    aesprops::CategoricalAesProps
    label # nothing or any type workable as a label
    legend::Bool
    categories::Union{Nothing,Vector}
    palette # nothing or any type workable as a palette
end

struct EmptyCategoricalProps <: CategoricalAesProps end

categorical_aes_props_type(::Type{<:Aesthetic}) = EmptyCategoricalProps

categorical_aes_props(type::Type{<:Aesthetic}, props_dict::Dictionary{Symbol,Any}) = aes_props(Val(:categorical), type, props_dict)

function aes_props(kind::Val, type::Type{<:Aesthetic}, props_dict::Dictionary{Symbol,Any})
    f_T(::Val{:categorical}) = categorical_aes_props_type
    f_T(::Val{:continuous}) = continuous_aes_props_type
    T = f_T(kind)(type)
    local invalid_keys
    try
        return T(; pairs(props_dict)...)
    catch e
        if e isa MethodError && e.f === Core.kwcall
            invalid_keys = setdiff(keys(e.args[1]), fieldnames(T))
        else
            rethrow(e)
        end
    end
    sym(::Val{<:S}) where S = S
    throw(ArgumentError("Unknown scale$(length(invalid_keys) == 1 ? "" : "s") attribute $(join((repr(key) for key in invalid_keys), ", ", " and ")) for $(sym(kind)) scale with aesthetic $type. $(isempty(fieldnames(T)) ? "$T does not accept any attributes." : "Available attributes for $T are $(join((repr(key) for key in fieldnames(T)), ", ", " and ")).")"))
end

struct CategoricalScale{S, T, U}
    data::S
    plot::T
    palette::U
    label::Union{AbstractString, Nothing}
    props::CategoricalScaleProps
end

function _pop!(d::Dictionary, key, default)
    if haskey(d, key)
        val = d[key]
        delete!(d, key)
        val
    else
        default
    end
end

function CategoricalScaleProps(aestype::Type{<:Aesthetic}, props::Dictionary)
    props_copy = copy(props)
    legend = _pop!(props_copy, :legend, true)
    label = _pop!(props_copy, :label, nothing)
    categories = _pop!(props_copy, :categories, nothing)
    palette = _pop!(props_copy, :palette, nothing)
    aes_props = categorical_aes_props(aestype, props_copy)
    CategoricalScaleProps(
        aes_props,
        label,
        legend,
        categories,
        palette,
    )
end

function CategoricalScale(aestype::Type{<:Aesthetic}, data, palette, label::Union{AbstractString, Nothing}, props)
    props_typed = CategoricalScaleProps(aestype, props)
    return CategoricalScale(data, nothing, palette, label, props_typed)
end

category_value(v) = v
category_value(p::Pair) = p[1]
category_label(v) = string(v)
category_label(p::Pair) = p[2]

# Final processing step of a categorical scale
function fitscale(c::CategoricalScale)
    data = if c.props.categories !== nothing
        catvalues = map(category_value, c.props.categories)
        u = try
            union(catvalues, c.data)
        catch e
            throw(ArgumentError("Custom categories were given but unioning them with the categories determined from the data failed."))
        end
        if u != catvalues
            extraneous = setdiff(c.data, catvalues)
            throw(ArgumentError("Custom categories were given but there were more categories in the data, which is not allowed. The additional categories were $extraneous"))
        end
        u
    else
        c.data
    end
    palette = c.palette
    plot = apply_palette(c.palette, data)
    return CategoricalScale(data, plot, palette, c.label, c.props)
end

datavalues(c::CategoricalScale) = c.data
plotvalues(c::CategoricalScale) = c.plot
function datalabels(c::CategoricalScale)
    if c.props.categories !== nothing
        map(category_label, c.props.categories)
    else
        string.(datavalues(c))
    end
end

## Continuous Scales

abstract type ContinuousAesProps end
struct ContinuousScaleProps
    aesprops::ContinuousAesProps
    label # nothing or any type workable as a label
    legend::Bool
end

function ContinuousScaleProps(aestype::Type{<:Aesthetic}, props::Dictionary)
    props_copy = copy(props)
    legend = _pop!(props_copy, :legend, true)
    label = _pop!(props_copy, :label, nothing)
    aes_props = continuous_aes_props(aestype, props_copy)
    ContinuousScaleProps(
        aes_props,
        label,
        legend,
    )
end

struct EmptyContinuousProps <: ContinuousAesProps end
Base.@kwdef struct AesColorContinuousProps <: ContinuousAesProps
    colormap = nothing
    colorrange = nothing
    lowclip = nothing
    highclip = nothing
    nan_color = nothing
end

Base.@kwdef struct AesMarkerSizeContinuousProps <: ContinuousAesProps
    sizerange::Tuple{Float64,Float64} = (5.0, 20.0)
end

continuous_aes_props_type(::Type{<:Aesthetic}) = EmptyContinuousProps
continuous_aes_props_type(::Type{AesColor}) = AesColorContinuousProps
continuous_aes_props_type(::Type{AesMarkerSize}) = AesMarkerSizeContinuousProps

continuous_aes_props(type::Type{<:Aesthetic}, props_dict::Dictionary{Symbol,Any}) = aes_props(Val(:continuous), type, props_dict)

struct ContinuousScale{T}
    extrema::NTuple{2, T}
    label::Union{AbstractString, Nothing}
    force::Bool
    props::ContinuousScaleProps
end

ContinuousScale(extrema, label, props; force=false) = ContinuousScale(extrema, label, force, props)

function ContinuousScale(aestype::Type{<:Aesthetic}, extrema, label, props; force=false)
    props_typed = ContinuousScaleProps(aestype, props)
    return ContinuousScale(extrema, label, force, props_typed)
end

getlabel(c::Union{ContinuousScale,CategoricalScale}) = c.props.label === nothing ? something(c.label, "") : c.props.label

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
    plot = assert_equal(c1.plot, c2.plot)
    label = mergelabels(c1.label, c2.label)
    if c1.props != c2.props
        error("Expected props of merging categorical scales to match, got $(c1.props) and $(c2.props)")
    end
    return CategoricalScale(data, plot, palette, label, c1.props)
end

function mergescales(c1::ContinuousScale, c2::ContinuousScale)
    c1.force && c2.force && assert_equal(c1.extrema, c2.extrema)
    i = findfirst((c1.force, c2.force))
    force = !isnothing(i)
    extrema = force ? (c1.extrema, c2.extrema)[i] : extend_extrema(c1.extrema, c2.extrema)
    label = mergelabels(c1.label, c2.label)
    if c1.props != c2.props
        error("Expected props of merging continuous scales to match, got $(c1.props) and $(c2.props)")
    end
    return ContinuousScale(extrema, label, force, c1.props)
end

# Logic to create ticks from a scale
# Should take current tick to incorporate information
function ticks(scale::CategoricalScale)
    labels = datalabels(scale)
    plotvals = plotvalues(scale)
    positions = if plotvals isa AbstractVector{<:Real}
        plotvals
    else
        axes(labels, 1)
    end
    return (positions, labels)
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
