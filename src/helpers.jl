# helper types and functions for rescaling

to_string(s) = string(s)
to_string(s::AbstractString) = s

# A wrapper around `CartesianIndex` that also stores which dimensions were selected
# via the `dims()` selector. This allows proper label extraction later, as we can
# identify which dimension(s) each index component refers to.
struct DimsIndex{N, M}
    dims::NTuple{N, Int}  # which dimensions were selected (e.g., (1, 2) for dims(1, 2))
    index::CartesianIndex{M}  # the actual index values
end

Base.show(io::IO, d::DimsIndex) = print(io, "DimsIndex(dims=", d.dims, ", index=", d.index, ")")
Base.hash(d::DimsIndex, h::UInt) = hash(d.index, hash(d.dims, hash(:DimsIndex, h)))
Base.:(==)(d1::DimsIndex, d2::DimsIndex) = d1.dims == d2.dims && d1.index == d2.index
Base.isequal(d1::DimsIndex, d2::DimsIndex) = isequal(d1.dims, d2.dims) && isequal(d1.index, d2.index)
Base.isless(d1::DimsIndex, d2::DimsIndex) = isless((d1.dims, Tuple(d1.index)), (d2.dims, Tuple(d2.index)))

struct Sorted{T}
    idx::UInt32
    value::T
end
Sorted(idx::Integer, value) = Sorted(convert(UInt32, idx), value)

Base.hash(s::Sorted, h::UInt) = hash(s.value, hash(s.idx, hash(:Sorted, h)))
Base.:(==)(s1::Sorted, s2::Sorted) = isequal(s1.idx, s2.idx) && isequal(s1.value, s2.value)

Base.print(io::IO, s::Sorted) = print(io, s.value)
Base.isless(s1::Sorted, s2::Sorted) = isless((s1.idx, s1.value), (s2.idx, s2.value))

struct Renamer{U, L}
    uniquevalues::U
    labels::L
end

# for `dims(2)` and up, we get indices like `CartesianIndex(1, 4)` etc, which
# by construction are always only non-1 in one dimension, but we can't know that
# just from a single `CartesianIndex`. As long as we only drop all the ones, and error
# if there are two non-ones, this should be fine.
function linearize_cartesian_index(i::CartesianIndex)
    t = Tuple(i)
    linearized = reduce(t; init = 1) do a, b
        a == 1 ? b : b == 1 ? a : error("Can't linearize $(i) because it has two indices that are not one")
    end
    return linearized
end

linearize_cartesian_index(d::DimsIndex) = linearize_cartesian_index(d.index)

linearize_cartesian_index(x) = x

function (r::Renamer{Nothing})(x)
    lx = linearize_cartesian_index(x)
    i = LinearIndices(r.labels)[lx]
    return Sorted(i, r.labels[i])
end

function (r::Renamer)(x)
    for i in keys(r.uniquevalues)
        cand = @inbounds r.uniquevalues[i]
        if isequal(cand, x)
            label = r.labels[i]
            return Sorted(i, label)
        end
    end
    throw(KeyError(x))
end

renamer(args::Pair...) = renamer(args)

"""
    renamer(arr::Union{AbstractArray, Tuple})

Utility to rename a categorical variable, as in `renamer([value1 => label1, value2 => label2])`.
The keys of all pairs should be all the unique values of the categorical variable and
the values should be the corresponding labels. The order of `arr` is respected in
the legend.

# Examples
```jldoctest
julia> r = renamer(["class 1" => "Class One", "class 2" => "Class Two"])
AlgebraOfGraphics.Renamer{Vector{String}, Vector{String}}(["class 1", "class 2"], ["Class One", "Class Two"])

julia> println(r("class 1"))
Class One
```
Alternatively, a sequence of pair arguments may be passed.
```jldoctest
julia> r = renamer("class 1" => "Class One", "class 2" => "Class Two")
AlgebraOfGraphics.Renamer{Tuple{String, String}, Tuple{String, String}}(("class 1", "class 2"), ("Class One", "Class Two"))

julia> println(r("class 1"))
Class One
```

If `arr` does not contain `Pair`s, elements of `arr` are assumed to be labels, and the
unique values of the categorical variable are taken to be the indices of the array.
This is particularly useful for `dims` mappings.

# Examples
```jldoctest
julia> r = renamer(["Class One", "Class Two"])
AlgebraOfGraphics.Renamer{Nothing, Vector{String}}(nothing, ["Class One", "Class Two"])

julia> println(r(2))
Class Two
```
"""
function renamer(arr::Union{AbstractArray, Tuple})
    ispairs = all(x -> isa(x, Pair), arr)
    k, v = ispairs ? (map(first, arr), map(last, arr)) : (nothing, arr)
    return Renamer(k, v)
end

function sorter(ks...)
    vs = map(to_string, ks)
    return Renamer(ks, vs)
end

"""
    sorter(ks)

Utility to reorder a categorical variable, as in `sorter(["low", "medium", "high"])`.
A vararg method `sorter("low", "medium", "high")` is also supported.
`ks` should include all the unique values of the categorical variable.
The order of `ks` is respected in the legend.
"""
function sorter(ks::Union{AbstractArray, Tuple})
    vs = map(to_string, ks)
    return Renamer(ks, vs)
end

struct NonNumeric{T}
    x::T
end

"""
    nonnumeric(x)

Transform `x` into a non numeric type that is printed and sorted in the same way.
"""
nonnumeric(x) = NonNumeric(x)

Base.print(io::IO, n::NonNumeric) = print(io, n.x)
Base.isless(n1::NonNumeric, n2::NonNumeric) = isless(n1.x, n2.x)

struct Verbatim{T}
    x::T
end

"""
    verbatim(x)

Signal that `x` should not be rescaled, but used in the plot as is.
"""
verbatim(x) = Verbatim(x)

Base.getindex(v::Verbatim) = v.x
Base.print(io::IO, v::Verbatim) = print(io, v.x)


@static if VERSION < v"1.7"
    macro something(args...)
        expr = :(nothing)
        for arg in reverse(args)
            expr = :(val = $(esc(arg)); val !== nothing ? val : ($expr))
        end
        something = GlobalRef(Base, :something)
        return :($something($expr))
    end
end

struct Bin
    range::Tuple{Float64, Float64}
    inclusive::Tuple{Bool, Bool}
end

Base.isless(b1::Bin, b2::Bin) = isless(b1.range, b2.range)

function Base.show(io::IO, b::Bin)
    return print(io, b.inclusive[1] ? "[" : "(", b.range[1], ", ", b.range[2], b.inclusive[2] ? "]" : ")")
end

struct Pregrouped end

"""
    pregrouped(positional...; named...)

Equivalent to `data(Pregrouped()) * mapping(positional...; named...)`.
Refer to [`mapping`](@ref) for more information.
"""
pregrouped(args...; kwargs...) = data(Pregrouped()) * mapping(args...; kwargs...)

struct Columns{T}
    columns::T
end

struct DirectData{T}
    data::T
end

"""
    direct(x)

Return `DirectData(x)` which marks `x` for direct use in a `mapping` that's
used with a table-like `data` source. As a result, `x` will be used directly as
data, without lookup in the table. If `x` is not an `AbstractArray`, it will
be expanded like `fill(x, n)` where `n` is the number of rows in the `data` source.
"""
direct(x) = DirectData(x)

struct Presorted{T}
    x::T
    i::UInt16
end
Presorted(x) = Presorted(x, 0x0000)

"""
    presorted(x)

Use within a pair expression in `mapping` to signal that
a categorical column from the data source should be
used in the original order and not automatically sorted.

Example:

```julia
# normally, categories would be sorted a, b, c but with `presorted`
# they stay in the order b, c, a

data((; some_column = ["b", "c", "a"])) * mapping(:some_column => presorted)
```
"""
presorted(x) = Presorted(x)

Base.show(io::IO, p::Presorted) = print(io, p.x)

# this is a bit weird, but two Presorteds wrapping different values should be sorted by the index they store,
# so that the original order of the dataset remains intact,
# but two Presorteds with the same value should be considered equal no matter which indices they have,
# so that the same value appearing in different positions in two datasets is considered the same when plotting
Base.isless(p::Presorted, p2::Presorted) = isless(p.i, p2.i)
Base.isequal(p::Presorted, p2::Presorted) = isequal(p.x, p2.x)
Base.:(==)(p::Presorted, p2::Presorted) = p.x == p2.x
Base.hash(p::Presorted) = hash(p.x)

struct FromContinuous{T}
    continuous::T
    relative::Bool
end

"""
    from_continuous(x; relative = true)

Mark a colormap as continuous such that AlgebraOfGraphics will sample
a categorical palette from start to end in n steps, and not by using the first
n colors.

You could also use `cgrad(colormap, n; categorical = true)`, however,
this requires you to specify how many levels there are, which
`from_continuous` detects automatically.

The `relative` option applies only when the datavalues of the palette are of type `Bin`.
In this case, if `relative = true`, the continuous colormap is sampled at the relative
midpoints of the bins, which means that neighboring bins that are smaller have more similar
colors because their midpoints are closer together. If `relative = false`, the colormap
is sampled evenly.

Example:

```julia
draw(scales(Color = (; palette = from_continuous(:viridis))))
```
"""
from_continuous(x; relative = true) = FromContinuous(x, relative)
