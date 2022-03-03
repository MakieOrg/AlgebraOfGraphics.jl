# helper types and functions for rescaling

const StringLike = Union{AbstractString, Symbol}

to_string(s) = string(s)
to_string(s::AbstractString) = s

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

function (r::Renamer{Nothing})(x)
    i = LinearIndices(r.labels)[x]
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
