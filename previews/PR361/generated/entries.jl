# # Entries
#
# The key ingredient for data representations are `AxisEntries`.
#
# ## The `AxisEntries` type
#
# An `AxisEntries` object is made of four components:
# - axis,
# - entries,
# - categorical scales,
# - continuous scales.

# The entries are supposed to be rescaled already and can be plotted as they are
# onto the axis. The scales can be used to draw legend, colorbar, axis ticks and labels.

using AlgebraOfGraphics, CairoMakie
using AlgebraOfGraphics: CategoricalScale, ContinuousScale, fitscale
using AlgebraOfGraphics: NamedArguments, MixedArguments
resolution = (600, 600)
fig = Figure(; resolution)
N = 11
rg = range(1, 2, length=N)
markerpalette = [:circle, :utriangle, :dtriangle, :rect]
x1, x2 = rg, rg
y1, y2 = cosh.(rg), sinh.(rg)
c1, c2 = 1:N, 1:N
m1, m2 = fill(:utriangle, N), fill(:utriangle, N)

categoricalscales = MixedArguments()
insert!(
    categoricalscales,
    :marker,
    fitscale(CategoricalScale(["a", "b", "c"], markerpalette, "class"))
)

continuousscales = MixedArguments()
insert!(continuousscales, 1, ContinuousScale(extrema([x1; x2]), "x"))
insert!(continuousscales, 2, ContinuousScale(extrema([y1; y2]), "y"))
insert!(continuousscales, :color, ContinuousScale((1, N), "c"))

ae = AxisEntries(
    Axis(fig[1, 1]),
    [
        Entry(
            Scatter,
            Any[x1, y1],
            NamedArguments((color=c1, marker=m1, markersize=15, colorrange=(1, N)))
        ),
        Entry(
            Scatter,
            Any[x2, y2],
            NamedArguments((color=c2, marker=m2, markersize=15, colorrange=(1, N)))
        ),
    ],
    categoricalscales,
    continuousscales
)
plot!(ae)
fig
