Base.@kwdef struct SmoothAnalysis
    npoints::Int=200
    span::Float64=0.75
    degree::Int=2
end

function (l::SmoothAnalysis)(le::Entry)
    entry = map(le) do p, _
        x, y = p
        min, max = extrema(x)
        model = Loess.loess(Float64.(x), Float64.(y); l.span, l.degree)
        x̂ = collect(range(min, max, length=l.npoints))
        ŷ = Loess.predict(model, x̂)
        return (x̂, ŷ), (;)
    end
    plottype = Makie.plottype(entry.plottype, Lines)
    return Entry(entry; plottype)
end

"""
    smooth(; span=0.75, degree=2, npoints=200)

Fit a loess model. `span` is the degree of smoothing, typically in `[0,1]`.
Smaller values result in smaller local context in fitting.
`degree` is the polynomial degree used in the loess model.
`npoints` is the number of points used by Makie to draw the line
"""
smooth(; options...) = transformation(SmoothAnalysis(; options...))
