struct SmoothAnalysis
    options::Dict{Symbol, Any}
end

SmoothAnalysis(; kwargs...) = SmoothAnalysis(Dict{Symbol, Any}(kwargs))

function (l::SmoothAnalysis)(le::Entry)
    return splitapply(le) do entry
        options = copy(l.options)
        npoints = pop!(l.options, :npoints, 200)
        labels, mappings = map(getlabel, entry.mappings), map(getvalue, entry.mappings)
        x, y = mappings.positional
        min, max = extrema(x)
        min < max || return Entry[]
        model = Loess.loess(Float64.(x), Float64.(y); options...)
        x̂ = collect(range(min, max, length=npoints))
        ŷ = Loess.predict(model, x̂)
        labeled_result = map(Labeled, labels.positional, [x̂, ŷ])
        default_plottype = Lines
        return Entry(
            AbstractPlotting.plottype(entry.plottype, default_plottype),
            Arguments(labeled_result),
            entry.attributes
        )
    end
end

"""
    smooth(span=0.75, degreee=2)

Fit a loess model. `span` is the degree of smoothing, typically in `[0,1]`.
Smaller values result in smaller local context in fitting.
`degree` is the polynomial degree used in the loess model.
"""
smooth(; kwargs...) = Layer((SmoothAnalysis(; kwargs...),))
