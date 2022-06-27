# Dispatcher type for `draw` usage.
struct PaginatedLayers
    each::Vector{Layers}
    layout::Union{Nothing, Int}
    row::Union{Nothing, Int}
    col::Union{Nothing, Int}
end

Base.length(p::PaginatedLayers) = length(p.each)

function Base.show(io::IO, p::PaginatedLayers)
    _info = filter(
        !isnothing ∘ last,
        [key => getfield(p, key) for key in (:layout, :row, :col)]
    )
    _info_str = isempty(_info) ? "no limits set" :
        join(("$key = $value" for (key, value) in _info), ", ")
    n = length(p)
    entry_str = n == 1 ? "1 entry" : "$n entries"
    print(io, "PaginatedLayers with $entry_str ($_info_str)")
end

"""
    draw(p::PaginatedLayers; kws...)

Draw each element of `PaginatedLayers` `p` and return a `Vector{FigureGrid}`.
Keywords `kws` are passed to the underlying `draw` calls.
"""
draw(p::PaginatedLayers; kws...) = draw.(p.each; kws...)

"""
    draw(p::PaginatedLayers, i::Int; kws...)

Draw the ith element of `PaginatedLayers` `p` and return a `FigureGrid`.
Keywords `kws` are passed to the underlying `draw` call.

You can retrieve the number of elements using `length(p)`.
"""
function draw(p::PaginatedLayers, i::Int; kws...)
    if i ∉ 1:length(p)
        throw(ArgumentError("Invalid index $i for PaginatedLayers with $(length(p)) entries."))
    end
    draw(p.each[i]; kws...)
end

function getsets(layer, data, column, by)
    func(column::Tuple) = sort!(unique(Iterators.product((getcolumn(data, c) for c in column)...)))
    func(column) = sort!(unique(getcolumn(data, column)))
    values = func(column)
    parts = Iterators.partition(values, by)
    return map(Set{eltype(values)}, parts)
end

function getsets(layer, data, dims::DimsSelector, by)
    positional = layer.positional
    return zip((d in dims.dims ? (withshape(p, each) for each in Iterators.partition(p, by)) : Iterators.cycle(p) for (d, p) in enumerate(positional))...)
end

colname((name, _)::Pair) = name
colname(name) = name

getcols(row, name) = getcolumn(row, name)
getcols(row, name::Tuple) = map(n -> getcolumn(row, n), name)

function paginate_layer(layer::Layer; layout = nothing, row = nothing, col = nothing)
    named = layer.named
    data = layer.data

    layoutspec = get(named, :layout, nothing)
    rowspec = get(named, :row, nothing)
    colspec = get(named, :col, nothing)

    valid(a, b) = !isnothing(a) && !isnothing(b)

    layers = if valid(layoutspec, layout)
        paginate_layer(layer, data, layoutspec, layout)
    elseif valid(rowspec, row) && valid(colspec, col)
        paginate_layer(layer, data, (rowspec, colspec), (row, col))
    elseif valid(rowspec, row)
        paginate_layer(layer, data, rowspec, row)
    elseif valid(col, col)
        paginate_layer(layer, data, col, col)
    else
        [layer]
    end
    return layers
end

function paginate_layer(layer::Layer, data, spec, limiter)
    name = colname(spec)
    sets = getsets(layer, data, name, limiter)

    function func(set::Set)
        table = TableOperations.filter(data) do row
            value = getcols(row, name)
            return value in set
        end
        return columntable(table), layer.positional
    end
    func(positional::Tuple) = (layer.data, positional)

    layers = map(sets) do set
        return Layer(layer.transformation, func(set)..., layer.named)
    end
    return layers
end

function paginate_layer(layer::Layer, data, (row, col)::Tuple, (rows, columns)::Tuple)
    row_name = colname(row)
    col_name = colname(col)
    row_sets = getsets(layer, data, row_name, rows)
    col_sets = getsets(layer, data, col_name, columns)
    layers = map(Iterators.product(row_sets, col_sets)) do (row_set, col_set)
        table = TableOperations.filter(data) do row
            row_value = getcols(row, row_name)
            col_value = getcols(row, col_name)
            return row_value in row_set && col_value in col_set
        end
        return Layer(
            layer.transformation,
            columntable(table),
            layer.positional,
            layer.named,
        )
    end
    return vec(layers)
end

"""
    paginate(l; layout = nothing, row = nothing, col = nothing)

Paginate `l`, the `Layer` or `Layers` object created by an `AlgebraOfGraphics` spec, to create a
`PaginatedLayers` object.
This contains a vector of layers where each layer operates on a subset of the input data.

The `PaginatedLayers` object can be passed to `draw` which will return a `Vector{FigureGrid}`
rather than a single figure.

The keywords that limit the number of subplots on each page are the same that are used
to specify facets in `mapping`:
  - `layout`: Maximum number of subplots in a wrapped linear layout.
  - `row`: Maximum number of rows in a 2D layout.
  - `col`: Maximum number of columns in a 2D layout.

## Example

```
d = data((
    x = rand(1000),
    y = rand(1000),
    group1 = rand(string.('a':'i'), 1000),
    group2 = rand(string.('j':'r'), 1000),
))

layer_1 = d * mapping(:x, :y, layout = :group1) * visual(Scatter)
paginated_1 = paginate(layer_1, layout = 9)
figuregrids = draw(paginated_1)

layer_2 = d * mapping(:x, :y, row = :group1, col = :group2) * visual(Scatter)
paginated_2 = paginate(layer_2, row = 4, col = 3)
figuregrid = draw(paginated_2, 1) # draw only the first grid
```
"""
function paginate(
        l::Union{Layer, Layers};
        layout = nothing,
        row = nothing,
        col = nothing,
    )
    layers = l isa Layer ? Layers([l]) : l
    inverted = [paginate_layer(layer; layout, row, col) for layer in layers]
    layers = map(Layers, invert(inverted))
    return PaginatedLayers(layers, layout, row, col)
end

# copied from SplitApplyCombine.jl to avoid full dependency 
function invert(a::AbstractArray{T}) where {T <: AbstractArray}
    f = first(a)
    innersize = size(a)
    outersize = size(f)
    innerkeys = keys(a)
    outerkeys = keys(f)

    @boundscheck for x in a
        if size(x) != outersize
            error("keys don't match")
        end
    end

    out = Array{Array{eltype(T),length(innersize)}}(undef, outersize)
    @inbounds for i in outerkeys
        out[i] = Array{eltype(T)}(undef, innersize)
    end

    return _invert!(out, a, innerkeys, outerkeys)
end

function _invert!(out, a, innerkeys, outerkeys)
    @inbounds for i ∈ innerkeys
        tmp = a[i]
        for j ∈ outerkeys
            out[j][i] = tmp[j]
        end
    end
    return out
end

# Reshape the vector `v` to `N` axes.
withshape(::Val{N}, v::AbstractVector) where N = reshape(v, ntuple(n -> ifelse(n < N, 1, length(v)), N))
withshape(::AbstractArray{T,N}, v::AbstractVector) where {T,N} = withshape(Val{N}(), v)
