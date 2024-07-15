# # Visual

# The function `visual` can be used to give data-independent visual information about the plot
# (plotting function or attributes).

# The available plotting functions are documented
# [here](http://makie.juliaplots.org/dev/examples/plotting_functions/). Refer to
# plotting functions using upper CamelCase for `visual`'s first argument (e.g.
# `visual(Scatter), visual(BarPlot)`). See the documentation of each plotting
# function to discover the available attributes. These attributes can be passed
# as additional keyword arguments to `visual`, or as part of the `mapping` 
# you define.

# In fact `visual` can be used for any plotting function that is defined using
# the `@recipe` macro from Makie. This means that if you have a custom recipe
# defined in another package you can use it from AlgebraOfGraphics just like any
# of the plotting functions defined in Makie.

## Examples

using AlgebraOfGraphics, CairoMakie
set_aog_theme!()

df = (x=randn(1000), y=randn(1000))
plt = data(df) * mapping(:x, :y) * AlgebraOfGraphics.density(npoints=50)
draw(plt * visual(Heatmap)) # plot as heatmap (the default)

# From AlgebraOfGraphics version 0.7 on, some attributes of the underlying Makie functions will not have an effect if they are
# controlled by scales instead. For example, continuous colors are completely controlled
# by color scales, so setting `colormap` in `visual` does not have an effect.
#
# Set the colormap in the [Scale options](@ref) instead.

draw(plt, scales(Color = (; colormap = :viridis))) # set a different colormap

#

draw(plt * visual(Contour)) # plot as contour

#

draw(plt * visual(Contour, linewidth=2)) # plot as contour with thicker lines
