using AlgebraOfGraphics, CairoMakie, PalmerPenguins, DataFrames

penguins = dropmissing(DataFrame(PalmerPenguins.load()))

data(penguins) * visual(Violin) *
    mapping(:species, :bill_depth_mm, color=:sex, dodge=:sex) |> draw

plt = data(penguins) * visual(Violin, datalimits=extrema)
plt *= mapping(:species, :bill_depth_mm, color=:sex, side=:sex, dodge=:island)
fg = draw(plt, axis=(limits=((0.5, 3.5), nothing),))

data(penguins) * visual(BoxPlot, show_notch=true) *
    mapping(:species, :bill_depth_mm, color=:sex, dodge=:sex) |> draw

data(penguins) *
    mapping(:bill_length_mm, :bill_depth_mm, col=:sex) *
    visual(QQPlot, qqline=:fit) |> draw

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

