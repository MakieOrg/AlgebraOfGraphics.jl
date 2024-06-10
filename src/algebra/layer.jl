"""
    AbstractDrawable

Abstract type encoding objects that can be drawn via [`AlgebraOfGraphics.draw`](@ref).
"""
abstract type AbstractDrawable end

"""
    AbstractAlgebraic  <: AbstractDrawable

Abstract type encoding objects that can be combined together using `+` and `*`.
"""
abstract type AbstractAlgebraic <: AbstractDrawable end

"""
    Layer(transformation, data, positional::AbstractVector, named::AbstractDictionary)

Algebraic object encoding a single layer of a visualization. It is composed of a dataset,
positional and named arguments, as well as a transformation to be applied to those.
`Layer` objects can be multiplied, yielding a novel `Layer` object, or added,
yielding a [`AlgebraOfGraphics.Layers`](@ref) object.
"""
Base.@kwdef struct Layer <: AbstractAlgebraic
    transformation::Any=identity
    data::Any=nothing
    positional::Arguments=Arguments()
    named::NamedArguments=NamedArguments()
end

transformation(f) = Layer(transformation=f)

data(df) = Layer(data=columns(df))

mapping(args...; kwargs...) = Layer(positional=collect(Any, args), named=NamedArguments(kwargs))

⨟(f, g) = f === identity ? g : g === identity ? f : g ∘ f

function Base.:*(l::Layer, l′::Layer)
    transformation = l.transformation ⨟ l′.transformation
    data = isnothing(l′.data) ? l.data : l′.data
    positional = vcat(l.positional, l′.positional)
    named = merge(l.named, l′.named)
    return Layer(; transformation, data, positional, named)
end

## Format for layer after processing
const PlotType = Type{<:Plot}

Base.@kwdef struct ProcessedLayer <: AbstractDrawable
    plottype::PlotType=Plot{plot}
    primary::NamedArguments=NamedArguments()
    positional::Arguments=Arguments()
    named::NamedArguments=NamedArguments()
    labels::MixedArguments=MixedArguments()
    attributes::NamedArguments=NamedArguments()
    scale_mapping::Dictionary{KeyType,Symbol}=Dictionary{KeyType,Symbol}() # maps mapping entries to scale ids for use of additional scales
end

function ProcessedLayer(processedlayer::ProcessedLayer; kwargs...)
    nt = (;
        processedlayer.plottype,
        processedlayer.primary,
        processedlayer.positional,
        processedlayer.named,
        processedlayer.labels,
        processedlayer.attributes,
        processedlayer.scale_mapping,
    )
    return ProcessedLayer(; merge(nt, values(kwargs))...)
end

"""
    ProcessedLayer(layer::Layer)

Output of processing a `layer`. A `ProcessedLayer` encodes
- plot type,
- grouping arguments,
- positional and named arguments for the plot,
- labeling information,
- visual attributes.
"""
ProcessedLayer(layer::Layer) = process(layer)

unnest(vs::AbstractArray, indices) = map(k -> [el[k] for el in vs], indices)

unnest_arrays(vs) = unnest(vs, keys(first(vs)))
function unnest_dictionaries(vs)
    return Dictionary(Dict((k => [el[k] for el in vs] for k in collect(keys(first(vs))))))
end
slice(v, c) = map(el -> getnewindex(el, c), v)

function slice(processedlayer::ProcessedLayer, c)
    labels = slice(processedlayer.labels, c)
    primary = slice(processedlayer.primary, c)
    positional = slice(processedlayer.positional, c)
    named = slice(processedlayer.named, c)
    return ProcessedLayer(processedlayer; labels, primary, positional, named)
end

function Base.map(f, processedlayer::ProcessedLayer)
    axs = shape(processedlayer)
    outputs = map(CartesianIndices(axs)) do c
        return f(slice(processedlayer.positional, c), slice(processedlayer.named, c))
    end
    positional, named = unnest_arrays(map(first, outputs)), unnest_dictionaries(map(last, outputs))
    return ProcessedLayer(processedlayer; positional, named)
end

## Get scales from a `ProcessedLayer`

uniquevalues(v::AbstractArray) = collect(uniquesorted(vec(v)))

to_label(label::AbstractString) = label
to_label(labels::AbstractArray) = reduce(mergelabels, labels)

# merge dict2 into dict but translate keys first using remapdict
function merge_with_key_remap!(dict, dict2, remapdict)
    for (key, value) in pairs(dict2)
        if haskey(remapdict, key)
            insert!(dict, remapdict[key], value)
        else
            insert!(dict, key, value)
        end
    end
    return dict
end

# TODO: thread this in from the outside instead like `palettes` before
_default_categorical_palette(::Type{<:Union{AesX,AesY}}) = Makie.automatic
_default_categorical_palette(::Type{AesColor}) = to_value(Makie.current_default_theme()[:palette][:color])
_default_categorical_palette(::Type{AesMarker}) = to_value(Makie.current_default_theme()[:palette][:marker])
_default_categorical_palette(::Type{AesLayout}) = wrap
_default_categorical_palette(::Type{<:Union{AesRow,AesCol}}) = Makie.automatic
_default_categorical_palette(::Type{AesGroup}) = Makie.automatic
_default_categorical_palette(::Type{AesDodge}) = Makie.automatic
_default_categorical_palette(::Type{AesStack}) = Makie.automatic

function get_categorical_palette(scale_props, aestype, scale_id)
    haskey(scale_props, aestype) || return _default_categorical_palette(aestype)
    subdict = scale_props[aestype]
    haskey(subdict, scale_id) || return _default_categorical_palette(aestype)
    object = subdict[scale_id]
    haskey(object, :palette) || return _default_categorical_palette(aestype)
    get_categorical_palette(aestype, object[:palette])
end

get_categorical_palette(::Type{AesColor}, colormap::AbstractVector) = colormap
get_categorical_palette(::Type{AesColor}, colormap::Symbol) = Makie.to_colormap(colormap)
get_categorical_palette(::Type{<:Union{AesX,AesY,AesZ}}, v::AbstractVector{<:Real}) = v

const AestheticMapping = Dictionary{Union{Int,Symbol},Type{<:Aesthetic}}

function get_scale_props(scale_props, aes::Type{<:Aesthetic}, scale_id::Union{Symbol,Nothing})::Dictionary{Symbol,Any}
    if !haskey(scale_props, aes)
        return Dictionary{Symbol,Any}()
    end
    props_dict = scale_props[aes]
    if !haskey(props_dict, scale_id)
        return Dictionary{Symbol,Any}()
    end
    return Dictionary{Symbol,Any}(pairs(props_dict[scale_id]))
end

function categoricalscales(processedlayer::ProcessedLayer, scale_props, aes_mapping::AestheticMapping)
    categoricals = MixedArguments()
    merge!(categoricals, processedlayer.primary)
    merge!(
        categoricals,
        filter(iscategoricalcontainer, Dictionary(processedlayer.positional)),
    )

    categoricalscales = similar(keys(categoricals), CategoricalScale)
    map!(categoricalscales, pairs(categoricals)) do (key, val)
        aestype = hardcoded_or_mapped_aes(processedlayer, key, aes_mapping)
        scale_id = get(processedlayer.scale_mapping, key, nothing)
        palette = get_categorical_palette(scale_props, aestype, scale_id)
        datavalues = key isa Integer ? mapreduce(uniquevalues, mergesorted, val) : uniquevalues(val)
        label = to_label(get(processedlayer.labels, key, ""))
        props = get_scale_props(scale_props, aestype, scale_id)
        return CategoricalScale(aestype, datavalues, palette, label, props)
    end
    return categoricalscales
end

function has_zcolor(pl::ProcessedLayer)
    for field in (:primary, :named, :attributes)
        haskey(getproperty(pl, field), :color) && return false
    end
    return pl.plottype <: Union{Heatmap, Contour, Contourf, Surface}
end

# This method works on a "sliced" `ProcessedLayer`
function continuousscales(processedlayer::ProcessedLayer, scale_props)
    continuous = MixedArguments()
    merge!(continuous, filter(iscontinuous, processedlayer.named))
    merge!(
        continuous,
        filter(iscontinuous, Dictionary(processedlayer.positional)),
    )

    aes_mapping = aesthetic_mapping(processedlayer)

    continuousscales = similar(keys(continuous), ContinuousScale)
    map!(continuousscales, keys(continuous), continuous) do key, val
        aes = aes_mapping[key]
        scale_id = get(processedlayer.scale_mapping, key, nothing)
        props = get_scale_props(scale_props, aes, scale_id)
        extrema = extrema_finite(val)
        label = to_label(get(processedlayer.labels, key, ""))
        return ContinuousScale(aes, extrema, label, props)
    end

    # this is now handled via aesthetic mapping plus custom Entry functions per plot type

    # # TODO: also encode colormap here
    # if has_zcolor(processedlayer) && !haskey(continuousscales, :color)
    #     colorscale = get(continuousscales, 3, nothing)
    #     isnothing(colorscale) || insert!(continuousscales, :color, colorscale)
    # end

    # colorrange = get(processedlayer.attributes, :colorrange, nothing)
    # if !isnothing(colorrange)
    #     manualcolorscale = ContinuousScale(colorrange, "", force=true)
    #     merge!(mergescales, continuousscales, Dictionary((color=manualcolorscale,)))
    # end

    return continuousscales
end

function extract_single(aes, dict)
    !haskey(dict, aes) && return nothing
    subdict = dict[aes]
    if length(subdict) == 0
        return nothing
    elseif length(subdict) > 1
        error("Found more than one scale for aesthetic $aes for which only one scale is allowed")
    else
        return only(values(subdict))
    end
end

## Machinery to convert a `ProcessedLayer` to a grid of slices of `ProcessedLayer`s

function compute_grid_positions(categoricalscales, primary=NamedArguments())

    aes_keyword(::Type{AesRow}) = :row
    aes_keyword(::Type{AesCol}) = :col

    return map((AesRow, AesCol), (first, last)) do aes, f
        scale = extract_single(aes, categoricalscales)
        lscale = extract_single(AesLayout, categoricalscales)
        return if !isnothing(scale)
            rg = Base.OneTo(maximum(plotvalues(scale)))
            aeskw = aes_keyword(aes)
            haskey(primary, aeskw) ? fill(primary[aeskw]) : rg
        elseif !isnothing(lscale)
            rg = Base.OneTo(maximum(f, plotvalues(lscale)))
            haskey(primary, :layout) ? fill(f(primary[:layout])) : rg
        else
            Base.OneTo(1)
        end
    end
end

const MultiAesScaleDict{T} = Dictionary{Type{<:Aesthetic},Dictionary{Union{Nothing,Symbol},T}}

# function rescale(p::ProcessedLayer, categoricalscales::MultiAesScaleDict{CategoricalScale})
#     aes_mapping = aesthetic_mapping(p)
    
#     primary = map(keys(p.primary), p.primary) do key, values
#         aes = hardcoded_or_mapped_aes(p, key, aes_mapping)
#         scale_id = get(p.scale_mapping, key, nothing)
#         scale_dict = get(categoricalscales, aes, nothing)
#         scale = scale_dict === nothing ? nothing : get(scale_dict, scale_id, nothing)
#         return rescale(values, scale)
#     end
#     positional = map(keys(p.positional), p.positional) do key, values
#         aes = hardcoded_or_mapped_aes(p, key, aes_mapping)
#         scale_id = get(p.scale_mapping, key, nothing)
#         scale_dict = get(categoricalscales, aes, nothing)
#         scale = scale_dict === nothing ? nothing : get(scale_dict, scale_id, nothing)
#         return rescale.(values, Ref(scale))
#     end

#     # compute dodging information
#     dodge = get(categoricalscales, :dodge, nothing)
#     attributes = if isa(dodge, CategoricalScale)
#         set(p.attributes, :n_dodge => maximum(plotvalues(dodge)))
#     else
#         p.attributes
#     end

#     return ProcessedLayer(p; primary, positional, attributes)
# end

function rescale(p::ProcessedLayer, categoricalscales::MultiAesScaleDict{CategoricalScale})
    aes_mapping = aesthetic_mapping(p)
    
    primary = map(keys(p.primary), p.primary) do key, values
        aes = hardcoded_or_mapped_aes(p, key, aes_mapping)
        # we only rescale those columns early that are not used in the plot objects
        # and so will never need any special plot-dependent logic
        if aes <: Union{AesCol,AesRow,AesGroup,AesLayout}
            scale_id = get(p.scale_mapping, key, nothing)
            scale_dict = get(categoricalscales, aes, nothing)
            scale = scale_dict === nothing ? nothing : get(scale_dict, scale_id, nothing)
            return rescale(values, scale)
        else
            return values
        end
    end

    return ProcessedLayer(p; primary, p.positional, p.attributes)
end

# Determine whether entries from a `ProcessedLayer` should be merged
function mergeable(processedlayer::ProcessedLayer)
    plottype, primary = processedlayer.plottype, processedlayer.primary
    # merge violins for correct renormalization
    plottype <: Violin && return true
    # merge stacked barplots
    plottype <: BarPlot && haskey(primary, :stack) && return true
    # merge waterfall plots
    plottype <: Waterfall && return true
    # do not merge by default
    return false
end

# This method works on a list of "sliced" `ProcessedLayer`s
function concatenate(pls::AbstractVector{ProcessedLayer})
    pl = first(pls)
    ns = [mapreduce(length, assert_equal, Iterators.flatten([pl.positional, pl.named])) for pl in pls]

    primary = map(key -> reduce(vcat, [fill(pl.primary[key], n) for (pl, n) in zip(pls, ns)]), keys(pl.primary))
    positional = map(key -> reduce(vcat, [pl.positional[key] for pl in pls]), keys(pl.positional))
    named = map(key -> reduce(vcat, [pl.named[key] for pl in pls]), keys(pl.named))

    return ProcessedLayer(pl; primary, positional, named)
end

function append_processedlayers!(pls_grid, processedlayer::ProcessedLayer, categoricalscales::MultiAesScaleDict{CategoricalScale})
    processedlayer = rescale(processedlayer, categoricalscales)
    tmp_pls_grid = map(_ -> ProcessedLayer[], pls_grid)
    for c in CartesianIndices(shape(processedlayer))
        pl = slice(processedlayer, c)
        rows, cols = compute_grid_positions(categoricalscales, pl.primary)
        for i in rows, j in cols
            push!(tmp_pls_grid[i, j], pl)
        end
    end

    ismergeable = mergeable(processedlayer)
    for (pls, tmp_pls) in zip(pls_grid, tmp_pls_grid)
        isempty(tmp_pls) && continue
        if ismergeable
            push!(pls, concatenate(tmp_pls))
        else
            append!(pls, tmp_pls)
        end
    end
    return pls_grid
end

## Attribute processing

"""
    compute_attributes(pl::ProcessedLayer, categoricalscales, continuousscales_grid, continuousscales)

Process attributes of a `ProcessedLayer`. In particular,
- remove AlgebraOfGraphics-specific layout attributes,
- opt out of Makie cycling mechanism,
- customize behavior of `color` (implementing `alpha` transparency),
- customize behavior of bar `width` (default to one unit when not specified),
- set correct `colorrange`.
Return computed attributes.
"""
function compute_attributes(pl::ProcessedLayer,
                            categoricalscales,
                            continuousscales_grid::AbstractMatrix,
                            continuousscales::MultiAesScaleDict{ContinuousScale})
    plottype, primary, named, attributes = pl.plottype, pl.primary, pl.named, pl.attributes

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

    # avoid automatic bar width computation in Makie (issue #277)
    # sensible default for dates (isse #369)
    # TODO: consider only doing this for categorical scales or dates
    if (plottype <: Union{BarPlot, BoxPlot, CrossBar, Violin}) && !haskey(attrs, :width)
        xscale = get(continuousscales, 1, nothing)
        width = if isnothing(xscale)
            1
        else
            min, max = xscale.extrema
            elementwise_rescale(oneunit(max - min))
        end
        insert!(attrs, :width, width)
    end

    # Match colorrange extrema
    # TODO: might need to change to support temporal color scale
    # TODO: maybe use plottype to infer whether this should be passed or not
    colorscale = get(continuousscales, :color, nothing)
    !isnothing(colorscale) && set!(attrs, :colorrange, colorscale.extrema)

    # remove unnecessary information
    return filterkeys(!in((:col, :row, :layout, :alpha, :group)), attrs)
end
