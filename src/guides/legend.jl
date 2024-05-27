function legend!(fg::FigureGrid; position=:right,
                 orientation=default_orientation(position), kwargs...)

    guide_pos = guides_position(fg.figure, position)
    return legend!(guide_pos, fg; orientation, kwargs...)
end

"""
    legend!(figpos, grid; kwargs...)

Compute legend for `grid` (which should be the output of [`draw!`](@ref)) and draw it in
position `figpos`. Attributes allowed in `kwargs` are the same as `MakieLayout.Legend`.
"""
function legend!(figpos, grid; kwargs...)
    legend = compute_legend(grid)
    return isnothing(legend) ? nothing : Legend(figpos, legend...; kwargs...)
end

"""
    plottypes_attributes(entries)

Return plottypes and relative attributes, as two vectors of the same length,
for the given `entries`.
"""
function plottypes_attributes(entries)
    plottypes = PlotType[]
    attributes = Vector{Symbol}[]
    for entry in entries
        plottype = entry.plottype
        n = findfirst(==(plottype), plottypes)
        attrs = keys(entry.named)
        if isnothing(n)
            push!(plottypes, plottype)
            push!(attributes, collect(Symbol, attrs))
        else
            union!(attributes[n], attrs)
        end
    end
    return plottypes, attributes
end

compute_legend(fg::FigureGrid) = compute_legend(fg.grid)

# ignore positional scales and keywords that don't support legends
function legendable_scales(scales)
    return filterkeys(scale_is_legendable, scales)
end

scale_is_legendable(_) = false
scale_is_legendable(::Type{ColorScale}) = true

function compute_legend(grid::Matrix{AxisEntries})
    # gather valid named scales
    scales = legendable_scales(first(grid).categoricalscales)

    # if no legendable scale is present, return nothing
    isempty(scales) && return nothing

    titles = unique!(collect(map(getlabel, scales)))

    plottypes, attributes = plottypes_attributes(entries(grid))

    labels = Vector{AbstractString}[]
    elements_list = Vector{Vector{LegendElement}}[]

    for title in titles
        label_attrs = [key for (key, val) in pairs(scales) if getlabel(val) == title]
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
        push!(labels, map(to_string, uniquevalues))
        push!(elements_list, elements)
    end
    return elements_list, labels, titles
end

# Notes

# TODO: correctly handle composite plot types (now fall back to poly)
# TODO: make legend updateable?
# TODO: allow custom attributes in legend elements?
