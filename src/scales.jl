increment!(idx::Ref) = (idx[] += 1; idx[])

function apply_palette(p::AbstractVector, uv)
    values = filter(x -> !isa(x, Pair), p)
    pairs = Dict(filter(x -> isa(x, Pair), p))
    idx = Ref(0)
    return [get(() -> cycle(values, increment!(idx)), pairs, v) for v in uv]
end

apply_palette(::Automatic, uv) = eachindex(uv)
apply_palette(p, uv) = map(p, eachindex(uv)) # FIXME: maybe apply to values instead?

# TODO: add more customizations?
struct Wrap end

const wrap = Wrap()

function apply_palette(::Wrap, uv)
    ncols = ceil(Int, sqrt(length(uv)))
    return [fldmod1(idx, ncols) for idx in eachindex(uv)]
end

struct CategoricalScale{S, T}
    data::S
    palette::T
    label::String
end

plotvalues(c::CategoricalScale) = apply_palette(c.palette, c.data)

rescale(values, ::Nothing) = values

# Do not rescale continuous data with categorical scale
rescale(values::AbstractArray{<:Number}, ::CategoricalScale) = values

function rescale(values, c::CategoricalScale)
    idxs = indexin(values, c.data)
    return plotvalues(c)[idxs]
end

Base.length(c::CategoricalScale) = length(c.data)

function mergelabels(label1, label2)
    return if isequal(label1, label2)
        label1
    elseif label1 == ""
        label2
    elseif label2 == ""
        label1
    else
        ""
    end
end

function compute_label(entries, key)
    label = ""
    for entry in entries
        col = get(entry, key, nothing)
        label = mergelabels(label, get(entry.labels, key, ""))
    end
    return label
end

function mergescales(c1::CategoricalScale, c2::CategoricalScale)
    data = mergesorted(c1.data, c2.data)
    palette = assert_equal(c1.palette, c2.palette)
    label = mergelabels(c1.label, c2.label)
    return CategoricalScale(data, palette, label)
end

# Logic to create ticks from a scale
# Should take current tick to incorporate information
function ticks(scale::CategoricalScale)
    u = map(string, scale.data)
    return (axes(u, 1), u)
end

ticks(::Any) = automatic

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

isgeometry(::AbstractArray{<:Point}) = true
isgeometry(::AbstractArray{<:AbstractGeometry}) = true
isgeometry(::AbstractArray{T}) where {T} = eltype(T) <: Union{Point, AbstractGeometry}

extend_extrema((l1, u1), (l2, u2)) = min(l1, l2), max(u1, u2)
extend_extrema(::Nothing, (l2, u2)) = (l2, u2)

function compute_extrema(entries, key)
    acc = nothing
    for entry in entries
        col = get(entry, key, nothing)
        if !isnothing(col)
            acc = mapreduce(Makie.extrema_nan, extend_extrema, col, init=acc)
        end
    end
    return acc
end

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
