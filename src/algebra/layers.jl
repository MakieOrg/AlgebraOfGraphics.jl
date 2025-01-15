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
    processedlayers_array = map(process, layers)
    return ProcessedLayers(reduce(vcat, [processedlayer.layers for processedlayer in processedlayers_array]))
end

"""
    ProcessedLayers(layer::Layer)

Output of processing a `layer`. Each `ProcessedLayer` encodes
- plot type,
- grouping arguments,
- positional and named arguments for the plot,
- labeling information,
- visual attributes.
"""
ProcessedLayers(layer::Layer) = process(layer)

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
            to_entry(processedlayer, categoricalscales, merged_continuousscales)
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
    key === :dodge_x ? AesDodgeX :
    key === :dodge_y ? AesDodgeY :
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

    set_dodge_width_default!(categoricalscales, processedlayers)

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
            # Determine which scales of type AesX, AesY, AesZ have actually been
            # used by the processed layers in the current AxisSpecEntries.
            # We can allow the usage of multiple of these scales in a facetted figure
            # as long as each facet only uses one kind. That makes it possible to
            # create facet plots in which adjacent facets don't share X and Y scales at all,
            # like completely disjoint categories or categorical next to continuous data.
            used_scale_ids = get_used_scale_ids(ae, aes)
            if length(used_scale_ids) > 1
                error("Found more than two scales of type $aes used in one AxesSpecGrid, this is currently not supported. Scales were: $used_scale_ids")
            end
            used_scale_id = only(used_scale_ids)
            if haskey(ae.categoricalscales, aes) && haskey(ae.categoricalscales[aes], used_scale_id)
                catscales = ae.categoricalscales[aes]
                scale = catscales[used_scale_id]
            elseif haskey(ae.continuousscales, aes)
                conscales = ae.continuousscales[aes]
                scale = conscales[used_scale_id]
            else
                continue
            end
            label = getlabel(scale)
            # Use global scales for ticks for now
            # TODO: requires a nicer mechanism that takes into account axis linking
            (scale isa ContinuousScale) && (scale = merged_continuousscales[aes][used_scale_id])
            for (k, v) in pairs((label=label, ticks=ticks(scale)))
                keyword = Symbol(var, k)
                # Only set attribute if it was not present beforehand
                get!(ae.axis.attributes, keyword, v)
            end
        end
    end

    return axes_grid
end

function get_used_scale_ids(ae::AxisSpecEntries, aestype)
    scale_ids = Set{Union{Nothing,Symbol}}()
    for p in ae.processedlayers
        aes_map = aesthetic_mapping(p)
        for (key, value) in pairs(aes_map)
            if value === aestype
                scale_id = get(p.scale_mapping, key, nothing)
                push!(scale_ids, scale_id)
            end
        end
    end
    return scale_ids
end

function to_entry(p::ProcessedLayer, categoricalscales::Dictionary, continuousscales::Dictionary)
    entry = to_entry(p.plottype, p, categoricalscales, continuousscales)
    insert!(entry.named, :cycle, nothing)
    for key in (:group, :layout, :row, :col, :dodge_x, :dodge_y, :legend)
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
        if key in (:group, :layout, :col, :row, :dodge_x, :dodge_y)
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

    for dodge in (:dodge_x, :dodge_y)
        dodge_aes = dodge === :dodge_x ? AesDodgeX : AesDodgeY
        axis_aes = dodge === :dodge_x ? AesX : AesY
        if haskey(primary, dodge)
            positional = map(eachindex(positional)) do i
                aes_mapping[i] == axis_aes || return positional[i]
                return compute_dodge(positional[i], dodge, primary[dodge], scale_mapping, categoricalscales, dodge_aes)
            end
            named = map(pairs(named)) do (key, values)
                aes_mapping[key] == axis_aes || return values
                return compute_dodge(values, dodge, primary[dodge], scale_mapping, categoricalscales, dodge_aes)
            end
        end
    end

    Entry(P, positional, merge(p.attributes, named, primary))
end

function get_scale(key, aes, scale_mapping, categoricalscales, continuousscales)
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
    hc_aes = hardcoded_mapping(key)
    aes = hc_aes === nothing ? aes_mapping[key] : hc_aes
    scale = get_scale(key, aes, scale_mapping, categoricalscales, continuousscales)
    scale === nothing && return data # verbatim data
    return full_rescale(data, aes, scale)
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
    Makie.numbers_to_colors(
        Makie.convert_single_argument(collect(data)),
        colormap,
        identity,
        colorrange,
        lowclip,
        highclip,
        nan_color
    )
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
    aes = aes_mapping[key]
    scale = get_scale(key, aes, scale_mapping, categoricalscales, continuousscales)
    
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
    println(io, " with $(length(layers.layers)) elements:")
    for (i, layer) in enumerate(layers)
        show(io, layer; indent = indent + 1, index = i)
    end
end

scale_setting_name(scale_id, aes::Type{<:Aesthetic}) = scale_id !== nothing ? scale_id : string(nameof(aes))[4:end]

function compute_dodge(data, key::Symbol, dodgevalues, scale_mapping, categoricalscales, dodge_aes)
    scale_id = get(scale_mapping, key, nothing)
    scale = categoricalscales[dodge_aes][scale_id]

    indices = rescale(dodgevalues isa AbstractArray ? dodgevalues : [dodgevalues], scale)
    
    props = scale.props.aesprops
    n = length(datavalues(scale))
    n == 1 && return data
    width = if props.width !== nothing
        props.width
    else
        error("Tried to compute dodging offsets but the `width` attribute of the dodging scale was `nothing`. This happens if only plots participate in the dodge that do not have an inherent width. For example, a scatter plot has no width but a barplot does. You can pass a width manually like `draw(..., scales($(scale_setting_name(scale_id, dodge_aes)) = (; width = 0.6))`.")
    end
    # scale to 0-1, center around 0, shrink to width (like centers of bins that added together result in width)
    offsets = ((indices .- 1) ./ (n - 1) .- 0.5) .* width * (n-1) / n
    return data .+ offsets
end

function set_dodge_width_default!(categoricalscales, processedlayers)
    for dodgetype in (AesDodgeX, AesDodgeY)
        haskey(categoricalscales, dodgetype) || continue
        scales = categoricalscales[dodgetype]
        for (scale_id, scale) in pairs(scales)
            props = scale.props.aesprops
            props.width === nothing || continue
            n_dodge = length(datavalues(scale))
            width::Union{Float64,Nothing} = nothing
            for p in processedlayers
                _width = determine_dodge_width(p, dodgetype, n_dodge)
                if width === nothing
                    width = _width
                elseif _width !== nothing
                    width == _width || error("Determined at least two different auto-widths for the `$(scale_setting_name(scale_id, dodgetype))` scale, $width and $_width. AlgebraOfGraphics tried to determine dodge with because you specified that a width-less plot type such as Scatter or Errorbars should be dodged. Some plot types like Barplot may have an inherent width for dodging which can often be auto-determined, so AlgebraOfGraphics looked for such widths in all other plot types in this plot. Because multiple such widths were detected, AlgebraOfGraphics gives up and you have to specify the dodge width for your width-less plots manually, like `draw(..., scales($(scale_setting_name(scale_id, dodgetype)) = (; width = 0.5))`")
                end
            end
            if width !== nothing
                scales[scale_id] = update_width(scale, width)
            end
        end
    end
    return
end

function update_width(scale::CategoricalScale, width)
    return Accessors.@set scale.props.aesprops.width = width
end

function determine_dodge_width(p::ProcessedLayer, dodgetype, n_dodge)::Union{Float64,Nothing}
    aes_mapping = aesthetic_mapping(p)
    for key in keys(p.primary)
        aes = hardcoded_or_mapped_aes(p, key, aes_mapping)
        # check that processedlayer participates in this dodge
        aes == dodgetype || continue
        return determine_dodge_width(p.plottype, p, aes_mapping, dodgetype, n_dodge)
    end
    return nothing
end

determine_dodge_width(anyplot, p::ProcessedLayer, aes_mapping, dodgetype, n_dodge) = nothing

attribute_or_plot_default(plottype, attributes, key) = get(attributes, key) do
    to_value(Makie.default_theme(nothing, plottype)[key])
end

function determine_dodge_width(T::Type{BarPlot}, p::ProcessedLayer, aes_mapping, dodgetype, n_dodge)
    width = attribute_or_plot_default(T, p.attributes, :width)
    gap = attribute_or_plot_default(T, p.attributes, :gap)
    dodge_gap = attribute_or_plot_default(T, p.attributes, :dodge_gap)
    dodge_width = Makie.scale_width(dodge_gap, n_dodge)
    if width === Makie.automatic
        corresponding_aes(::Type{AesDodgeX}) = AesX
        corresponding_aes(::Type{AesDodgeY}) = AesY
        if length(p.positional) == 1 # Makie goes 1:n automatically if only one arg is given
            w = 1
        end
        for key in eachindex(p.positional)
            if aes_mapping[key] === corresponding_aes(dodgetype)
                w = resolution(p.positional[key])
            end
        end
    elseif width isa Real
        w = width
    end
    w_with_gap = w * (1 - gap)
    return n_dodge * w_with_gap * (dodge_width + dodge_gap)
end

function resolution(vec_of_vecs)::Float64
    iscategoricalcontainer(vec_of_vecs) && return 1.0
    s = unique(sort(reduce(vcat, vec_of_vecs)))
    return minimum((b - a for (a, b) in @views zip((s[begin:end-1]), s[begin+1:end])))
end
