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
    merge!(categoricals, Dictionary(filter(hascategoricalentry, processedlayer.positional)))
    return map(keys(categoricals), categoricals) do key, val
        palette = key isa Integer ? automatic : get(palettes, key, automatic)
        datavalues = key isa Integer ? mapreduce(uniquevalues, mergesorted, val) : uniquevalues(val)
        label = to_label(get(processedlayer.labels, key, ""))
        return CategoricalScale(datavalues, palette, label)
    end
end

# # FIXME: find out cleaner fix for continuous scales
# Also fix https://github.com/JuliaPlots/AlgebraOfGraphics.jl/issues/288 while at it
# function continuouslabels(processedlayer::ProcessedLayer)
#     labels = MixedArguments()
#     for key in keys(processedlayer.named)
#         label = to_label(get(processedlayer.labels, key, ""))
#         insert!(labels, key, label)
#     end
#     for (key, val) in pairs(processedlayer.positional)
#         hascategoricalentry(val) && continue
#         label = to_label(get(processedlayer.labels, key, ""))
#         insert!(labels, key, label)
#     end
#     return labels
# end

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
            haskey(primary, sym) ? fill(primary[sym]) : rg
        elseif !isnothing(lscale)
            rg = Base.OneTo(maximum(f, plotvalues(lscale)))
            haskey(primary, :layout) ? fill(f(primary[:layout])) : rg
        else
            Base.OneTo(1)
        end
    end
end

function rescale(p::ProcessedLayer, field::Symbol, scales)
    isprimary = field == :primary
    container = getproperty(p, field)
    return map(keys(container), container) do key, values
        scale = get(scales, key, nothing)
        return isprimary ? rescale(values, scale) : rescale.(values, Ref(scale))
    end
end

function rescale(p::ProcessedLayer, scales::MixedArguments)
    primary, positional, named = map((:primary, :positional, :named)) do field
        return rescale(p, field, scales)
    end

    # compute dodging information
    dodge = get(scales, :dodge, nothing)
    attributes = if isa(dodge, CategoricalScale)
        set(p.attributes, :n_dodge => maximum(plotvalues(dodge)))
    else
        p.attributes
    end

    return ProcessedLayer(p; primary, positional, named, attributes)
end

slice(v, c) = map(el -> getnewindex(el, c), v)

function slice(processedlayer::ProcessedLayer, c)
    labels = slice(processedlayer.labels, c)
    primary = slice(processedlayer.primary, c)
    positional = slice(processedlayer.positional, c)
    named = slice(processedlayer.named, c)
    return ProcessedLayer(processedlayer; labels, primary, positional, named)
end

# This method works on a "sliced" `ProcessedLayer`
function compute_attributes(pl::ProcessedLayer)
    attrs = NamedArguments()
    merge!(attrs, pl.attributes)
    merge!(attrs, pl.primary)
    merge!(attrs, pl.named)

    # implement alpha transparency
    alpha = get(attrs, :alpha, nothing)
    color = get(attrs, :color, nothing)
    if !isnothing(color)
        set!(attrs, :color, isnothing(alpha) ? color : (color, alpha))
    end

    # opt out of the default cycling mechanism
    set!(attrs, :cycle, nothing)

    # remove unnecessary information 
    return filterkeys(!in((:col, :row, :layout, :alpha)), attrs)
end

# This method works on a "sliced" `ProcessedLayer`
function compute_entry(pl::ProcessedLayer)
    plottype, positional = pl.plottype, pl.positional
    named = compute_attributes(pl)
    # plottype = Makie.plottype(plottype, pl.positional...)
    return Entry(plottype, positional, named)
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

function compute_entries_grid!(processedlayer::ProcessedLayer, labels_grid, scales::MixedArguments)
    processedlayer = rescale(processedlayer, scales)
    ismergeable = mergeable(processedlayer)

    pls_grid = map(_ -> ProcessedLayer[], labels_grid)
    for c in CartesianIndices(shape(processedlayer))
        pl = slice(processedlayer, c)
        rows, cols = compute_grid_positions(scales, pl.primary)
        for i in rows, j in cols
            push!(pls_grid[i, j], pl)
            mergewith!(mergelabels, labels_grid[i, j], pl.labels) #FIXME: should have been computed already
        end
    end

    return map(pls_grid) do pls
        isempty(pls) && return Entry[]
        return ismergeable ? [compute_entry(concatenate(pls))] : map(compute_entry, pls)
    end
end
