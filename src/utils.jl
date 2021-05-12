## Layout helpers

isaxis2d(::Axis) = true
isaxis2d(::Any) = false
isaxis2d(ae::AxisEntries) = isaxis2d(Axis(ae))

for sym in [:hidexdecorations!, :hideydecorations!, :hidedecorations!]
    @eval function $sym(ae::AxisEntries; kwargs...)
        axis = Axis(ae)
        isaxis2d(axis) && $sym(axis; kwargs...)
    end
end

for sym in [:linkxaxes!, :linkyaxes!, :linkaxes!]
    @eval function $sym(ae::AxisEntries, aes::AxisEntries...)
        axs = filter(isaxis2d, map(Axis, (ae, aes...)))
        isempty(axs) || $sym(axs...)
    end
end

function hideinnerdecorations!(aes::Matrix{AxisEntries})
    options = (label=true, ticks=true, minorticks=true, grid=false, minorgrid=false)
    foreach(ae -> hidexdecorations!(ae; options...), aes[1:end-1, :])
    foreach(ae -> hideydecorations!(ae; options...), aes[:, 2:end])
end

function deleteemptyaxes!(aes::Matrix{AxisEntries})
    for ae in aes
        if isempty(ae.entries)
            delete!(Axis(ae))
        end
    end
end

function resizetocontent!(fig::Figure)
    figsize = size(fig.scene)
    sz = map((Col(), Row()), figsize) do dir, currentsize
        inferredsize = determinedirsize(fig.layout, dir)
        return ceil(Int, something(inferredsize, currentsize))
    end
    sz == figsize || resize!(fig.scene, sz)
    return fig
end

function resizetocontent!(fg::FigureGrid)
    resizetocontent!(fg.figure)
    return fg
end

## Scale helpers

const ArrayLike = Union{AbstractArray, Tuple}
const StringLike = Union{AbstractString, Symbol}

function cycle(v::AbstractVector, i::Int)
    ax = axes(v, 1)
    return v[first(ax) + mod(i - first(ax), length(ax))]
end

"""
    iscontinuous(v::AbstractArray)

Determine whether `v` should be treated as a continuous or categorical vector.
"""
iscontinuous(::AbstractArray) = false
iscontinuous(::AbstractArray{<:Number}) = true
iscontinuous(::AbstractArray{<:Union{Date, DateTime}}) = true

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

function assert_equal(a, b)
    @assert a == b
    return a
end

maybewrap(x::ArrayLike) = x
maybewrap(x) = fill(x)

unwrap(x) = x
unwrap(x::AbstractArray{<:Any, 0}) = x[]

function separate(f, nt::NamedTuple)
    filtered_keys = filter(key -> f(nt[key]), keys(nt))
    filtered_nt = NamedTuple{filtered_keys}(nt)
    return filtered_nt, Base.structdiff(nt, filtered_nt)
end
