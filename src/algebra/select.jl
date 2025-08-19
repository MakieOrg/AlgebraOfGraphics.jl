struct DimsSelector{N}
    dims::NTuple{N, Int}
end

"""
    dims(args...)

Create a `DimsSelector` object which can be used in `mapping` to refer
to the dimensions of the layer's shape.

Example:

```julia
mapping([:x1, :x2, :x3], col = dims(1))
```

In the normal case where only
single columns are referenced in `mapping`, the shape of the layer is `(1,)`.
If, for example, the first `mapping` entry, let's say for the X scale,
is a column vector with three column selectors, like `[:x1, :x2, :x3]`,
the shape becomes `(3,)`. If there's additionally a second `mapping` entry for
the Y scale with four column selectors in a row vector, like `[:y1 :y2 :y3 :y4]`,
which by itself has shape `(1, 4)`, the overall
shape becomes `(3, 4)`. This means that 3 x 4 = 12 combinations of columns will
be plotted together as X and Y in the same axis.

The `dims` selector can now be used to create what can be thought of as a categorical
scale with as many entries as the product of the sizes of the selected dimensions.
For example, if we have our shape `(3, 4)` and add `color = dims(1)`, the data will
be colored in three different shades, one for each column selector in the first dimension
(the three columns passed to the X scale). If we set `color = dims(1, 2)`, there will
be 12 different shades, one for each combination of X and Y. If we set `color = dims(2)`,
there will be four different shades, one for each Y column.

With wide input data, it often makes sense to put each column into its own facet, in
order not to overcrowd the visual space. Therefore, a common setting in the `mapping`
in such scenarios could be `row = dims(1), col = dims(2)`, for example.
"""
dims(args...) = DimsSelector(args)

function (d::DimsSelector)(c::CartesianIndex{N}) where {N}
    t = ntuple(N) do n
        return n in d.dims ? c[n] : 1
    end
    return CartesianIndex(t)
end

select(data, d::DimsSelector) = (d,) => identity => "" => nothing

function select(data::Columns, name::Union{Symbol, AbstractString})
    v = getcolumn(data.columns, Symbol(name))
    supports_colmetadata = DataAPI.colmetadatasupport(typeof(data.columns)).read
    label = if supports_colmetadata && "label" in DataAPI.colmetadatakeys(data.columns, name)
        to_string(DataAPI.colmetadata(data.columns, name, "label"))
    else
        to_string(name)
    end
    return (v,) => identity => label => nothing
end

function select(data::Columns, idx::Integer)
    name = columnnames(data.columns)[idx]
    return select(data, name)
end

function select(::Nothing, shape, selector)
    if selector isa Pair
        vs, rest = selector
        fn(x::Pair) = fn(x[1], x[2])
        fn(x::Function) = x, "", nothing
        fn(x::ScaleID) = identity, "", x
        fn(x) = identity, x, nothing
        fn(x::Function, y::Pair) = x, y[1], y[2]
        fn(x::Function, y::ScaleID) = x, "", y
        fn(x::Function, y) = x, y, nothing
        fn(x, y::ScaleID) = identity, x, y

        f, label, scaleid = fn(rest)
    else
        vs = selector
        f = identity
        label = ""
        scaleid = nothing
    end

    # Makie doesn't like getting zero-dimensional arrays, so if we have only scalars
    # we make one-element vectors instead
    non_zerodim_shape(s::Tuple{}) = (Base.OneTo(1),)
    non_zerodim_shape(s) = s

    if !(vs isa AbstractArray)
        vs = [vs for _ in CartesianIndices(non_zerodim_shape(shape))]
    end

    return (vs,), (f, (label, scaleid))
end

select(::Pregrouped, v::AbstractArray) = (v,) => identity => "" => nothing

function select(data, x::Pair{<:Any, <:Union{Symbol, AbstractString}})
    name, label = x
    vs, _ = select(data, name)
    return vs => identity => to_string(label) => nothing
end

function select(data::Columns, direct::DirectData{T}) where {T}
    arr = if T <: AbstractArray{X, 1} where {X}
        direct.data
    elseif T <: AbstractArray
        throw(ArgumentError("It's currently not allowed to use arrays that are not one-dimensional (column vectors) as direct data."))
    else
        nrows = length(rows(data.columns))
        fill(direct.data, nrows)
    end
    return (arr,) => identity => "" => nothing
end

# treat a tuple of columns as a column of tuples by default
select(data, x::Tuple{Vararg{Union{Symbol, String}}}) = select(data, x => tuple)

function select(data, x::Pair{<:Any, <:Any})
    name, transformation = x
    if name isa Tuple
        vs = map(name) do n
            only(first(select(data, n)))
        end
        label = ""
    else
        vs, (_, (label, _)) = select(data, name)
    end
    return vs => transformation => label => identity
end

function select(data, x::Pair{<:Any, <:Pair})
    name, transformation_label = x
    transformation, label = transformation_label
    names = name isa Tuple ? name : (name,)
    vs = map(n -> only(first(select(data, n))), names)
    return vs => transformation => label => nothing
end

function select(data, x::Pair{<:Any, <:Pair{<:Any, ScaleID}})
    (vs, (transf, (label, _))) = select(data, x[1] => x[2][1])
    return vs => transf => label => x[2][2]
end

function select(data, x::Pair{<:Any, <:Pair{<:Any, <:Pair{<:Any, ScaleID}}})
    (col, (f, (lbl, id))) = x
    (vs, (transf, (label, _))) = select(data, col => f => lbl)
    return vs => transf => label => id
end

function select(data, x::Pair{<:Any, ScaleID})
    (vs, (transf, (label, _))) = select(data, x[1])
    return vs => transf => label => x[2]
end
