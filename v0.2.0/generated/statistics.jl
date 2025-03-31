# # Statistical plots
#
# Statistical plots are supported automatically, provided that they are implemented
# in Makie. Integration with the styling framework should also happen automatically.
# Some particular statistical plots have specific keyword options that can be applied
# in mapping, such as `dodge` (for `boxplot` and `violin`) or `side` (for `violin`).
#
# ## Examples

#src using RDatasets: dataset
#src using AlgebraOfGraphics, AbstractPlotting, CairoMakie
#src mpg = dataset("ggplot2", "mpg");
#src data(mpg) * mapping(:Displ, :Hwy, layout_x = ) * visual(QQPlot) |> draw
#src AbstractPlotting.save("qqplot.svg", AbstractPlotting.current_scene()); nothing #hide

#src # ![](qqplot.svg)
#src Needs https://github.com/JuliaStats/Distributions.jl/issues/1196 to work.

using RDatasets: dataset
using AlgebraOfGraphics, AbstractPlotting, CairoMakie
mpg = dataset("ggplot2", "mpg");
mpg.IsAudi = mpg.Manufacturer .== "audi"
geom = visual(BoxPlot, layout_x = 1) + visual(Violin, layout_x = 2)
data(mpg) *
    mapping(:Cyl => categorical, :Hwy) *
    mapping(dodge = :IsAudi => categorical, color = :IsAudi => categorical) *
    geom |> draw
AbstractPlotting.save("boxplot.svg", AbstractPlotting.current_scene()); nothing #hide

# ![](boxplot.svg)

data(mpg) *
    mapping(:Cyl => categorical, :Hwy) *
    mapping(side = :IsAudi => categorical, color = :IsAudi => categorical) *
    visual(Violin) |> draw
AbstractPlotting.save("violin.svg", AbstractPlotting.current_scene()); nothing #hide

# ![](violin.svg)