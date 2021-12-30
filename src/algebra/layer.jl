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

function Base.get(processedlayer::ProcessedLayer, key::Int, default)
    return key in keys(processedlayer.positional) ? processedlayer.positional[key] : default
end

function Base.get(processedlayer::ProcessedLayer, key::Symbol, default)
    return get(processedlayer.named, key, default)
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

ProcessedLayer(layer::Layer) = layer.transformation(to_processedlayer(layer))

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
