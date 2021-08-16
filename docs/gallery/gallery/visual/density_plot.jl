# ---
# title: Density plot
# cover: assets/density_plot.png
# author: "[Pietro Vertechi](https://github.com/piever)"
# ---

using AlgebraOfGraphics, CairoMakie
using AlgebraOfGraphics: density
set_aog_theme!() #src

df = (x=randn(1000), c=rand(["a", "b"], 1000))
plt = data(df) * mapping(:x, color=:c) * density(bandwidth=0.5)
fg = draw(plt)

#

df = (x=randn(1000), c=rand(["a", "b"], 1000))
plt = data(df) * mapping(:x, color=:c) * density(bandwidth=0.5) * visual(orientation=:vertical)
"Not yet supported" # hide

# save cover image #src
mkpath("assets") #src
save("assets/density_plot.png", fg) #src
