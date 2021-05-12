struct Layers
    layers::Vector{Layer}
end

Base.convert(::Type{Layers}, s::Layer) = Layers([s])
Base.convert(::Type{Layers}, s::Layers) = s

Base.getindex(v::Layers, i::Int) = v.layers[i]
Base.length(v::Layers) = length(v.layers)
Base.eltype(::Type{Layers}) = Layer
Base.iterate(v::Layers, args...) = iterate(v.layers, args...)

const OneOrMoreLayers = Union{Layers, Layer}

function Base.:+(s1::OneOrMoreLayers, s2::OneOrMoreLayers)
    l1::Layers, l2::Layers = s1, s2
    return Layers(vcat(l1.layers, l2.layers))
end

function Base.:*(s1::OneOrMoreLayers, s2::OneOrMoreLayers)
    l1::Layers, l2::Layers = s1, s2
    return Layers([el1 * el2 for el1 in l1 for el2 in l2])
end

summary(v) = iscontinuous(v) ? extrema(v) : collect(uniquesorted(vec(v)))
mergesummaries(s1::AbstractVector, s2::AbstractVector) = mergesorted(s1, s2)
mergesummaries(s1::Tuple, s2::Tuple) = extend_extrema(s1, s2)

mergelabels(a, b) = a

function entries_scales_labels(s::OneOrMoreLayers, palettes=NamedTuple())
    layers::Layers = s
    summaries = ArgDict()
    labels = ArgDict()
    entries = Entry[]
    for labeledentries in process_transformations(layers)
        for le in labeledentries
            positional, named = map((le.positional, le.named)) do tup
                local values, labels = map(getvalue, tup), map(getlabel, tup)
                local summaries = map(summary, values)
                return (; values, labels, summaries)
            end
            push!(entries, Entry(le.plottype, positional.values, named.values, le.attributes))
            mergewith!(
                mergesummaries,
                summaries,
                pairs(positional.summaries),
                pairs(named.summaries)
            )
            mergewith!(
                mergelabels,
                labels,
                pairs(positional.labels),
                pairs(named.labels)
            )
        end
    end
    palettes = merge(default_palettes(), palettes)
    scales = default_scales(summaries, palettes)
    return entries, scales, labels
end

function AbstractPlotting.plot!(fig, s::OneOrMoreLayers;
                                axis=NamedTuple(), palettes=NamedTuple())
    return plot!(fig, Entries(s, palettes); axis)
end

function AbstractPlotting.plot(s::OneOrMoreLayers;
                               axis=NamedTuple(), figure=NamedTuple(), palettes=NamedTuple())
    return plot(Entries(s, palettes); axis, figure)
end

# Convenience function, which may become superfluous if `plot` also calls `facet!`
function draw(s::OneOrMoreLayers;
              axis = NamedTuple(), figure=NamedTuple(), palettes=NamedTuple())
    fg = plot(s; axis, figure, palettes)
    facet!(fg)
    Legend(fg)
    resizetocontent!(fg)
    return fg
end

function draw!(fig, s::OneOrMoreLayers;
               axis=NamedTuple(), palettes=NamedTuple())
    ag = plot!(fig, s; axis, palettes)
    facet!(fig, ag)
    return ag
end