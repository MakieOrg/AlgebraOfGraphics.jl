"""
    Layers(layers::Vector{Layer})

Algebraic object encoding a list of [`AlgebraOfGraphics.Layer`](@ref) objects.
`Layers` objects can be added or multiplied, yielding a novel `Layers` object.
"""
struct Layers <: AbstractAlgebraic
    layers::Vector{Layer}
end

Base.convert(::Type{Layers}, l::Layer) = Layers([l])

Base.getindex(layers::Layers, i::Int) = layers.layers[i]
Base.length(layers::Layers) = length(layers.layers)
Base.eltype(::Type{Layers}) = Layer
Base.iterate(layers::Layers, args...) = iterate(layers.layers, args...)

function Base.:+(a::AbstractAlgebraic, a′::AbstractAlgebraic)
    layers::Layers, layers′::Layers = a, a′
    return Layers(vcat(layers.layers, layers′.layers))
end

function Base.:*(a::AbstractAlgebraic, a′::AbstractAlgebraic)
    layers::Layers, layers′::Layers = a, a′
    return Layers([layer * layer′ for layer in layers for layer′ in layers′])
end

"""
    ProcessedLayers(layers::Vector{ProcessedLayer})

Object encoding a list of [`AlgebraOfGraphics.ProcessedLayer`](@ref) objects.
`ProcessedLayers` objects are the output of the processing pipeline and can be
drawn without further processing.
"""
struct ProcessedLayers <: AbstractDrawable
    layers::Vector{ProcessedLayer}
end

function ProcessedLayers(a::AbstractAlgebraic)
    layers::Layers = a
    return ProcessedLayers(map(process, layers))
end

ProcessedLayers(p::ProcessedLayer) = ProcessedLayers([p])
ProcessedLayers(p::ProcessedLayers) = p

function compute_processedlayers_grid(processedlayers, categoricalscales)
    indices = CartesianIndices(compute_grid_positions(categoricalscales))
    pls_grid = map(_ -> ProcessedLayer[], indices)
    for processedlayer in processedlayers
        append_processedlayers!(pls_grid, processedlayer, categoricalscales)
    end
    return pls_grid
end

function compute_entries_continuousscales(pls_grid, categoricalscales, scale_props)
    # Here processed layers in `pls_grid` are "sliced",
    # the categorical scales have been applied, but not
    # the continuous scales

    rescaled_pls_grid = map(_ -> ProcessedLayer[], pls_grid)
    continuousscales_grid = map(_ -> MultiAesScaleDict{ContinuousScale}(), pls_grid)

    for idx in eachindex(pls_grid), pl in pls_grid[idx]
        # Apply continuous transformations
        positional = map(contextfree_rescale, pl.positional)
        named = map(contextfree_rescale, pl.named)
        aes_mapping = aesthetic_mapping(pl)

        continuousscales = AlgebraOfGraphics.continuousscales(pl, scale_props)

        for (key, scale) in pairs(continuousscales)
            aes = aes_mapping[key]
            scaledict = continuousscales_grid[idx]
            if !haskey(scaledict, aes)
                insert!(scaledict, aes, eltype(scaledict)())
            end
            dict = scaledict[aes]
            scale_id = get(pl.scale_mapping, key, nothing)
            if !haskey(dict, scale_id)
                insert!(dict, scale_id, scale)
            else
                dict[scale_id] = mergescales(dict[scale_id], scale)
            end
        end

        # Compute `ProcessedLayer` with rescaled columns
        push!(rescaled_pls_grid[idx], ProcessedLayer(pl; positional, named))
    end

    # Compute merged continuous scales, as it may be needed to use global extrema
    merged_continuousscales = MultiAesScaleDict{ContinuousScale}()
    for multiaesscaledict in continuousscales_grid
        for (aes, scaledict) in pairs(multiaesscaledict)
            existing = if !haskey(merged_continuousscales, aes)
                d = Dictionary{Union{Nothing,Symbol},ContinuousScale}()
                insert!(merged_continuousscales, aes, d)
                d
            else
                merged_continuousscales[aes]
            end
            for (scale_id, scale) in pairs(scaledict)
                if !haskey(existing, scale_id)
                    insert!(existing, scale_id, scale)
                else
                    existing[scale_id] = mergescales(existing[scale_id], scale)
                end
            end
        end
    end

    entries_grid = map(rescaled_pls_grid, CartesianIndices(rescaled_pls_grid)) do processedlayers, idx
        map(processedlayers) do processedlayer
            to_entry(processedlayer, categoricalscales, continuousscales_grid[idx])
        end
    end

    return entries_grid, continuousscales_grid, merged_continuousscales
end

function aesthetic_for_symbol(s::Symbol)
    aessym = Symbol("Aes", s)
    t = isdefined(AlgebraOfGraphics, aessym) ? getproperty(AlgebraOfGraphics, aessym) : nothing
    if !(t isa Type{<:Aesthetic})
        return nothing
    else
        t
    end
end


function compute_scale_properties(processedlayers::Vector{ProcessedLayer}, scales::Scales)

    # allow specifying named scales just by symbol, we can find out what aesthetic that maps
    # to by checking the processed layers
    named_scales = Dictionary{Union{Symbol,Int},Type{<:Aesthetic}}()
    unnamed_aes = Set{Type{<:Aesthetic}}()

    for processedlayer in processedlayers
        aes_mapping = aesthetic_mapping(processedlayer)

        function p!(key)
            if haskey(processedlayer.scale_mapping, key)
                symbol = processedlayer.scale_mapping[key]
                existing_aes = get(named_scales, symbol, nothing)
                aes = aes_mapping[key]
                if existing_aes !== nothing && existing_aes !== aes
                    error("Found two different aesthetics for scale key $key, $aes and $existing_aes")
                end
                if existing_aes === nothing
                    insert!(named_scales, symbol, aes)
                end
            else
                aes = hardcoded_or_mapped_aes(processedlayer, key, aes_mapping)
                push!(unnamed_aes, aes)
            end
        end
        foreach(p!, keys(processedlayer.positional))
        foreach(p!, keys(processedlayer.primary))
        foreach(p!, keys(processedlayer.named))
    end

    dict = MultiAesScaleDict{Any}()

    fn(value::Pair{<:Type,<:Any}) = nothing, value[1], value[2]
    fn(value::Pair{<:Tuple{<:Type,Symbol},<:Any}) = value[1][2], value[1][1], value[2]
    fn(value::Pair{Symbol,<:Any}) = value[1], named_scales[value[1]], value[2]

    for (sym, value) in pairs(scales.dict)
        aes = aesthetic_for_symbol(sym)
        if aes === nothing
            if !haskey(named_scales, sym)
                error("Got scale $(repr(sym)) in scale properties but this key is neither the default name of a scale nor does it reference a named scale. The named scales are $(keys(named_scales))")
            end
            aes = named_scales[sym]
            scale_id = sym
        else
            if aes ∉ unnamed_aes
                error("Got scale properties for $(repr(sym)) but no scale of this kind is mapped.")
            end
            scale_id = nothing
        end
    
        if !haskey(dict, aes)
            insert!(dict, aes, Dictionary{Union{Nothing,Symbol},Any}())
        end
        subdict = dict[aes]
        if haskey(subdict, scale_id)
            error("Found more than one scale for aesthetic $aes and scale id $scale_id")
        end
        insert!(subdict, scale_id, value)
    end

    # layout = Dictionary((layout=wrap,))
    # theme_palettes = map(to_value, Dictionary(Makie.current_default_theme()[:palette]))
    # user_palettes = Dictionary(palettes)
    # return foldl(merge!, (layout, theme_palettes, user_palettes), init=NamedArguments())

    return dict
end

function compute_axes_grid(fig, d::AbstractDrawable, scales::Scales = scales();
                           axis=NamedTuple())

    axes_grid = compute_axes_grid(d, scales; axis)
    sz = size(axes_grid)
    if sz != (1, 1) && fig isa Axis
        msg = "You can only pass an `Axis` to `draw!` if the calculated layout only contains one element. Elements: $(sz)"
        throw(ArgumentError(msg))
    end

    return map(ae -> AxisEntries(ae, fig), axes_grid)
end

hardcoded_mapping(_::Int) = nothing
function hardcoded_mapping(key::Symbol)
    key === :layout ? AesLayout :
    key === :row ? AesRow :
    key === :col ? AesCol :
    key === :group ? AesGroup :
    nothing
end

function hardcoded_or_mapped_aes(processedlayer, key::Union{Int,Symbol}, aes_mapping::AestheticMapping)
    hardcoded = hardcoded_mapping(key)
    hardcoded !== nothing && return hardcoded
    if !haskey(aes_mapping, key)
        throw(ArgumentError("ProcessedLayer with plot type $(processedlayer.plottype) did not have $(repr(key)) in its AestheticMapping. The mapping was $aes_mapping"))
    end
    return aes_mapping[key]
end

function compute_axes_grid(d::AbstractDrawable, scales::Scales = scales(); axis=NamedTuple())

    processedlayers = ProcessedLayers(d).layers

    scale_props = compute_scale_properties(processedlayers, scales)

    categoricalscales = MultiAesScaleDict{CategoricalScale}()
    
    for processedlayer in processedlayers
        aes_mapping = aesthetic_mapping(processedlayer)
        catscales = AlgebraOfGraphics.categoricalscales(processedlayer, scale_props, aes_mapping)

        for (key, scale) in pairs(catscales)
            scale_id = get(processedlayer.scale_mapping, key, nothing)
            aes = hardcoded_or_mapped_aes(processedlayer, key, aes_mapping)
            if !haskey(categoricalscales, aes)
                insert!(categoricalscales, aes, eltype(categoricalscales)())
            end
            scaledict = categoricalscales[aes]
            if !haskey(scaledict, scale_id)
                insert!(scaledict, scale_id, scale)
            else
                scaledict[scale_id] = mergescales(scaledict[scale_id], scale)
            end
        end
    end
    # fit categorical scales (compute plot values using all data values)
    for scaledict in values(categoricalscales)
        map!(fitscale, scaledict, scaledict)
    end

    pls_grid = compute_processedlayers_grid(processedlayers, categoricalscales)
    entries_grid, continuousscales_grid, merged_continuousscales =
        compute_entries_continuousscales(pls_grid, categoricalscales, scale_props)

    indices = CartesianIndices(pls_grid)
    axes_grid = map(indices) do c
        return AxisSpecEntries(
            AxisSpec(c, axis),
            entries_grid[c],
            categoricalscales,
            continuousscales_grid[c],
            pls_grid[c],
        )
    end

    # Axis labels and ticks
    for ae in axes_grid
        ndims = isaxis2d(ae) ? 2 : 3
        aesthetics = [AesX, AesY, AesZ]
        for (aes, var) in zip(aesthetics[1:ndims], (:x, :y, :z)[1:ndims])
            if haskey(ae.categoricalscales, aes)
                catscales = ae.categoricalscales[aes]
                if length(keys(catscales)) != 1 || only(keys(catscales)) !== nothing
                    error("There should only be one $aes, found keys $(keys(catscales))")
                end
                scale = catscales[nothing]
            elseif haskey(ae.continuousscales, aes)
                conscales = ae.continuousscales[aes]
                if length(keys(conscales)) != 1 || only(keys(conscales)) !== nothing
                    error("There should only be one $aes, found keys $(keys(conscales))")
                end
                scale = conscales[nothing]
            else
                continue
            end
            label = getlabel(scale)
            # Use global scales for ticks for now
            # TODO: requires a nicer mechanism that takes into account axis linking
            (scale isa ContinuousScale) && (scale = merged_continuousscales[aes][nothing])
            for (k, v) in pairs((label=label, ticks=ticks(scale)))
                keyword = Symbol(var, k)
                # Only set attribute if it was not present beforehand
                get!(ae.axis.attributes, keyword, v)
            end
        end
    end

    return axes_grid
end

function to_entry(p::ProcessedLayer, categoricalscales::Dictionary, continuousscales::Dictionary)
    entry = to_entry(p.plottype, p, categoricalscales, continuousscales)
    insert!(entry.named, :cycle, nothing)
    for key in (:group, :layout, :row, :col)
        if haskey(entry.named, key)
            delete!(entry.named, key)
        end
    end
    return entry
end

function to_entry(P, p::ProcessedLayer, categoricalscales::Dictionary, continuousscales::Dictionary)
    aes_mapping = aesthetic_mapping(p)
    scale_mapping = p.scale_mapping

    positional = map(eachindex(p.positional)) do i
        full_rescale(p.positional[i], i, aes_mapping, scale_mapping, categoricalscales, continuousscales)
    end
    named = map(pairs(p.named)) do (key, value)
        full_rescale(value, key, aes_mapping, scale_mapping, categoricalscales, continuousscales)
    end
    primary = map(pairs(p.primary)) do (key, values)
        if key in (:group, :layout, :col, :row)
            return values
        end
        # seems that there can be vectors here for concatenated layers, but for unconcatenated these should
        # be scalars
        if values isa AbstractVector
            full_rescale(values, key, aes_mapping, scale_mapping, categoricalscales, continuousscales)
        else
            values = [values]
            rescaled = full_rescale(values, key, aes_mapping, scale_mapping, categoricalscales, continuousscales)
            rescaled[]
        end
    end

    Entry(P, positional, merge(p.attributes, named, primary))
end

function get_scale(key, aes_mapping, scale_mapping, categoricalscales, continuousscales)
    aes = aes_mapping[key]
    scale_id = get(scale_mapping, key, nothing)
    scale = if haskey(categoricalscales, aes) && haskey(categoricalscales[aes], scale_id)
        categoricalscales[aes][scale_id]
    elseif haskey(continuousscales, aes) && haskey(continuousscales[aes], scale_id)
        continuousscales[aes][scale_id]
    else
        # this should mean that the data were passed `verbatim` so there is no scale
        nothing
    end
    return scale
end

function full_rescale(data, key, aes_mapping, scale_mapping, categoricalscales, continuousscales)
    scale = get_scale(key, aes_mapping, scale_mapping, categoricalscales, continuousscales)
    scale === nothing && return data # verbatim data
    full_rescale(data, aes_mapping[key], scale)
end

function default_colormap()
    Makie.current_default_theme().colormap[]
end

full_rescale(data, aes, scale::CategoricalScale) = rescale(data, scale)

function full_rescale(data, aes::Type{AesColor}, scale::ContinuousScale)
    props = scale.props.aesprops::AesColorContinuousProps
    colormap = Makie.to_colormap(@something(props.colormap, default_colormap()))
    colorrange = Makie.Vec2(@something(props.colorrange, scale.extrema))
    lowclip = Makie.to_color(@something(props.lowclip, first(colormap)))
    highclip = Makie.to_color(@something(props.highclip, last(colormap)))
    nan_color = Makie.to_color(@something(props.nan_color, RGBAf(0, 0, 0, 0)))
    Makie.numbers_to_colors(collect(data), colormap, identity, colorrange, lowclip, highclip, nan_color)
end

function full_rescale(data, aes::Type{AesMarkerSize}, scale::ContinuousScale)
    props = scale.props.aesprops::AesMarkerSizeContinuousProps
    values_to_markersizes(data, props.sizerange, scale.extrema)
end

full_rescale(data, aes::Type{<:Union{AesContourColor,AesABIntercept,AesABSlope}}, scale::ContinuousScale) = data # passthrough, this aes is a mock one anyway

function values_to_markersizes(data, sizerange, extrema)
    # we scale the area linearly with the values
    areamin, areamax = sizerange .^ 2
    areawidth = areamax - areamin
    scalemin, scalemax = extrema
    scalewidth = scalemax - scalemin
    map(data) do value
        fraction = ((value - scalemin) / scalewidth)
        markerarea = areamin + fraction * areawidth
        markersize = sqrt(markerarea)
        return markersize
    end
end

function full_rescale(data, aes::Type{<:Union{AesX,AesY,AesZ,AesDeltaX,AesDeltaY,AesDeltaZ}}, scale::ContinuousScale)
    return data
end

function numerical_rescale(values, key, aes_mapping, scale_mapping, categoricalscales, continuousscales)
    scale = get_scale(key, aes_mapping, scale_mapping, categoricalscales, continuousscales)
    
    if scale isa ContinuousScale
        return values, scale
    elseif scale === nothing
        error("Cannot do numerical rescale on verbatim data for $(repr(key))")
    end
    indices = Int.(indexin(values, datavalues(scale)))
    return indices, scale
end

function to_entry(P::Type{Heatmap}, p::ProcessedLayer, categoricalscales::Dictionary, continuousscales::Dictionary)
    aes_mapping = aesthetic_mapping(p)
    scale_mapping = p.scale_mapping

    z_indices, scale = numerical_rescale(p.positional[3], 3, aes_mapping, scale_mapping, categoricalscales, continuousscales)

    if scale isa CategoricalScale
        colormap = plotvalues(scale)
        color_attributes = dictionary([
            :colormap => colormap,
            :colorrange => (1, length(colormap)),
            :nan_color => :transparent,
        ])
    else
        color_attributes = dictionary([
            :colormap => @something(scale.props.aesprops.colormap, default_colormap()),
            :colorrange => @something(scale.props.aesprops.colorrange, scale.extrema),
            :nan_color => @something(scale.props.aesprops.nan_color, :transparent),
            :lowclip => @something(scale.props.aesprops.lowclip, Makie.automatic),
            :highclip => @something(scale.props.aesprops.highclip, Makie.automatic),
        ])
    end

    positional = Any[
        full_rescale(p.positional[1], 1, aes_mapping, scale_mapping, categoricalscales, continuousscales),
        full_rescale(p.positional[2], 2, aes_mapping, scale_mapping, categoricalscales, continuousscales),
        z_indices,
    ]
    
    Entry(P, positional, merge(p.named, p.primary, p.attributes, color_attributes))
end

function Base.show(io::IO, layers::Layers; indent = 0)
    ind = "  " ^ indent
    printstyled(io, ind, "Layers", bold = true)
    println(io, ind, " with $(length(layers.layers)) elements:")
    for (i, layer) in enumerate(layers)
        show(io, layer; indent = indent + 1, index = i)
    end
end