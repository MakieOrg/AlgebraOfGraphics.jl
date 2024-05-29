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
scale_is_legendable(::Type{AesColor}) = true

function compute_legend(grid::Matrix{AxisEntries})
    # gather valid named scales
    scales = legendable_scales(first(grid).categoricalscales)

    # if no legendable scale is present, return nothing
    isempty(scales) && return nothing

    processedlayers = first(grid).processedlayers

    plottypes, attributes = plottypes_attributes(entries(grid))

    # turn dict of dicts into single-level dict
    scales_flattened = Dictionary{Pair{Type{<:Aesthetic},Union{Nothing,Symbol}},CategoricalScale}()
    for (aes, scaledict) in pairs(scales)
        for (scale_id, scale) in pairs(scaledict)
            insert!(scales_flattened, aes => scale_id, scale)
        end
    end

    titles = []
    labels = Vector{AbstractString}[]
    elements_list = Vector{Vector{LegendElement}}[]

    for (aes, scaledict) in pairs(scales)
        for (scale_id, scale) in pairs(scaledict)
            push!(titles, @show(getlabel(scale)))

            display(scale)

            datavals = @show datavalues(scale)
            plotvals = @show plotvalues(scale)

            legend_els = [LegendElement[] for _ in datavals]

            for processedlayer in processedlayers
                aes_mapping = aesthetic_mapping(processedlayer)
                ProcessedLayer
                matching_keys = filter(keys(merge(dictionary(processedlayer.positional), processedlayer.primary, processedlayer.named))) do key
                    get(aes_mapping, key, nothing) === aes &&
                        get(processedlayer.scale_mapping, key, nothing) === scale_id
                end

                isempty(matching_keys) && continue

                for (i, (dataval, plotval)) in enumerate(zip(datavals, plotvals))
                    append!(legend_els[i], legend_elements(processedlayer, MixedArguments(map(key -> plotval, matching_keys))))
                end

            end

            # label_attrs = [key for (key, val) in pairs(scales_flattened) if getlabel(val) == title]
            # @show label_attrs
            # uniquevalues = mapreduce(k -> datavalues(scales_flattened[k]), assert_equal, label_attrs)
            # @show uniquevalues
            # elements = map(eachindex(uniquevalues)) do idx
            #     local elements = LegendElement[]
            #     for (P, attrs) in zip(plottypes, attributes)
            #         shared_attrs = attrs ∩ label_attrs
            #         isempty(shared_attrs) && continue
            #         options = [attr => plotvalues(scales_flattened[attr])[idx] for attr in shared_attrs]
            #         append!(elements, legend_elements(P; options...))
            #     end
            #     return elements
            # end
            # push!(labels, map(to_string, uniquevalues))
            # push!(elements_list, elements)
            push!(labels, string.(datavals))
            push!(elements_list, legend_els)
        end
    end
    return elements_list, labels, titles
end

function legend_elements(p::ProcessedLayer, scale_args::MixedArguments)
    legend_elements(p.plottype, scale_args)
end

function legend_elements(::Type{Scatter}, scale_args::MixedArguments)
    [MarkerElement(
        color = haskey(scale_args, :color) ? scale_args[:color] : Makie.current_default_theme()[:markercolor],
        markerpoints = [Point2f(0.5, 0.5)],
        marker = Makie.current_default_theme()[:marker],
    )]
end

function legend_elements(::Union{Type{BarPlot},Type{Violin}}, scale_args::MixedArguments)
    [PolyElement(
        color = haskey(scale_args, :color) ? scale_args[:color] : Makie.current_default_theme()[:patchcolor],
    )]
end

function legend_elements(::Type{HLines}, scale_args::MixedArguments)
    [LineElement(
        color = haskey(scale_args, :color) ? scale_args[:color] : Makie.current_default_theme()[:linecolor],
    )]
end

# Notes

# TODO: correctly handle composite plot types (now fall back to poly)
# TODO: make legend updateable?
# TODO: allow custom attributes in legend elements?
