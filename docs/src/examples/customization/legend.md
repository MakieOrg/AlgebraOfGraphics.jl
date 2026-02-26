# Legend options


````@example legend
using AlgebraOfGraphics, CairoMakie
````

To tweak the position and appearance of the legend, simply use the `legend` keyword when plotting. For example

````@example legend
labels = ["a looooooong label", "an even loooooonger label", "and one more long label"]
df = (x=rand(100), y=rand(100), group=rand(labels, 100))
layers = linear() + mapping(color=:group)
plt = data(df) * layers * mapping(:x, :y)
draw(plt)
````

````@example legend
fg = draw(plt, legend=(position=:top, titleposition=:left, framevisible=true, padding=5))
````

To adjust the title and order of labels in a legend you can use the pair syntax.

````@example legend
layers = linear() +  mapping(color=:group => sorter(labels) => "Labels")
plt = data(df) * layers * mapping(:x, :y)
draw(plt)
````

Adding a plot to a pre-existing figure with `draw!` will not draw the legend
automatically.  In this case, one must use `legend!` and specify the axis to
which it should be added.

The `tellheight = false, tellwidth = false` arguments are useful to avoid
changing the dimensions of the axis.

````@example legend
makie_fig = Figure()
ax_scatter = Axis(makie_fig[1, 1])

grid = draw!(ax_scatter, plt)

legend!(makie_fig[1, 1], grid; tellheight=false, tellwidth=false, halign=:right, valign=:top)

makie_fig
````

If the automatic legend elements are not legible enough, you can change their properties
by passing overrides to the `legend` attribute of a `visual`.

````@example legend
df = (;
    x = repeat(1:100, 5),
    y = reduce(vcat, [[cos(x) for x in range(0, 8pi, length = 100)] .+ 0.3 .* randn.() for _ in 1:5]),
    group = repeat(1:5, inner = 100),
)

lin = data(df) *
    mapping(:x, :y, group = :group => nonnumeric) *
    visual(Lines, linewidth = 0.3, label = "Lines", legend = (; linewidth = 1.5))
sca = data(df) *
    mapping(:x, :y => y -> y + 5, group = :group => nonnumeric) *
    visual(Scatter, markersize = 3, label = "Scatter", legend = (; markersize = 12))

draw(lin + sca)
````

When combining multiple layers that share a categorical scale, some layers may produce
unwanted legend elements. For example, `Annotation` labels added on top of `Scatter` points
generate colored poly squares that cover the scatter markers in the legend:

````@example legend
df = (;
    x = [1, 2, 3, 4],
    y = [3, 5, 2, 6],
    label = ["A", "B", "C", "D"],
    group = ["I", "I", "II", "II"],
)

spec = data(df) * mapping(:x, :y, color = :group) * (
    visual(Scatter, markersize = 15) +
    visual(Annotation) * mapping(text = :label => verbatim)
)
draw(spec)
````

You can suppress a layer's legend contribution by passing `legend = (; visible = false)` to `visual`:

````@example legend
spec = data(df) * mapping(:x, :y, color = :group) * (
    visual(Scatter, markersize = 15) +
    visual(Annotation, legend = (; visible = false)) * mapping(text = :label => verbatim)
)
draw(spec)
````

