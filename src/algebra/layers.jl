"""
    Layers(layers::Vector{Layer})

Algebraic object encoding a list of [`AlgebraOfGraphics.Layer`](@ref) objects.
`Layers` objects can be added or multiplied, yielding a novel `Layers` object.
"""
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

function compute_axes_grid(fig, s::OneOrMoreLayers;
    axis=NamedTuple(), palettes=NamedTuple())

    axes_grid = compute_axes_grid(s; axis, palettes)
    sz = size(axes_grid)
    if sz !== (1, 1) && fig isa Axis
        error("You can only pass an `Axis` to `draw!`, if the calculated layout only contains one element. Elements: $(sz)")
    end

    return map(ae -> AxisEntries(ae, fig), axes_grid)
end

function compute_axes_grid(s::OneOrMoreLayers;
                           axis=NamedTuple(), palettes=NamedTuple())
    layers::Layers = s
    processedlayers = map(ProcessedLayer, layers)

    theme_palettes = NamedTuple(Makie.current_default_theme()[:palette])
    palettes = merge((layout=wrap,), map(to_value, theme_palettes), palettes)

    scales = MixedArguments()
    for processedlayer in processedlayers
        mergewith!(mergescales, scales, categoricalscales(processedlayer, palettes))
    end
    # fit categorical scales (compute plot values using all data values)
    map!(fitscale, scales, scales)

    # fit continuous scales
    indices = CartesianIndices(compute_grid_positions(scales))
    processedlayers = map(pl -> rescale(pl, scales), processedlayers)
    continuousscales_grid = map(_ -> MixedArguments(), indices)
    for processedlayer in processedlayers
        for c in CartesianIndices(shape(processedlayer))
            pl = slice(processedlayer, c)
            rows, cols = compute_grid_positions(scales, pl.primary)
            for i in rows, j in cols
                mergewith!(mergescales, continuousscales_grid[i, j], continuousscales(pl))
            end
        end
    end

    # Compute merged continuous scales, as it may be needed to use global extrema
    merged_continuousscales = reduce(mergewith!(mergescales), continuousscales_grid, init=MixedArguments())
    axes_grid = map(c -> AxisSpecEntries(AxisSpec(c, axis), Entry[], scales, continuousscales_grid[c]), indices)
    for processedlayer in processedlayers
        append_entries!(axes_grid, processedlayer, merged_continuousscales)
    end

    # Axis labels and ticks
    for ae in axes_grid
        ndims = isaxis2d(ae) ? 2 : 3
        for (i, var) in zip(1:ndims, (:x, :y, :z))
            scale = get(ae.categoricalscales, i) do
                return get(ae.continuousscales, i, nothing) # FIXME: Should maybe fit across axes?
            end
            isnothing(scale) && continue
            label = something(scale.label, "")
            # Use global scales for ticks for now, TODO: requires a nicer mechanism
            (scale isa ContinuousScale) && (scale = merged_continuousscales[i])
            for (k, v) in pairs((label=string(label), ticks=ticks(scale)))
                keyword = Symbol(var, k)
                # Only set attribute if it was not present beforehand
                get!(ae.axis.attributes, keyword, v)
            end
        end
    end

    return axes_grid
end
