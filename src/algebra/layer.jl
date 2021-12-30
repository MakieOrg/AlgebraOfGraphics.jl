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

function unnest(v::AbstractArray)
    return map_pairs(first(v)) do (k, _)
        return [el[k] for el in v]
    end
end

function Base.map(f, processedlayer::ProcessedLayer)
    axs = shape(processedlayer)
    outputs = map(CartesianIndices(axs)) do c
        p = map(v -> getnewindex(v, c), processedlayer.positional)
        n = map(v -> getnewindex(v, c), processedlayer.named)
        return f(p, n)
    end
    positional = unnest(map(first, outputs))
    named = unnest(map(last, outputs))
    return ProcessedLayer(processedlayer; positional, named)
end

## Get scales from a `ProcessedLayer`

uniquevalues(v::ArrayLike) = collect(uniquesorted(vec(v)))

to_label(label::AbstractString) = label
to_label(labels::ArrayLike) = reduce(mergelabels, labels)

function categoricalscales(processedlayer::ProcessedLayer, palettes)
    cs = MixedArguments()
    for (key, val) in pairs(processedlayer.primary)
        palette = get(palettes, key, automatic)
        label = to_label(get(processedlayer.labels, key, ""))
        insert!(cs, key, CategoricalScale(uniquevalues(val), palette, label))
    end
    for (key, val) in pairs(processedlayer.positional)
        hascategoricalentry(val) || continue
        palette = automatic
        label = to_label(get(processedlayer.labels, key, ""))
        insert!(cs, key, CategoricalScale(mapreduce(uniquevalues, mergesorted, val), palette, label))
    end
    return cs
end

## Machinery to convert a `ProcessedLayer` to a grid of entries

# Determine whether entries from a `ProcessedLayer` should be merged 
# Useful to recombine stacked barplots, but may have other applications
function mergeable(processedlayer::ProcessedLayer)
    return processedlayer.plottype <: BarPlot && haskey(processedlayer.primary, :stack)
end

function compute_grid_positions(scales, primary=NamedArguments())
    return map((:row, :col), (first, last)) do sym, f
        scale = get(scales, sym, nothing)
        lscale = get(scales, :layout, nothing)
        return if !isnothing(scale)
            rg = Base.OneTo(maximum(plotvalues(scale)))
            haskey(primary, sym) ? rescale(fill(primary[sym]), scale) : rg
        elseif !isnothing(lscale)
            rg = Base.OneTo(maximum(f, plotvalues(lscale)))
            haskey(primary, :layout) ? map(f, rescale(fill(primary[:layout]), lscale)) : rg
        else
            Base.OneTo(1)
        end
    end
end

function compute_attributes(attributes, primary, named, scales)
    attrs = NamedArguments()
    merge!(attrs, attributes)
    merge!(attrs, primary)
    merge!(attrs, named)

    # implement alpha transparency
    alpha = get(attrs, :alpha, nothing)
    color = get(attrs, :color, nothing)
    if !isnothing(color)
        set!(attrs, :color, isnothing(alpha) ? color : (color, alpha))
    end

    # opt out of the default cycling mechanism
    set!(attrs, :cycle, nothing)

    # compute dodging information
    dodge = get(scales, :dodge, nothing)
    isa(dodge, CategoricalScale) && set!(attrs, :n_dodge, maximum(plotvalues(dodge)))

    # remove unnecessary information
    return unset(attrs, :col, :row, :layout, :alpha)
end

function rescale(p::ProcessedLayer, c::CartesianIndex, field::Symbol, scales)
    return map_pairs(getproperty(p, field)) do (key, values)
        value = getnewindex(values, c)
        isprimary = field == :primary
        input = isprimary ? fill(value) : value
        output = rescale(input, get(scales, key, nothing))
        return isprimary ? only(output) : output
    end
end

function compute_entries_grid!(processedlayer::ProcessedLayer, labels_grid, scales)
    ismergeable = mergeable(processedlayer)
    entries_grid = map(_ -> Entry[], labels_grid)
    for c in CartesianIndices(shape(processedlayer))
        labels = map(l -> getnewindex(l, c), processedlayer.labels)
        primary, positional, named = map((:primary, :positional, :named)) do field
            return rescale(processedlayer, c, field, scales)
        end
        rows, cols = compute_grid_positions(scales, primary)
        if ismergeable
            N = length(first(positional))
            map!(v -> fill(v, N), primary, primary)
        end
        plottype, attributes = processedlayer.plottype, processedlayer.attributes
        attrs = compute_attributes(attributes, primary, named, scales)
        # plottype = Makie.plottype(entry.plottype, positional...)
        entry = Entry(plottype, positional, attrs)
        for i in rows, j in cols
            entries = entries_grid[i, j]
            if ismergeable
                isempty(entries) ? push!(entries, copy_content(entry)) : append!(only(entries), entry)
            else
                push!(entries, entry)
            end
            mergewith!(mergelabels, labels_grid[i, j], labels)
        end
    end
    return entries_grid
end
