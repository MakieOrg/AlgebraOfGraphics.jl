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
    # fit scales (compute plot values using all data values)
    map!(fitscale, values(scales))

    indices = CartesianIndices(compute_grid_positions(scales))
    axes_grid = map(c -> AxisSpecEntries(AxisSpec(c, axis), Entry[], scales), indices)
    labels_grid = map(_ -> MixedArguments(), axes_grid)

    for processedlayer in processedlayers
        entries = compute_entries_grid!(processedlayer, labels_grid, scales)
        for idx in eachindex(axes_grid)
            append!(axes_grid[idx].entries, entries[idx])
        end
    end

    # FIXME: add back before merging
    # # Link colors
    # labeledcolorrange = getlabeledcolorrange(axes_grid)
    # if !isnothing(labeledcolorrange)
    #     _, colorrange = labeledcolorrange
    #     for processedlayer in AlgebraOfGraphics.processedlayers(axes_grid)
    #         # `attributes` were obtained via `set` above, FIXME: no longer true
    #         # so it is OK to edit the keys
    #         set!(processedlayer.attributes, :colorrange, colorrange)
    #     end
    # end

    # Axis labels and ticks
    for (ae, labels) in zip(axes_grid, labels_grid)
        ndims = ae.type isa Axis ? 2 : 3
        for (i, var) in zip(1:ndims, (:x, :y, :z))
            # TODO: move this computation out of the `for` loop
            scale = get(scales, i) do
                return compute_extrema(AlgebraOfGraphics.entries(axes_grid), i)
            end
            isnothing(scale) && continue
            # FIXME: make sure what to do if `label` is `nothing`
            label = something(get(labels, i, nothing), "")
            for (k, v) in pairs((label=string(label), ticks=ticks(scale)))
                keyword = Symbol(var, k)
                # Only set attribute if it was not present beforehand
                get!(ae.axis.attributes, keyword, v)
            end
        end
    end

    return axes_grid
end
