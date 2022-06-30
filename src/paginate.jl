# Dispatcher type for `draw` usage.
struct PaginatedLayers
    each::Vector{ProcessedLayers}
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

function getsubsets(data, by)
    values = sort!(unique(data))
    parts = Iterators.partition(values, by)
    sets = map(Set{eltype(values)}, parts)
    map(sets) do set
        map(eachindex(data)) do i
            @inbounds data[i] in set
        end
    end
end

colname((name, _)::Pair) = name
colname(name) = name

getcols(row, name) = getcolumn(row, name)
getcols(row, name::Tuple) = map(n -> getcolumn(row, n), name)

function paginate_layer(layer::ProcessedLayer; layout=nothing, row=nothing, col=nothing)
    primary = layer.primary

    layout_data = get(primary, :layout, nothing)
    row_data = get(primary, :row, nothing)
    col_data = get(primary, :col, nothing)

    valid(a, b) = !isnothing(a) && !isnothing(b)

    layers = if valid(layout_data, layout)
        paginate_layer(layer, layout_data => layout)
    elseif valid(row_data, row) && valid(col_data, col)
        paginate_layer(layer, row_data => row, col_data => col)
    elseif valid(row_data, row)
        paginate_layer(layer, row_data => row)
    elseif valid(col, col)
        paginate_layer(layer, col_data => col)
    else
        [layer]
    end
    return layers
end

function vecs_view(d::Dictionary, indices::AbstractVector)
    map(d) do value
        view(value, indices)
    end
end
function vecs_view(vec_of_vecs::AbstractVector, indices::AbstractVector)
    [view(vec, indices) for vec in vec_of_vecs]
end

function paginate_layer(layer::ProcessedLayer, data_limiter_pairs::Pair...)
    subsets = map(Base.splat(getsubsets), data_limiter_pairs)
    layers = map(Iterators.product(subsets...)) do (subs...,)
        view_vector = map(all, zip(subs...))
        primary = vecs_view(layer.primary, view_vector)
        positional = vecs_view(layer.positional, view_vector)
        named = vecs_view(layer.named, view_vector)
        ProcessedLayer(layer; primary, positional, named)
    end
    return vec(layers)
end

"""
    paginate(l; layout=nothing, row=nothing, col=nothing)

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
    processed_layers = map(ProcessedLayer, layers.layers)
    inverted = [paginate_layer(processed_layer; layout, row, col) for processed_layer in processed_layers]
    layers = map(ProcessedLayers, invert(inverted))
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
