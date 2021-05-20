struct SmoothAnalysis
    options::Dict{Symbol, Any}
end

SmoothAnalysis(; kwargs...) = SmoothAnalysis(Dict{Symbol, Any}(kwargs))

function (l::SmoothAnalysis)(le::Entry)
    return splitapply(le) do entry
        options = copy(l.options)
        npoints = pop!(options, :npoints, 200)
        x, y = entry.positional
        min, max = extrema(x)
        min < max || return Entry[]
        model = Loess.loess(Float64.(x), Float64.(y); options...)
        x̂ = collect(range(min, max, length=npoints))
        ŷ = Loess.predict(model, x̂)
        positional, named = (x̂, ŷ), (;)
        plottype = Makie.plottype(entry.plottype, Lines)
        return Entry(entry; plottype, positional, named)
    end
end

"""
    smooth(span=0.75, degreee=2)

Fit a loess model. `span` is the degree of smoothing, typically in `[0,1]`.
Smaller values result in smaller local context in fitting.
`degree` is the polynomial degree used in the loess model.
"""
smooth(; kwargs...) = Layer((SmoothAnalysis(; kwargs...),))
