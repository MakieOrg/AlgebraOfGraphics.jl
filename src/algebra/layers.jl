struct Layers
    layers::Vector{Layer}
end

Base.convert(::Type{Layers}, s::Layer) = Layers([s])
Base.convert(::Type{Layers}, s::Layers) = s

Base.getindex(v::Layers, i::Int) = v.layers[i]
Base.length(v::Layers) = length(v.layers)
Base.eltype(::Type{Layers}) = Layer
Base.iterate(v::Layers, args...) = iterate(v.layers, args...)

const OneOrMoreLayers = Union{Layers, Layer}

function Base.:+(s1::OneOrMoreLayers, s2::OneOrMoreLayers)
    l1::Layers, l2::Layers = s1, s2
    return Layers(vcat(l1.layers, l2.layers))
end

function Base.:*(s1::OneOrMoreLayers, s2::OneOrMoreLayers)
    l1::Layers, l2::Layers = s1, s2
    return Layers([el1 * el2 for el1 in l1 for el2 in l2])
end

function summary(e::Entry)
    scales = Dict{KeyType, Any}()
    for (i, tup) in enumerate((e.primary, e.positional, e.named))
        for (key, val) in pairs(tup)
            scales[key] = i > 1 && iscontinuous(val) ? extrema(val) : collect(uniquesorted(vec(val)))
        end
    end
    return Entry(e.plottype, e.primary, e.positional, e.named, scales, e.labels, e.attributes)
end

mergesummaries(s1::AbstractVector, s2::AbstractVector) = mergesorted(s1, s2)
mergesummaries(s1::Tuple, s2::Tuple) = extend_extrema(s1, s2)

mergelabels(a, b) = a

function compute_axes_grid(fig, s::OneOrMoreLayers;
                           axis=NamedTuple(), palettes=NamedTuple())
    layers::Layers = s
    labels = Dict{KeyType, Any}()
    entries = [summary(entry) for layer in layers for entry in process_transformations(layer)]
    summaries = mapfoldl(entry -> entry.scales, mergewith!(mergesummaries), entries, init=Dict{KeyType, Any}())
    labels = mapfoldl(entry -> entry.labels, mergewith!(mergelabels), entries, init=Dict{KeyType, Any}())

    palettes = merge(default_palettes(), palettes)
    scales = default_scales(summaries, palettes)

    e = (; entries, scales, labels)

    rowcol = (:row, :col)

    layout_scale, scales... = map((:layout, rowcol...)) do sym
        return get(e.scales, sym, nothing)
    end

    grid_size = map(scales, (first, last)) do scale, f
        isnothing(scale) || return maximum(scale.plot)
        isnothing(layout_scale) || return maximum(f, layout_scale.plot)
        return 1
    end

    axes_grid = map(CartesianIndices(grid_size)) do c
        type = get(axis, :type, Axis)
        options = Base.structdiff(axis, (; type))
        ax = type(fig[Tuple(c)...]; options...)
        return AxisEntries(ax, Entry[], e.scales, e.labels)
    end

    for entry in e.entries
        rows, cols = map(rowcol, scales, (first, last)) do sym, scale, f
            v = get(entry.primary, sym, nothing)
            layout_v = get(entry.primary, :layout, nothing)
            # without layout info, plot on all axes
            # all values in `v` and `layout_v` are equal
            isnothing(v) || return rescale(v[1:1], scale)
            isnothing(layout_v) || return map(f, rescale(layout_v[1:1], layout_scale))
            return 1:f(grid_size)
        end
        for i in rows, j in cols
            ae = axes_grid[i, j]
            push!(ae.entries, entry)
        end
    end

    # Link colors
    labeledcolorbar = getlabeledcolorbar(axes_grid)
    if !isnothing(labeledcolorbar)
        _, colorbar = labeledcolorbar
        colorrange = colorbar.extrema
        for entry in AlgebraOfGraphics.entries(axes_grid)
            entry.attributes[:colorrange] = colorrange
        end
    end

    return axes_grid

end

function AbstractPlotting.plot!(fig, s::OneOrMoreLayers;
                                axis=NamedTuple(), palettes=NamedTuple())
    grid = compute_axes_grid(fig, s; axis, palettes)
    foreach(plot!, grid)
    return grid
end

function AbstractPlotting.plot(s::OneOrMoreLayers;
                               axis=NamedTuple(), figure=NamedTuple(), palettes=NamedTuple())
    fig = Figure(; figure...)
    grid = plot!(fig, s; axis, palettes)
    return FigureGrid(fig, grid)
end

# Convenience function, which may become superfluous if `plot` also calls `facet!`
function draw(s::OneOrMoreLayers;
              axis = NamedTuple(), figure=NamedTuple(), palettes=NamedTuple())
    fg = plot(s; axis, figure, palettes)
    facet!(fg)
    Legend(fg)
    resizetocontent!(fg)
    return fg
end

function draw!(fig, s::OneOrMoreLayers;
               axis=NamedTuple(), palettes=NamedTuple())
    ag = plot!(fig, s; axis, palettes)
    facet!(fig, ag)
    return ag
end