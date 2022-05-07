# helper types and functions for rescaling

to_string(s) = string(s)
to_string(s::AbstractString) = s

struct Renamed{S, T}
    idx::UInt32
    original::S
    value::Union{T, Nothing}
end
Renamed(idx::Integer, original, value) = Renamed(convert(UInt32, idx), original, value)
value(x::Renamed) = isnothing(x.value) ? x.original : s.value

Base.hash(s::Renamed, h::UInt) = hash(value(s), hash(s.idx, hash(:Renamed, h)))
function Base.:(==)(s1::Renamed, s2::Renamed) 
    val_equal = isequal(s1.idx, s2.idx) && isequal(s1.value, s2.value) 
    if val_equal && isnothing(s1.value)
        return s1.original == s2.original
    else
        return val_equal
    end
end

Base.print(io::IO, s::Renamed) = print(io, value(s))
function Base.isless(s1::Renamed, s2::Renamed)
    if isnothing(s1.value) == isnothing(s1.value)
        return isless((s1.idx, value(s1)), (s2.idx, value(s2)))
    else
        # sort any renamed values before values that keep
        # their original value
        return isless(!isnothing(s1.value), !isnothing(s2.value))
    end
end

struct Renamer{U, L}
    uniquevalues::U
    labels::L
end

function (r::Renamer{Nothing})(x)
    i = LinearIndices(r.labels)[x]
    return Renamed(i, x, r.labels[i])
end

function (r::Renamer)(x)
    for i in keys(r.uniquevalues)
        cand = @inbounds r.uniquevalues[i]
        if isequal(cand, x)
            label = r.labels[i]
            return Renamed(i, x, label)
        end
    end
    throw(KeyError(x))
end

renamer(args::Pair...) = renamer(args)

"""
    renamer(arr::Union{AbstractArray, Tuple})

Utility to rename a categorical variable, as in `renamer([value1 => label1, value2 =>
label2])`. The order of `arr` is respected in the legend. The renamer need not specify all
values of the sequence it renames: if the renamer is missing one of the values from a
sequence it is applied to, the unspecified values are sorted after those that are specified (in the
order returned by `unique`) and are not renamed.

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
unique values of the categorical variable are taken to be the indices of the array. This is
particularly useful for `dims` mappings.

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

Utility to reorder a categorical variable, as in `sorter(["low", "medium", "high"])`. A
vararg method `sorter("low", "medium", "high")` is also supported. The order of `ks` is
respected in the legend. The sorter need not specify all values (e.g. `sorter(["low",
"medium"])` will work for an array that includes `"high"``); the unspecified values will be
sorted after the specified values and will occur in the order returned by `unique`.

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
