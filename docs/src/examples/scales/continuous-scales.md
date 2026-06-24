# Continuous scales

````@example continuous_scales
using AlgebraOfGraphics, CairoMakie

x = 1:100
y = @. sqrt(x) + 20x + 100
df = (; x, y)
plt = data(df) *
    mapping(
        :x,
        :y => log => "√x + 20x + 100 (log scale)",
    ) * visual(Lines)
draw(plt)
````

````@example continuous_scales
x = 1:100
y = @. sqrt(x) + 20x + 100
df = (; x, y)
plt = data(df) *
    mapping(
        :x,
        :y => "√x + 20x + 100 (log scale)",
    ) * visual(Lines)
draw(plt, axis=(yscale=log,))
````

````@example continuous_scales
x = 0:100
y = @. 0.01 + x/1000
df = (; x, y)
plt = data(df) *
    mapping(
        :x,
        :y => "y",
    ) * visual(Lines)
fg = draw(plt, axis=(yscale=log,))
````

## Scale transforms and analyses

There are two ways to place data on a transformed (e.g. logarithmic) axis, and they differ in how [analyses](@ref "Analyses") behave.

Passing `axis = (; yscale = log10)` is a display-only transform: it is a Makie axis attribute that warps the coordinates when drawing, after every analysis has already run in data space. An analysis such as `linear` or `smooth` is therefore fit on the untransformed values, which is usually not what you want on a log axis.

Passing `scales(Y = (; scale = log10))` instead sets the scale on the `Y` aesthetic. Analyses then fit in the transformed space and back-transform their output, so the fit matches the log-scaled display. The same applies to `density`, `histogram`, `expectation` and `filled_contours`, whose evaluation points or bin edges are computed in the transformed space and mapped back.

The left panel below fits the line in linear space and curves away from the log-linear data; the right panel fits in log space and tracks it.

````@example continuous_scales
t = repeat(0.0:1:8, inner = 2)
conc = @. 100 * 10^(-0.09 * t)
df = (; t, conc)
base = data(df) * mapping(:t => "time (h)", :conc => "concentration (mg/L)")
spec = base * visual(Scatter) + base * linear(interval = nothing) * visual(color = :firebrick)

fig = Figure(size = (800, 350))
draw!(fig[1, 1], spec; axis = (; yscale = log10, title = "axis = (; yscale = log10)"))
draw!(fig[1, 2], spec, scales(Y = (; scale = log10)); axis = (; title = "scales(Y = (; scale = log10))"))
fig
````

The scale function must have an inverse known to `Makie.inverse_transform` (e.g. `log10`, `log2`, `log`, `sqrt`), and every value mapped onto the scaled aesthetic must lie in its domain.

When the data carries units, the transform is applied to the unitless numeric value (units are stripped before and reattached after).



