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

function compute_processedlayers_grid(processedlayers, categoricalscales)
    indices = CartesianIndices(compute_grid_positions(categoricalscales))
    pls_grid = map(_ -> ProcessedLayer[], indices)
    for processedlayer in processedlayers
        append_processedlayers!(pls_grid, processedlayer, categoricalscales)
    end
    return pls_grid
end

function compute_attributes(attributes, primary, named)
    attrs = NamedArguments()
    merge!(attrs, attributes)
    merge!(attrs, primary)
    merge!(attrs, named)

    # implement alpha transparency
    alpha = get(attrs, :alpha, automatic)
    color = get(attrs, :color, automatic)
    (color !== automatic) && (alpha !== automatic) && (color = (color, alpha))

    # opt out of the default cycling mechanism
    cycle = nothing

    merge!(attrs, Dictionary(valid_options(; color, cycle)))

    # remove unnecessary information 
    return filterkeys(!in((:col, :row, :layout, :alpha)), attrs)
end

function compute_entries_continuousscales(pls_grid)
    # Here processed layers in `pls_grid` are "sliced",
    # the categorical scales have been applied, but not
    # the continuous scales

    entries_grid = map(_ -> Entry[], pls_grid)
    continuousscales_grid = map(_ -> MixedArguments(), pls_grid)

    for idx in eachindex(pls_grid), pl in pls_grid[idx]
        # Apply continuous transformations
        positional = map(contextfree_rescale, pl.positional)
        plottype = Makie.plottype(pl.plottype, positional...)

        # Compute continuous scales with correct plottype, to figure out role of color
        continuousscales = AlgebraOfGraphics.continuousscales(ProcessedLayer(pl; plottype))
        mergewith!(mergescales, continuousscales_grid[idx], continuousscales)

        # Compute `Entry` with rescaled columns
        named = compute_attributes(pl.attributes, pl.primary, map(contextfree_rescale, pl.named))
        entry = Entry(plottype, positional, named)
        push!(entries_grid[idx], entry)
    end

    # Compute merged continuous scales, as it may be needed to use global extrema
    merged_continuousscales = reduce(mergewith!(mergescales), continuousscales_grid, init=MixedArguments())

    colorscale = get(merged_continuousscales, :color, nothing)
    if !isnothing(colorscale)
        # TODO: might need to change to support temporal color scale
        colorrange = colorscale.extrema
        for entries in entries_grid, entry in entries
            # Safe to do, as each entry has a separate `named` dictionary
            set!(entry.named, :colorrange, colorrange)
        end
    end

    return entries_grid, continuousscales_grid, merged_continuousscales
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

    categoricalscales = MixedArguments()
    for processedlayer in processedlayers
        mergewith!(
            mergescales,
            categoricalscales,
            AlgebraOfGraphics.categoricalscales(processedlayer, palettes)
        )
    end
    # fit categorical scales (compute plot values using all data values)
    map!(fitscale, categoricalscales, categoricalscales)

    pls_grid = compute_processedlayers_grid(processedlayers, categoricalscales)
    entries_grid, continuousscales_grid, merged_continuousscales =
        compute_entries_continuousscales(pls_grid)

    indices = CartesianIndices(pls_grid)
    axes_grid = map(indices) do c
        return AxisSpecEntries(
            AxisSpec(c, axis),
            entries_grid[c],
            categoricalscales,
            continuousscales_grid[c]
        )
    end

    # Axis labels and ticks
    for ae in axes_grid
        ndims = isaxis2d(ae) ? 2 : 3
        for (i, var) in zip(1:ndims, (:x, :y, :z))
            scale = get(ae.categoricalscales, i) do
                return get(ae.continuousscales, i, nothing)
            end
            isnothing(scale) && continue
            label = getlabel(scale)
            # Use global scales for ticks for now
            # TODO: requires a nicer mechanism that takes into account axis linking
            (scale isa ContinuousScale) && (scale = merged_continuousscales[i])
            for (k, v) in pairs((label=to_string(label), ticks=ticks(scale)))
                keyword = Symbol(var, k)
                # Only set attribute if it was not present beforehand
                get!(ae.axis.attributes, keyword, v)
            end
        end
    end

    return axes_grid
end
