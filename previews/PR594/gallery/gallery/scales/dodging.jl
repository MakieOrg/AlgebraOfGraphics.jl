using AlgebraOfGraphics, CairoMakie
using Colors

df = (; x = ["One", "One", "Two", "Two"], y = 1:4, err = [0.2, 0.3, 0.4, 0.5], group = ["A", "B", "A", "B"])
plt = data(df) * mapping(:x, :y, dodge = :group, color = :group) * visual(BarPlot)
draw(plt)

plt2 = data(df) * mapping(:x, :y, :err, dodge_x = :group) * visual(Errorbars)
fg = draw(plt + plt2)

df = (
    x = repeat(1:10, inner = 2),
    y = cos.(range(0, 2pi, length = 20)),
    ylow = cos.(range(0, 2pi, length = 20)) .- 0.2,
    yhigh = cos.(range(0, 2pi, length = 20)) .+ 0.3,
    dodge = repeat(["A", "B"], 10)
)

f = Figure()
plt3 = data(df) * (
    mapping(:x, :y, dodge_x = :dodge, color = :dodge) * visual(Scatter) +
    mapping(:x, :ylow, :yhigh, dodge_x = :dodge, color = :dodge) * visual(Rangebars)
)
kw(; kwargs...) = (; xticklabelsvisible = false, xticksvisible = false, xlabelvisible = false, kwargs...)

draw!(f[1, 1], plt3, scales(DodgeX = (; width = 0.25)); axis = kw(title = "DodgeX = (; width = 0.25)"))
draw!(f[2, 1], plt3, scales(DodgeX = (; width = 0.5)); axis = kw(title = "DodgeX = (; width = 0.5)"))
draw!(f[3, 1], plt3, scales(DodgeX = (; width = 1.0)); axis = (; title = "DodgeX = (; width = 1.0)"))

f

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
