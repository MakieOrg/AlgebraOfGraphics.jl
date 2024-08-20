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
function legend!(figpos, grid; order = nothing, kwargs...)
    legend = compute_legend(grid; order)
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

compute_legend(fg::FigureGrid; order) = compute_legend(fg.grid; order)

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
    s = Set() # type constraining this via `return_type` had some stack overflow problem on 1.6
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

struct ScaleWithMeta
    aes::Type{<:Aesthetic}
    scale_id::Union{Nothing,Symbol}
    scale::Union{CategoricalScale,ContinuousScale}
end

function categorical_scales_mergeable(c1::CategoricalScale, c2::CategoricalScale)
    getlabel(c1) == getlabel(c2) && datavalues(c1) == datavalues(c2) && datalabels(c1) == datalabels(c2)
end

categorical_scales_mergeable(c1, c2) = false # there can be continuous scales in the mix, like markersize

function compute_legend(grid::Matrix{AxisEntries}; order::Union{Nothing,AbstractVector})
    # gather valid named scales
    scales_categorical = legendable_scales(Val(:categorical), first(grid).categoricalscales)
    scales_continuous = legendable_scales(Val(:continuous), first(grid).continuousscales)

    scales = Iterators.flatten((pairs(scales_categorical), pairs(scales_continuous)))

    # if no legendable scale is present, return nothing
    isempty(scales) && return nothing

    scales_by_symbol = Dictionary{Symbol,ScaleWithMeta}()

    _aes_sym(::Type{A}) where A<:Aesthetic = Symbol(replace(string(nameof(A)), r"^Aes" => ""))

    for (aes, scaledict) in scales
        for (scale_id, scale) in pairs(scaledict)
            symbol = scale_id === nothing ? _aes_sym(aes) : scale_id
            insert!(scales_by_symbol, symbol, ScaleWithMeta(aes, scale_id, scale))
        end
    end

    processedlayers = first(grid).processedlayers

    titles = []
    labels = Vector[]
    elements_list = Vector{Vector{LegendElement}}[]

    # we can't loop over all processedlayers here because one layer can be sliced into multiple processedlayers
    unique_processedlayers = unique_by(processedlayers) do pl
        (pl.plottype, pl.attributes)
    end

    final_order = if order === nothing
        basic_order = collect(keys(scales_by_symbol))
        merged_order = []
        i = 1
        while i <= length(basic_order)
            sc = basic_order[i]
            firstscale = scales_by_symbol[sc].scale
            mergeable_indices = filter(i+1:length(basic_order)) do k
                sym = basic_order[k]
                otherscale = scales_by_symbol[sym].scale
                return categorical_scales_mergeable(firstscale, otherscale)
            end
            if !isempty(mergeable_indices)
                push!(merged_order, (sc, basic_order[mergeable_indices]...))
                else
                push!(merged_order, sc)
            end
            deleteat!(basic_order, mergeable_indices)
            i += 1
        end
        merged_order
    else
        order
    end

    syms_or_symgroups_and_title(sym::Symbol) = [sym], getlabel(scales_by_symbol[sym].scale)
    syms_or_symgroups_and_title(syms::AbstractVector{Symbol}) = syms, nothing
    syms_or_symgroups_and_title(syms_title::Pair{<:AbstractVector{Symbol},<:Any}) = syms_title
    syms_or_symgroups_and_title(any) = throw(ArgumentError("Invalid legend order element $any"))
    syms_or_symgroups_and_title(symgroup_title::Pair{<:NTuple{N,Symbol},<:Any}) where N = syms_or_symgroups_and_title(symgroup_title[1], symgroup_title[2])
    function syms_or_symgroups_and_title(symgroup::NTuple{N,Symbol}, title = nothing) where N
        symgroups = [[symgroup...]]
        _titles = unique([getlabel(scales_by_symbol[sym].scale) for sym in symgroup])
        title = title !== nothing ? title : if length(_titles) != 1
            nothing
        else
            only(_titles)
        end
        return symgroups, title
    end

    used_scales = Set{Symbol}()

    for order_element in final_order
        syms_or_symgroups, title = syms_or_symgroups_and_title(order_element)
        title = title == "" ? nothing : title # empty titles can be hidden completely if they're `nothing`, "" still uses layout space
        push!(titles, title)
        legend_els = []
        datalabs = []
        for sym_or_symgroup in syms_or_symgroups
            # a symgroup is a vector of scale symbols which all represent the same underlying categorical
            # data, so their legends can be merged into one
            symgroup::Vector{Symbol} = sym_or_symgroup isa Symbol ? [sym_or_symgroup] : sym_or_symgroup

            for sym in symgroup
                if sym in used_scales
                    error("Scale $sym appeared twice in legend order.")
                end
                push!(used_scales, sym)
            end

            scalewithmetas = [scales_by_symbol[sym] for sym in symgroup]
            aess = [scalewithmeta.aes for scalewithmeta in scalewithmetas]
            scale_ids = [scalewithmeta.scale_id for scalewithmeta in scalewithmetas]
            _scales = [scalewithmeta.scale for scalewithmeta in scalewithmetas]

            dpds = [datavalues_plotvalues_datalabels(aes, scale) for (aes, scale) in zip(aess, _scales)]

            # Check that all scales in the merge group are compatible for the legend
            # (they should be if we have computed them, but they might not be if they were passed manually)

            for (k, kind) in zip([1, 3], ["values", "labels"])
                for i in 2:length(symgroup)
                    if dpds[1][k] != dpds[i][k]
                        error("""
                            Got passed scales $(repr(symgroup[1])) and $(repr(symgroup[i])) as a mergeable legend group but their data $kind don't match.
                            Data $kind for $(repr(symgroup[1])) are $(dpds[1][k])
                            Data $kind for $(repr(symgroup[i])) are $(dpds[i][k])
                            """
                        )
                    end
                end
            end

            # we can now extract data values and labels from the first entry, knowing they are all the same
            _datavals = dpds[1][1]
            _datalabs = dpds[1][3]

            _legend_els = [LegendElement[] for _ in _datavals]

            # We are layering legend elements on top of each other by deriving them from the processed layers,
            # each processed layer can contribute a vector of legend elements for each data value in the scale.
            for processedlayer in unique_processedlayers
                aes_mapping = aesthetic_mapping(processedlayer)

                # for each scale in the merge group, we're extracting the keys (of all positional and keyword mappings)
                # for which the aesthetic and the scale id match a mapping of the processed layer
                # (so basically we're finding all mappings which have used this scale)
                all_plotval_kwargs = map(aess, scale_ids, dpds) do aes, scale_id, (_, plotvals, _)
                    matching_keys = filter(keys(merge(Dictionary(processedlayer.positional), processedlayer.primary, processedlayer.named))) do key
                        get(aes_mapping, key, nothing) === aes &&
                            get(processedlayer.scale_mapping, key, nothing) === scale_id
                    end

                    # for each mapping which used the scale, we extract the matching plot value
                    # for example the processed layer might have used the current `AesColor` scale
                    # on the `color` mapping keyword, so we store `{:color => red}`, `{:color => blue}`, etc,
                    # one for each value in the categorical scale
                    map(plotvals) do plotval
                        MixedArguments(map(key -> plotval, matching_keys))
                    end
                end

                # we can merge the kwarg dicts from the different scales so that one legend element for this
                # processed layer type can represent attributes for multiple scales at once.
                # for example, a processed layer with a Scatter might get `{:color => red}` from one scale and
                # `{:marker => circle}` from another, which means the legend element is computed using
                # `{:color => red, :marker => circle}`
                merged_plotval_kwargs = map(eachindex(first(all_plotval_kwargs))) do i
                    merge([plotval_kwargs[i] for plotval_kwargs in all_plotval_kwargs]...)
                end

                for (i, kwargs) in enumerate(merged_plotval_kwargs)
                    # skip the legend element for this processed layer if the kwargs are empty
                    # which means that no scale in this merge group affected this processedlayer
                    if !isempty(kwargs)
                        append!(_legend_els[i], legend_elements(processedlayer, kwargs))
                    end
                end

            end

            append!(datalabs, _datalabs)
            append!(legend_els, _legend_els)
        end
        push!(labels, datalabs)
        push!(elements_list, legend_els)
    end

    unused_scales = setdiff(keys(scales_by_symbol), used_scales)
    if !isempty(unused_scales)
        error("Found scales that were missing from the manual legend ordering: $(sort!(collect(unused_scales)))")
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

function legend_elements(T::Type{ScatterLines}, attributes, scale_args::MixedArguments)
    [
        LineElement(
            color = _get(T, scale_args, attributes, :color),
            linestyle = _get(T, scale_args, attributes, :linestyle),
            linewidth = _get(T, scale_args, attributes, :linewidth),
            linepoints = [Point2f(0, 0.5), Point2f(1, 0.5)],
        ),
        MarkerElement(
            color = _get(T, scale_args, attributes, :color),
            markerpoints = [Point2f(0.5, 0.5)],
            marker = _get(T, scale_args, attributes, :marker),
            markerstrokewidth = _get(T, scale_args, attributes, :strokewidth),
            markersize = _get(T, scale_args, attributes, :markersize),
            markerstrokecolor = _get(T, scale_args, attributes, :strokecolor),
        )
    ]
end

function legend_elements(T::Union{Type{BarPlot},Type{Violin},Type{BoxPlot},Type{Choropleth},Type{Poly},Type{LongPoly},Type{Density}}, attributes, scale_args::MixedArguments)
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

function legend_elements(T::Type{<:Union{HLines,VLines,Lines,LineSegments,Errorbars,Rangebars,Wireframe,ABLines}}, attributes, scale_args::MixedArguments)

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

function legend_elements(T::Type{Makie.Text}, attributes, scale_args::MixedArguments)
    [PolyElement(
        color = _get(T, scale_args, attributes, :color),
    )]
end

function legend_elements(T::Type{Contour}, attributes, scale_args::MixedArguments)
    [LineElement(
        color = _get(T, scale_args, attributes, :color),
        linestyle = _get(T, scale_args, attributes, :linestyle),
        linewidth = _get(T, scale_args, attributes, :linewidth),
    )]
end

function legend_elements(T::Type{<:Union{Band,VSpan,HSpan}}, attributes, scale_args::MixedArguments)
    [PolyElement(
        color = _get(T, scale_args, attributes, :color),
    )]
end

function legend_elements(T::Type{Arrows}, attributes, scale_args::MixedArguments)
    marker = _get(T, scale_args, attributes, :arrowhead)
    marker = marker === Makie.automatic ? :utriangle : marker # Makie handles this internally due to the 2d/3d combination. This should probably be fixed in Makie
    [
        LineElement(
            color = _get(T, scale_args, attributes, :color),
            linewidth = _get(T, scale_args, attributes, :linewidth),
            linestyle = _get(T, scale_args, attributes, :linestyle),
            linepoints = [Point2(0.5, 0), Point2(0.5, 0.75)]
        ),
        MarkerElement(;
            marker,
            color = _get(T, scale_args, attributes, :color),
            markerpoints = [Point2(0.5, 0.75)],
        ),
    ]
end

# Notes

# TODO: correctly handle composite plot types (now fall back to poly)
# TODO: make legend updateable?
# TODO: allow custom attributes in legend elements?
