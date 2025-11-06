# Statistical visualizations

````@example statistical_visualizations
using AlgebraOfGraphics, CairoMakie, DataFrames

penguins = DataFrame(AlgebraOfGraphics.penguins())

data(penguins) * visual(Violin) *
    mapping(:species, :bill_depth_mm, color=:sex, dodge=:sex) |> draw
````

````@example statistical_visualizations
plt = data(penguins) * visual(Violin, datalimits=extrema)
plt *= mapping(:species, :bill_depth_mm, color=:sex, side=:sex, dodge=:island)
fg = draw(plt, axis=(limits=((0.5, 3.5), nothing),))
````

````@example statistical_visualizations
data(penguins) * visual(BoxPlot, show_notch=true) *
    mapping(:species, :bill_depth_mm, color=:sex, dodge=:sex) |> draw
````

````@example statistical_visualizations
data(penguins) *
    mapping(:bill_length_mm, :bill_depth_mm, col=:sex) *
    visual(QQPlot, qqline=:fit) |> draw
````



