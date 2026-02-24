Base.@kwdef struct SmoothAnalysis
    npoints::Int = 200
    span::Float64 = 0.75
    degree::Int = 2
    interval::Union{Symbol, Nothing} = :confidence
    level::Float64 = 0.95
end

function (l::SmoothAnalysis)(input::ProcessedLayer)
    if isnothing(l.interval)
        output = map(input) do p, _
            x, y = p
            xn = to_numerical(x)
            model = Loess.loess(xn, y; l.span, l.degree)
            x̂n = collect(range(extrema(xn)..., length = l.npoints))
            ŷ = Loess.predict(model, x̂n)
            x̂ = from_numerical(x̂n, x)
            return (x̂, ŷ), (;)
        end
        plottype = Makie.plottype(output.plottype, Lines)
        return ProcessedLayer(output; plottype, label = :prediction)
    else
        output = map(input) do p, _
            x, y = p
            xn = to_numerical(x)
            model = Loess.loess(xn, y; l.span, l.degree)
            x̂n = collect(range(extrema(xn)..., length = l.npoints))
            pred = Loess.predict(model, x̂n; interval = l.interval, level = l.level)
            ŷ = pred.predictions
            lower = pred.lower
            upper = pred.upper
            x̂ = from_numerical(x̂n, x)
            return (x̂, ŷ, x̂, lower, upper), (;)
        end

        lineslayer = ProcessedLayer(
            map(output) do p, n
                x̂, ŷ, x, lower, upper = p
                (x̂, ŷ), (;)
            end, plottype = Lines, label = :prediction
        )

        bandlayer = ProcessedLayer(
            map(output) do p, n
                x̂, ŷ, x, lower, upper = p
                (x, lower, upper), (;)
            end, plottype = Band, label = :ci, attributes = dictionary([:alpha => 0.15])
        )

        return ProcessedLayers([bandlayer, lineslayer])
    end
end

"""
    smooth(; span=0.75, degree=2, interval=:confidence, level=0.95, npoints=200)

Fit a loess model. `span` is the degree of smoothing, typically in `[0,1]`.
Smaller values result in smaller local context in fitting.
`degree` is the polynomial degree used in the loess model.
Use `interval` to specify what type of interval the shaded band should represent,
for a given coverage `level` (the default `0.95` equates `alpha = 0.05`).
Valid values of `interval` are `:confidence` (the default), to delimit the uncertainty 
of the predicted relationship. Use `interval = nothing` to only compute the line fit, 
without any uncertainty estimate.
`npoints` is the number of points used by Makie to draw the line and shaded band.

This transformation creates two `ProcessedLayer`s labelled `:prediction` and `:ci`, which can be styled separately with `[subvisual](@ref)`.
"""
smooth(; options...) = transformation(SmoothAnalysis(; options...))
