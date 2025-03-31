# # Visual

# ```@docs
# visual
# ```

# ## Examples

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

# ## Manual legend entries via `label`

# The legend normally contains entries for all appropriate scales used in the plot.
# Sometimes, however, you just want to label certain plots such that they appear in the legend without using any scale.
# You can achieve this by adding the `label` keyword to all `visual`s that you want to label.
# Layers with the same `label` will be combined within a legend entry.

x = range(0, 4pi, length = 40)
layer1 = data((; x = x, y = cos.(x))) * mapping(:x, :y) * visual(Lines, linestyle = :dash, label = "A cosine line")
layer2 = data((; x = x, y = sin.(x) .+ 2)) * mapping(:x, :y) *
    (visual(Lines, color = (:tomato, 0.4)) + visual(Scatter, color = :tomato)) * visual(label = "A sine line + scatter")
draw(layer1 + layer2)

# If the figure contains other scales, the legend will list the labelled group last by default. If you want to reorder, use the symbol `:Label` to specify the labelled group.

df = (; x = repeat(1:10, 3), y = cos.(1:30), group = repeat(["A", "B", "C"], inner = 10))
spec1 = data(df) * mapping(:x, :y, color = :group) * visual(Lines)

spec2 = data((; x = 1:10, y = cos.(1:10) .+ 2)) * mapping(:x, :y) * visual(Scatter, color = :purple, label = "Scatter")

f = Figure()
fg = draw!(f[1, 1], spec1 + spec2)
legend!(f[1, 2], fg)
legend!(f[1, 3], fg, order = [:Label, :Color])

f
