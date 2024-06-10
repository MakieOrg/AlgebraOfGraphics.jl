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
function legendable_scales(kind::Val, scales)
    in_principle_legendable = filterkeys(aes -> scale_is_legendable(kind, aes), scales)
    disabled_legends_filtered = map(in_principle_legendable) do dict
        filter(dict) do scale
            scale.props.legend
        end
    end
    remaining = filter(!isempty, disabled_legends_filtered)
    return remaining
end

scale_is_legendable(kind::Union{Val{:categorical},Val{:continuous}}, _) = false
scale_is_legendable(kind::Val{:categorical}, ::Type{AesColor}) = true
scale_is_legendable(kind::Val{:categorical}, ::Type{AesMarker}) = true
scale_is_legendable(kind::Val{:categorical}, ::Type{AesLineStyle}) = true
scale_is_legendable(kind::Val{:categorical}, ::Type{AesMarkerSize}) = true
scale_is_legendable(kind::Val{:continuous}, ::Type{AesMarkerSize}) = true

function unique_by(f, collection)
    T = Base._return_type(f, Tuple{eltype(collection)})
    s = Set{T}()
    v = Vector{eltype(collection)}()
    for el in collection
        by = f(el)
        if by ∉ s
            push!(s, by)
            push!(v, el)
        end
    end
    return v
end

function compute_legend(grid::Matrix{AxisEntries})
    # gather valid named scales
    scales_categorical = legendable_scales(Val(:categorical), first(grid).categoricalscales)
    scales_continuous = legendable_scales(Val(:continuous), first(grid).continuousscales)

    scales = Iterators.flatten((pairs(scales_categorical), pairs(scales_continuous)))

    # if no legendable scale is present, return nothing
    isempty(scales) && return nothing

    processedlayers = first(grid).processedlayers

    titles = []
    labels = Vector[]
    elements_list = Vector{Vector{LegendElement}}[]

    # we can't loop over all processedlayers here because one layer can be sliced into multiple processedlayers
    unique_processedlayers = unique_by(processedlayers) do pl
        (pl.plottype, pl.attributes)
    end

    for (aes, scaledict) in scales
        for (scale_id, scale) in pairs(scaledict)
            push!(titles, getlabel(scale))

            datavals, plotvals, datalabs = datavalues_plotvalues_datalabels(aes, scale)

            legend_els = [LegendElement[] for _ in datavals]

            for processedlayer in unique_processedlayers
                aes_mapping = aesthetic_mapping(processedlayer)

                matching_keys = filter(keys(merge(Dictionary(processedlayer.positional), processedlayer.primary, processedlayer.named))) do key
                    get(aes_mapping, key, nothing) === aes &&
                        get(processedlayer.scale_mapping, key, nothing) === scale_id
                end

                isempty(matching_keys) && continue

                for (i, (_, plotval)) in enumerate(zip(datavals, plotvals))
                    append!(legend_els[i], legend_elements(processedlayer, MixedArguments(map(key -> plotval, matching_keys))))
                end

            end

            push!(labels, datalabs)
            push!(elements_list, legend_els)
        end
    end
    return elements_list, labels, titles
end

datavalues_plotvalues_datalabels(aes, scale::CategoricalScale) = datavalues(scale), plotvalues(scale), datalabels(scale)
function datavalues_plotvalues_datalabels(aes::Type{AesMarkerSize}, scale::ContinuousScale)
    n = 5
    datavalues = range(scale.extrema..., length = n)
    props = scale.props.aesprops::AesMarkerSizeContinuousProps
    markersizes = values_to_markersizes(datavalues, props.sizerange, scale.extrema)
    datavalues, markersizes, string.(datavalues)
end

function legend_elements(p::ProcessedLayer, scale_args::MixedArguments)
    legend_elements(p.plottype, p.attributes, scale_args)
end

function _get(plottype, scale_args, attributes, key)
    get(scale_args, key) do
        get(attributes, key) do 
            to_value(Makie.default_theme(nothing, plottype)[key])
        end
    end
end

function legend_elements(T::Type{Scatter}, attributes, scale_args::MixedArguments)
    [MarkerElement(
        color = _get(T, scale_args, attributes, :color),
        markerpoints = [Point2f(0.5, 0.5)],
        marker = _get(T, scale_args, attributes, :marker),
        markerstrokewidth = _get(T, scale_args, attributes, :strokewidth),
        markersize = _get(T, scale_args, attributes, :markersize),
        markerstrokecolor = _get(T, scale_args, attributes, :strokecolor),
    )]
end

function legend_elements(T::Union{Type{BarPlot},Type{Violin}}, attributes, scale_args::MixedArguments)
    [PolyElement(
        color = _get(T, scale_args, attributes, :color),
        polystrokecolor = _get(T, scale_args, attributes, :strokecolor),
        polystrokewidth = _get(T, scale_args, attributes, :strokewidth),
    )]
end

function legend_elements(T::Type{RainClouds}, attributes, scale_args::MixedArguments)
    [PolyElement(
        color = _get(T, scale_args, attributes, :color),
    )]
end

function legend_elements(T::Type{Heatmap}, attributes, scale_args::MixedArguments)
    [PolyElement(
        color = _get(T, scale_args, attributes, 3),
    )]
end

function legend_elements(T::Type{<:Union{HLines,VLines,Lines,LineSegments,Errorbars,Rangebars}}, attributes, scale_args::MixedArguments)

    is_vertical = T === VLines || (T <: Union{Errorbars,Rangebars} && _get(T, scale_args, attributes, :direction) === :y)
    # TODO: seems errorbars and rangebars are missing linestyle in Makie, once this is fixed, remove this
    kwargs = T <: Union{Errorbars,Rangebars} ? (;) : (; linestyle = _get(T, scale_args, attributes, :linestyle))
    [LineElement(;
        color = _get(T, scale_args, attributes, :color),
        linewidth = _get(T, scale_args, attributes, :linewidth),
        linepoints = is_vertical ? [Point2f(0.5, 0), Point2f(0.5, 1)] : [Point2f(0, 0.5), Point2f(1, 0.5)],
        kwargs...
    )]
end

function legend_elements(T::Type{LinesFill}, attributes, scale_args::MixedArguments)
    fillalpha = _get(T, scale_args, attributes, :fillalpha)
    base_color = _get(T, scale_args, attributes, :color)

    [
        PolyElement(
            color = (base_color, fillalpha),
        ),
        LineElement(
            color = base_color,
            linewidth = _get(T, scale_args, attributes, :linewidth),
            linestyle = _get(T, scale_args, attributes, :linestyle),
        )
    ]
end

# Notes

# TODO: correctly handle composite plot types (now fall back to poly)
# TODO: make legend updateable?
# TODO: allow custom attributes in legend elements?
