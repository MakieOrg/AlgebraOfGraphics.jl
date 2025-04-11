# # Entries
#
# The key ingredient for data representations are `AxisEntries`.
#
# ## The `AxisEntries` type
#
# An `AxisEntries` object is
# made of four components:
# - axis,
# - entries,
# - scales,
# - labels.

using AlgebraOfGraphics, CairoMakie
using AlgebraOfGraphics: CategoricalScale, ContinuousScale
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
        1 => ContinuousScale(identity, (0, 4)),
        2 => ContinuousScale(identity, (0, 4)),
        :color => ContinuousScale(identity, (1, N)),
        :marker => CategoricalScale(["a", "b", "c"], [:circle, :utriangle, :dtriangle]),
    ), # scales
    Dict(
        1 => "x",
        2 => "y",
        :color => "identity",
        :marker => "function"
    ), # labels
)
plot!(ae)
fig
