# Dispatcher type for `draw` usage.
struct Paginate
    each::Vector
end

draw(p::Paginate; kws...) = draw.(p.each; kws...)
draw(p::Paginate, i::Int; kws...) = draw(p.each[i]; kws...)

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

function paginator(layer::Layer, data, spec, limiter)
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
    Main.@infiltrate
    return Paginate(layers)
end

function paginator(layer::Layer, data, (row, col)::Tuple, (rows, columns)::Tuple)
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
    Main.@infiltrate
    return Paginate(vec(layers))
end

"""
    paginate(layers; limit, rows, columns)
Paginate the layer objects created by an `AlgebraOfGraphics` spec to create a
vector of layers that each operate on a subset of the input data. Can be passed
through to `draw` which will return a `Vector` of figures rather than a single
figure.
The following keywords must be combined to create suitable paginations:
  - `limit` and `layout` or,
  - `rows` and `row` and/or,
  - `columns` and `col`
"""
function paginate end

function paginate(
        layer::Layer;
        limit = nothing,
        rows = nothing,
        columns = nothing,
    )
    named = layer.named
    data = layer.data

    layout = get(named, :layout, nothing)
    row = get(named, :row, nothing)
    col = get(named, :col, nothing)

    valid(a, b) = !isnothing(a) && !isnothing(b)

    if valid(layout, limit)
        return paginator(layer, data, layout, limit)
    elseif valid(row, rows) && valid(col, columns)
        return paginator(layer, data, (row, col), (rows, columns))
    elseif valid(row, rows)
        return paginator(layer, data, row, rows)
    elseif valid(col, columns)
        return paginator(layer, data, col, columns)
    else
        return Paginate([layer])
    end
end

function paginate(
        layers::Layers;
        limit = nothing,
        rows = nothing,
        columns = nothing,
    )
    inverted = [paginate(layer; limit, rows, columns).each for layer in layers]
    return Paginate(Layers.(SplitApplyCombine.invert(inverted)))
end

# Reshape the vector `v` to `N` axes.
withshape(::Val{N}, v::AbstractVector) where N = reshape(v, ntuple(n -> ifelse(n < N, 1, length(v)), N))
withshape(::AbstractArray{T,N}, v::AbstractVector) where {T,N} = withshape(Val{N}(), v)
