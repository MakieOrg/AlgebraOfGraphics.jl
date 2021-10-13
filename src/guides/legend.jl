function legend!(fg::FigureGrid; kwargs...)
    attr = Dict{Symbol,Any}(kwargs)
    position = pop!(attr, :position, :right)
    get!(attr, :orientation, default_orientation(position))

    guide_pos = guides_position(fg.figure, position)

    legend!(guide_pos, fg; attr...)
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
