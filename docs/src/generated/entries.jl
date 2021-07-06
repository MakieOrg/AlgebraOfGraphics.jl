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
using AlgebraOfGraphics: CategoricalScale
resolution = (600, 600)
fig = Figure(; resolution)
N = 11
rg = range(1, 2, length=N)
ae = AxisEntries(
    Axis(fig[1, 1]),
    [
        Entry(
            plottype=Scatter,
            positional=(rg, cosh.(rg)),
            named=(color=1:N, marker=fill("b", N));
            attributes=Dict(:markersize => 15)
        ),
        Entry(
            plottype=Scatter,
            positional=(rg, sinh.(rg)),
            named=(color=1:N, marker=fill("c", N));
            attributes=Dict(:markersize => 15)
        ),
    ],
    Dict(
        :marker => CategoricalScale(["a", "b", "c"], [:circle, :utriangle, :dtriangle], "class"),
    ), # scales
)
plot!(ae)
fig
