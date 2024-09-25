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
struct AesDodgeX <: Aesthetic end
struct AesDodgeY <: Aesthetic end
struct AesStack <: Aesthetic end
struct AesLineStyle <: Aesthetic end
struct AesText <: Aesthetic end
# all these plot specific ones seem kind of unnecessary, but not sure what to do with them yet,
# maybe aesthetics that completely avoid scales 
struct AesViolinSide <: Aesthetic end
struct AesContourColor <: Aesthetic end # this is just so the third contour argument doesn't conflict with other things for now, it's complex to handle in its interplay with `color` and `levels`
struct AesPlaceholder <: Aesthetic end # choropleth for example takes as first arg only geometries which avoid scales, but for now we still have to give an aes to 1, so this can serve for that purpose
struct AesABIntercept <: Aesthetic end
struct AesABSlope <: Aesthetic end

# helper to dissociate scales belonging to the same Aesthetic type
struct ScaleID
    id::Symbol
end

"""
    scale(id::Symbol)

Create a `ScaleID` object that can be used in a [`mapping`](@ref) to assign a custom id
to the mapped variable. This variable will then not be merged into the default scale
for its aesthetic type, but instead be handled separately, leading to a separate legend entry.
"""
scale(id::Symbol) = ScaleID(id)

Base.broadcastable(s::ScaleID) = Ref(s)

struct Scales
    dict::Dictionary{Symbol,Dictionary{Symbol,Any}}
end

"""
    scales(; kwargs...)

Create a `Scales` object containing properties for aesthetic scales that can be passed to [`draw`](@ref) and [`draw!`](@ref).
Each keyword should be the name of a scale in the spec that is being drawn.
That can either be a default one like `Color`, `Marker` or `LineStyle`, or a custom scale name
defined in a [`mapping`](@ref) using the `scale` function.

The values attached to the keywords must be dict-like, with `Symbol`s as keys (such as `NamedTuple`s).
"""
function scales(; kwargs...)
    dict = Dictionary{Symbol,Dictionary{Symbol,Any}}()
    for (kw, value) in pairs(kwargs)
        insert!(dict, kw, _kwdict(value))
    end
    return Scales(dict)
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
apply_palette(f::Function, uv) = f(uv)
apply_palette(fc::FromContinuous, uv) = cgrad(fc.continuous, length(uv); categorical = true)

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
    categories::Union{Nothing,Function,Vector}
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
        is_kw_error = @static if isdefined(Core, :kwcall)
            e isa MethodError && e.f === Core.kwcall
        else
            e isa MethodError && endswith(string(e.f), "#kw")
        end
        if is_kw_error
            invalid_keys = setdiff(keys(e.args[1]), fieldnames(T))
        else
            rethrow(e)
        end
    end
    sym(::Val{<:S}) where S = S
    throw(ArgumentError("Unknown scale$(length(invalid_keys) == 1 ? "" : "s") attribute $(join((repr(key) for key in invalid_keys), ", ", " and ")) for $(sym(kind)) scale with aesthetic $type. $(isempty(fieldnames(T)) ? "$T does not accept any attributes." : "Available attributes for $T are $(join((repr(key) for key in fieldnames(T)), ", ", " and ")).")"))
end

struct CategoricalScale{S, T}
    data::S
    plot::T
    label::Union{AbstractString, Nothing}
    props::CategoricalScaleProps
    aes::Type{<:Aesthetic}
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

# delete! on a `copy`ed dict modifies original
_dictcopy(dict::T) where {T<:Dictionary} = T(copy(keys(dict)), copy(values(dict)))

function CategoricalScaleProps(aestype::Type{<:Aesthetic}, props::Dictionary)
    props_copy = _dictcopy(props)
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

Base.@kwdef struct AesDodgeXCategoricalProps <: CategoricalAesProps
    width::Union{Nothing,Float64} = nothing
end
Base.@kwdef struct AesDodgeYCategoricalProps <: CategoricalAesProps
    width::Union{Nothing,Float64} = nothing
end

categorical_aes_props_type(::Type{AesDodgeX}) = AesDodgeXCategoricalProps
categorical_aes_props_type(::Type{AesDodgeY}) = AesDodgeYCategoricalProps


function CategoricalScale(aestype::Type{<:Aesthetic}, data, label::Union{AbstractString, Nothing}, props)
    props_typed = CategoricalScaleProps(aestype, props)
    return CategoricalScale(data, nothing, label, props_typed, aestype)
end

category_value(v) = v
category_value(p::Pair) = p[1]
category_label(v) = string(v)
category_label(p::Pair) = p[2]

# Final processing step of a categorical scale
function fitscale(c::CategoricalScale)
    possibly_transformed_data = datavalues(c)
    # this is a bit weird maybe, but we look up the palette for the possibly transformed
    # data and store the normal data again, probably storing the palette is actually not
    # necessary but that can be a later refactor
    palette = get_categorical_palette(c.aes, c.props.palette)
    plot = apply_palette(palette, possibly_transformed_data)
    return CategoricalScale(c.data, plot, c.label, c.props, c.aes)
end

function datavalues(c::CategoricalScale)
    if c.props.categories === nothing
        c.data
    else
        if c.props.categories isa Function
            catvalues = map(category_value, c.props.categories(c.data))
        else
            catvalues = map(category_value, c.props.categories)
        end
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
    end
end
plotvalues(c::CategoricalScale) = c.plot

to_datalabel(x::AbstractString) = x
to_datalabel(x::Makie.RichText) = x
to_datalabel(x) = string(x)
to_datalabel(s::Sorted) = to_datalabel(s.value)

function datalabels(c::CategoricalScale)
    if c.props.categories === nothing
        to_datalabel.(datavalues(c))
    elseif c.props.categories isa Function
        map(category_label, c.props.categories(c.data))
    else
        map(category_label, c.props.categories)
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
    props_copy = _dictcopy(props)
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
    for (i, idx) in zip(eachindex(values), idxs)
        if idx === nothing
            error("Value $(values[i]) was not found in categorical scale with datavalues $(datavalues(c))")
        end
    end
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
    # "possibly" because presorted data should where c2 contains something c1 doesn't should just be appended, there's no meaningful
    # sort order between two disjoint sets of data which are supposed to be kept in their intrinsic order
    data = possibly_mergesorted(c1.data, c2.data)
    plot = assert_equal(c1.plot, c2.plot)
    label = mergelabels(c1.label, c2.label)
    if c1.props != c2.props
        error("Expected props of merging categorical scales to match, got $(c1.props) and $(c2.props)")
    end
    if c1.aes != c2.aes
        error("Expected aes types of merging categorical scales to match, got $(c1.aes) and $(c2.aes)")
    end
    return CategoricalScale(data, plot, label, c1.props, c1.aes)
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

abstract type ScientificType end
struct Categorical <: ScientificType end
struct Continuous <: ScientificType end
struct Geometrical <: ScientificType end
const categorical = Categorical()
const continuous = Continuous()
const geometrical = Geometrical()
const Normal = Union{Categorical,Continuous}

"""
    scientific_type(T::Type)

Determine whether `T` represents a continuous, geometrical, or categorical variable.
"""
function scientific_type(::Type{T}) where T
    T === Missing && return categorical
    NT = nonmissingtype(T)
    NT <: Bool && return categorical
    NT <: Union{Number, TimeType} && return continuous
    NT <: Verbatim && return geometrical
    NT <: Union{Makie.StaticVector, Point, AbstractGeometry} && return geometrical
    NT <: AbstractArray && eltype(NT) <: Union{Point, AbstractGeometry} && return geometrical
    isgeometry(NT) && return geometrical
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

natural_lt(x, y) = isless(x, y)
natural_lt(x::AbstractString, y::AbstractString) = NaturalSort.natural(x, y)

# the below `natural_lt`s are copying Julia's `isless` implementation
natural_lt(::Tuple{}, ::Tuple{}) = false
natural_lt(::Tuple{}, ::Tuple) = true
natural_lt(::Tuple, ::Tuple{}) = false

"""
    natural_lt(t1::Tuple, t2::Tuple)

Return `true` when `t1` is less than `t2` in lexicographic order.
"""
function natural_lt(t1::Tuple, t2::Tuple)
    a, b = t1[1], t2[1]
    natural_lt(a, b) || (isequal(a, b) && natural_lt(tail(t1), tail(t2)))
end

function mergesorted(v1, v2)
    issorted(v1; lt = natural_lt) && issorted(v2; lt = natural_lt) || throw(ArgumentError("Arguments must be sorted"))
    T = promote_type(eltype(v1), eltype(v2))
    v = sizehint!(T[], length(v1) + length(v2))
    i1, i2 = 1, 1
    while i2 ≤ length(v2)
        while i1 ≤ length(v1) && natural_lt(v1[i1], v2[i2])
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

possibly_mergesorted(v1, v2) = mergesorted(v1, v2)

function possibly_mergesorted(v1::AbstractVector{<:Presorted{T}}, v2::AbstractVector{<:Presorted}) where T
    set = Set{T}()
    for el in v1
        push!(set, el.x)
    end
    v = copy(v1)
    for el in v2
        el.x in set || push!(v, el)
    end
    return v
end