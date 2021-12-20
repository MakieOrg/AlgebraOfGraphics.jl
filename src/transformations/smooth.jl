struct SmoothAnalysis
    options::NamedArguments
end

SmoothAnalysis(; kwargs...) = SmoothAnalysis(NamedArguments(kwargs))

extract_npoints(; npoints=200, kwargs...) = npoints, kwargs

function (l::SmoothAnalysis)(le::Entry)
    npoints, kwargs = extract_npoints(; pairs(l.options)...)
    entry = map(le) do p, _
        x, y = p
        min, max = extrema(x)
        model = Loess.loess(Float64.(x), Float64.(y); kwargs...)
        x̂ = collect(range(min, max, length=npoints))
        ŷ = Loess.predict(model, x̂)
        return (x̂, ŷ), (;)
    end
    plottype = Makie.plottype(entry.plottype, Lines)
    return Entry(entry; plottype)
end

"""
    smooth(span=0.75, degree=2)

Fit a loess model. `span` is the degree of smoothing, typically in `[0,1]`.
Smaller values result in smaller local context in fitting.
`degree` is the polynomial degree used in the loess model.
"""
smooth(; kwargs...) = transformation(SmoothAnalysis(; kwargs...))
