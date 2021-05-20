function MakieLayout.Legend(fg::FigureGrid)
    colorbar = _Colorbar_(fg)
    legend = _Legend_(fg)
    if !isnothing(colorbar)
        Colorbar(fg.figure[:, end + 1]; colorbar...)
    end
    if !isnothing(legend)
        Legend(fg.figure[:, end + 1], legend...)
    end
end

function has_zcolor(entry::Entry)
    return entry.plottype <: Union{Heatmap, Contour, Contourf, Surface} &&
        !haskey(entry.primary, :color) &&
        !haskey(entry.named, :color) &&
        !haskey(entry.attributes, :color)
end

function getlabeledcolorbar(grid)
    scales, labels = first(grid).scales, first(grid).labels
    key = any(has_zcolor, entries(grid)) ? 3 : :color
    label, scale = get(labels, key, nothing), get(scales, key, nothing)
    return scale isa ContinuousScale ? (label, scale) : nothing
end

function _Colorbar_(fg::FigureGrid)
    grid = fg.grid
    labeledcolorbar = getlabeledcolorbar(grid)
    isnothing(labeledcolorbar) && return
    label, colorscale = labeledcolorbar
    colormap = current_default_theme().Colorbar.colormap[]
    for entry in entries(grid)
        colormap = to_value(get(entry.attributes, :colormap, colormap))
    end
    limits = colorscale.extrema
    return (; label, limits, colormap)
end

"""
    plottypes_attributes(entries)

Return plottypes and relative attributes, as two vectors of the same length,
for the given `entries`.
"""
function plottypes_attributes(entries)
    plottypes = PlotFunc[]
    attributes = Vector{Symbol}[]
    for entry in entries
        # FIXME: this should probably use the rescaled values
        plottype = Makie.plottype(entry.plottype, entry.positional...)
        n = findfirst(==(plottype), plottypes)
        attrs = (keys(entry.primary)..., keys(entry.named)...)
        if isnothing(n)
            push!(plottypes, plottype)
            push!(attributes, collect(Symbol, attrs))
        else
            union!(attributes[n], attrs)
        end
    end
    return plottypes, attributes
end

hassymbolkey((k, v)::Pair) = k isa Symbol

function _Legend_(fg::FigureGrid)
    grid = fg.grid

    # assume all subplots have same scales, to be changed to support free scales
    scales = filter(hassymbolkey, first(grid).scales)
    labels = filter(hassymbolkey, first(grid).labels)

    # remove keywords that don't support legends
    for key in [:row, :col, :layout, :stack, :dodge, :group]
        pop!(labels, key, nothing)
    end
    for (key, val) in scales
        val isa ContinuousScale && pop!(labels, key, nothing)
    end

    # if no legend-worthy keyword remains return nothing
    isempty(labels) && return nothing

    titles = unique!(collect(String, values(labels)))
    # empty strings create difficulties with the layout
    nonemptytitles = map(t -> isempty(t) ? " " : t, titles)

    plottypes, attributes = plottypes_attributes(entries(grid))

    labels_list = Vector{String}[]
    elements_list = Vector{Vector{LegendElement}}[]

    for title in titles
        label_attrs = [key for (key, val) in labels if val == title]
        first_scale = scales[first(label_attrs)]
        elements = map(eachindex(first_scale.data)) do idx
            local elements = LegendElement[]
            for (P, attrs) in zip(plottypes, attributes)
                shared_attrs = attrs ∩ label_attrs
                isempty(shared_attrs) && continue
                options = [attr => scales[attr].plot[idx] for attr in shared_attrs]
                append!(elements, legend_elements(P; options...))
            end
            return elements
        end
        push!(labels_list, map(string, first_scale.data))
        push!(elements_list, elements)
    end
    return elements_list, labels_list, nonemptytitles
end

#Notes

# TODO: correctly handle composite plot types (now fall back to poly)
# TODO: check that all scales for the same label agree on the data
# TODO: make legend updateable?
# TODO: allow custom attributes in legend elements?
