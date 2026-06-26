# # Visual

# ```@docs
# visual
# ```

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
