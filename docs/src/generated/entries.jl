# # Entries
#
# The key ingredient for data representations are `AxisEntries`.
#
# ## The `AxisEntries` type
#
# An `AxisEntries` object is
# made of three components:
# - axis,
# - entries,
# - scales.

using AlgebraOfGraphics, CairoMakie
using AlgebraOfGraphics: CategoricalScale, fitscale
using AlgebraOfGraphics: NamedArguments
resolution = (600, 600)
fig = Figure(; resolution)
N = 11
rg = range(1, 2, length=N)
markerpalette = [:circle, :utriangle, :dtriangle, :rect]
ae = AxisEntries(
    Axis(fig[1, 1]),
    [
        Entry(
            plottype=Scatter,
            positional=Any[rg, cosh.(rg)],
            named=NamedArguments((color=1:N, marker=fill("b", N)));
            attributes=NamedArguments((markersize=15,))
        ),
        Entry(
            plottype=Scatter,
            positional=Any[rg, sinh.(rg)],
            named=NamedArguments((color=1:N, marker=fill("c", N)));
            attributes=NamedArguments((markersize=15,))
        ),
    ],
    NamedArguments(
        (marker=fitscale(CategoricalScale(["a", "b", "c"], markerpalette, "class")),),
    ), # scales
)
plot!(ae)
fig
