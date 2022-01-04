"""
    Layer(transformation, data, positional::AbstractVector, named::AbstractDictionary)

Algebraic object encoding a single layer of a visualization. It is composed of a dataset,
positional and named arguments, as well as a transformation to be applied to those.
`Layer` objects can be multiplied, yielding a novel `Layer` object, or added,
yielding a [`AlgebraOfGraphics.Layers`](@ref) object.
"""
Base.@kwdef struct Layer
    transformation::Any=identity
    data::Any=nothing
    positional::Arguments=Arguments()
    named::NamedArguments=NamedArguments()
end

transformation(f) = Layer(transformation=f)

data(df) = Layer(data=columns(df))

mapping(args...; kwargs...) = Layer(positional=collect(Any, args), named=NamedArguments(kwargs))

⨟(f, g) = f === identity ? g : g === identity ? f : g ∘ f

function Base.:*(l1::Layer, l2::Layer)
    transformation = l1.transformation ⨟ l2.transformation
    data = isnothing(l2.data) ? l1.data : l2.data
    positional = vcat(l1.positional, l2.positional)
    named = merge(l1.named, l2.named)
    return Layer(; transformation, data, positional, named)
end

## Format for layer after processing

Base.@kwdef struct ProcessedLayer
    plottype::PlotFunc=Any
    primary::NamedArguments=NamedArguments()
    positional::Arguments=Arguments()
    named::NamedArguments=NamedArguments()
    labels::MixedArguments=MixedArguments()
    attributes::NamedArguments=NamedArguments()
end

function ProcessedLayer(processedlayer::ProcessedLayer; kwargs...)
    nt = (;
        processedlayer.plottype,
        processedlayer.primary,
        processedlayer.positional,
        processedlayer.named,
        processedlayer.labels,
        processedlayer.attributes
    )
    return ProcessedLayer(; merge(nt, values(kwargs))...)
end

"""
    ProcessedLayer(layer::Layer)

Convert `layer` to equivalent processed layer.
"""
function ProcessedLayer(layer::Layer)
    processedlayer = process_mappings(layer)
    grouped_entry = isnothing(layer.data) ? processedlayer : group(processedlayer)
    primary = map(vs -> map(getuniquevalue, vs), grouped_entry.primary)
    return layer.transformation(ProcessedLayer(grouped_entry; primary))
end

unnest(vs::AbstractArray, indices) = map(k -> [el[k] for el in vs], indices)

unnest_arrays(vs) = unnest(vs, keys(first(vs)))
unnest_dictionaries(vs) = unnest(vs, Indices(keys(first(vs))))

function Base.map(f, processedlayer::ProcessedLayer)
    axs = shape(processedlayer)
    outputs = map(CartesianIndices(axs)) do c
        return f(slice(processedlayer.positional, c), slice(processedlayer.named, c))
    end
    positional, named = unnest_arrays(map(first, outputs)), unnest_dictionaries(map(last, outputs))
    return ProcessedLayer(processedlayer; positional, named)
end

## Get scales from a `ProcessedLayer`

uniquevalues(v::ArrayLike) = collect(uniquesorted(vec(v)))

to_label(label::AbstractString) = label
to_label(labels::ArrayLike) = reduce(mergelabels, labels)

function categoricalscales(processedlayer::ProcessedLayer, palettes)
    categoricals = MixedArguments()
    merge!(categoricals, processedlayer.primary)
    merge!(categoricals, Dictionary(filter(iscategoricalcontainer, processedlayer.positional)))
    return map(keys(categoricals), categoricals) do key, val
        palette = key isa Integer ? automatic : get(palettes, key, automatic)
        datavalues = key isa Integer ? mapreduce(uniquevalues, mergesorted, val) : uniquevalues(val)
        label = to_label(get(processedlayer.labels, key, ""))
        return CategoricalScale(datavalues, palette, label)
    end
end

## Machinery to convert a `ProcessedLayer` to a grid of entries

# Determine whether entries from a `ProcessedLayer` should be merged 
function mergeable(processedlayer::ProcessedLayer)
    plottype, primary = processedlayer.plottype, processedlayer.primary
    # merge violins for correct renormalization
    plottype <: Violin && return true
    # merge stacked barplots
    plottype <: BarPlot && haskey(primary, :stack) && return true
    # do not merge by default
    return false
end

function compute_grid_positions(scales, primary=NamedArguments())
    return map((:row, :col), (first, last)) do sym, f
        scale = get(scales, sym, nothing)
        lscale = get(scales, :layout, nothing)
        return if !isnothing(scale)
            rg = Base.OneTo(maximum(plotvalues(scale)))
            haskey(primary, sym) ? fill(primary[sym]) : rg
        elseif !isnothing(lscale)
            rg = Base.OneTo(maximum(f, plotvalues(lscale)))
            haskey(primary, :layout) ? fill(f(primary[:layout])) : rg
        else
            Base.OneTo(1)
        end
    end
end

function rescale(p::ProcessedLayer, scales::MixedArguments)
    primary = map(keys(p.primary), p.primary) do key, values
        scale = get(scales, key, nothing)
        return rescale(values, scale)
    end
    positional = map(keys(p.positional), p.positional) do key, values
        scale = get(scales, key, nothing)
        return rescale.(values, Ref(scale))
    end

    # compute dodging information
    dodge = get(scales, :dodge, nothing)
    attributes = if isa(dodge, CategoricalScale)
        set(p.attributes, :n_dodge => maximum(plotvalues(dodge)))
    else
        p.attributes
    end

    return ProcessedLayer(p; primary, positional, attributes)
end

slice(v, c) = map(el -> getnewindex(el, c), v)

function slice(processedlayer::ProcessedLayer, c)
    labels = slice(processedlayer.labels, c)
    primary = slice(processedlayer.primary, c)
    positional = slice(processedlayer.positional, c)
    named = slice(processedlayer.named, c)
    return ProcessedLayer(processedlayer; labels, primary, positional, named)
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

function append_processedlayers!(pls_grid, processedlayer::ProcessedLayer, categoricalscales::MixedArguments)

    processedlayer = rescale(processedlayer, categoricalscales)
    tmp_pls_grid = map(_ -> ProcessedLayer[], axes_grid)
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
            push!(pls, concatenate(pls))
        else
            append!(pls, tmp_pls)
        end
    end
    return pls_grid
end

# This method works on a "sliced" `ProcessedLayer`
function compute_attributes(pl::ProcessedLayer, continuousscales)
    attrs = NamedArguments()
    merge!(attrs, pl.attributes)
    merge!(attrs, pl.primary)
    merge!(attrs, pl.named)

    # implement alpha transparency
    alpha = get(attrs, :alpha, automatic)
    color = get(attrs, :color, automatic)
    (color !== automatic) && (alpha !== automatic) && (color = (color, alpha))

    # Implement color range
    colorscale = get(continuousscales, :color, nothing)
    colorrange = if (color === automatic) || isnothing(colorscale)
        automatic
    else
        colorscale.extrema
    end

    # opt out of the default cycling mechanism
    cycle = nothing

    merge!(attrs, Dictionary(valid_options(; color, colorrange, cycle)))

    # remove unnecessary information 
    return filterkeys(!in((:col, :row, :layout, :alpha)), attrs)
end

# This method works on a "sliced" `ProcessedLayer`
function compute_entry(pl::ProcessedLayer, continuousscales)
    positional = pl.positional
    named = compute_attributes(pl, continuousscales)
    plottype = Makie.plottype(pl.plottype, positional...)
    return Entry(plottype, positional, named)
end

# Also fix https://github.com/JuliaPlots/AlgebraOfGraphics.jl/issues/288 while at it
function color_key(pl::ProcessedLayer)
    for field in (:primary, :named, :attributes)
        haskey(getproperty(pl, field), :color) && return :color
    end
    zcolor_recipe = pl.plottype <: Union{Heatmap, Contour, Contourf, Surface}
    return zcolor_recipe ? 3 : :color
end

function getlabeledcolorrange(grid)
    zcolor = any(has_zcolor, entries(grid))
    key = zcolor ? 3 : :color
    continuous_color_entries = Iterators.filter(entries(grid)) do entry
        return get(entry, key, nothing) isa AbstractArray{<:Number}
    end
    colorrange = compute_extrema(continuous_color_entries, key)
    # label = compute_label(continuous_color_entries, key)
    label = "" # FIXME: figure out a cleaner way
    return isnothing(colorrange) ? nothing : (label, colorrange)
end

# This method works on a "sliced" `ProcessedLayer`
function continuousscales(processedlayer::ProcessedLayer)
    continuous = MixedArguments()
    merge!(continuous, filter(iscontinuous, processedlayer.named))
    merge!(continuous, Dictionary(filter(iscontinuous, processedlayer.positional)))
    # FIXME: `color` might take from a different scale
    return map(keys(continuous), continuous) do key, val
        extrema = mapreduce(Makie.extrema_nan, extend_extrema, val)
        label = to_label(get(processedlayer.labels, key, ""))
        return ContinuousScale(extrema, label)
    end
end
