legend!(fg::FigureGrid) = legend!(fg.figure[:, end+1], fg)

function legend!(figpos, fg)
    legend = compute_legend(fg)
    return isnothing(legend) ? nothing : Legend(figpos, legend...)
end

colorbar!(fg::FigureGrid) = colorbar!(fg.figure[:, end+1], fg)

function colorbar!(figpos, fg)
    colorbar = compute_colorbar(fg)
    return isnothing(colorbar) ? nothing : Colorbar(figpos; colorbar...)
end

function has_zcolor(entry::Entry)
    return entry.plottype <: Union{Heatmap, Contour, Contourf, Surface} &&
        !haskey(entry.primary, :color) &&
        !haskey(entry.named, :color) &&
        !haskey(entry.attributes, :color)
end

function getlabeledcolorrange(grid)
    zcolor = any(has_zcolor, entries(grid))
    key = zcolor ? 3 : :color
    continuous_color_entries = Iterators.filter(entries(grid)) do entry
        return get(entry, key, nothing) isa AbstractArray{<:Number}
    end
    colorrange = compute_extrema(continuous_color_entries, key)
    label = compute_label(continuous_color_entries, key)
    return isnothing(colorrange) ? nothing : (label, colorrange)
end

compute_colorbar(fg::FigureGrid) = compute_colorbar(fg.grid)
function compute_colorbar(grid::Matrix{AxisEntries})
    labeledcolorrange = getlabeledcolorrange(grid)
    isnothing(labeledcolorrange) && return
    label, limits = labeledcolorrange
    colormap = current_default_theme().colormap[]
    for entry in entries(grid)
        colormap = to_value(get(entry.attributes, :colormap, colormap))
    end
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

compute_legend(fg::FigureGrid) = compute_legend(fg.grid)
function compute_legend(grid::Matrix{AxisEntries})
    # assume all subplots have same scales, to be changed to support free scales
    scales = filter(hassymbolkey, first(grid).scales)

    # remove keywords that don't support legends
    for key in [:row, :col, :layout, :stack, :dodge, :group]
        pop!(scales, key, nothing)
    end

    # if no legend-worthy keyword remains return nothing
    isempty(scales) && return nothing

    titles = unique!(collect(String, (scale.label for scale in values(scales))))
    # empty strings create difficulties with the layout
    nonemptytitles = map(t -> isempty(t) ? " " : t, titles)

    plottypes, attributes = plottypes_attributes(entries(grid))

    labels = Vector{String}[]
    elements_list = Vector{Vector{LegendElement}}[]

    for title in titles
        label_attrs = [key for (key, val) in scales if val.label == title]
        uniquevalues = mapreduce(k -> datavalues(scales[k]), assert_equal, label_attrs)
        elements = map(eachindex(uniquevalues)) do idx
            local elements = LegendElement[]
            for (P, attrs) in zip(plottypes, attributes)
                shared_attrs = attrs ∩ label_attrs
                isempty(shared_attrs) && continue
                options = [attr => plotvalues(scales[attr])[idx] for attr in shared_attrs]
                append!(elements, legend_elements(P; options...))
            end
            return elements
        end
        push!(labels, map(string, uniquevalues))
        push!(elements_list, elements)
    end
    return elements_list, labels, nonemptytitles
end

# Notes

# TODO: correctly handle composite plot types (now fall back to poly)
# TODO: make legend updateable?
# TODO: allow custom attributes in legend elements?
