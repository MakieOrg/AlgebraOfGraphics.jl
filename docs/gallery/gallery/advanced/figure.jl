# ---
# title: Figure tweaking
# cover: assets/figure_tweaking.png
# author: "[Pietro Vertechi](https://github.com/piever)"
# ---

using AlgebraOfGraphics, CairoMakie
set_aog_theme!() #src

# To tweak one or more axes, simply use the `axis` keyword when plotting. For example

df = (x=rand(100), y=rand(100), z=rand(100), c=rand(["a", "b"], 100))
xyc = data(df) * mapping(:x, :y, layout=:c)
layers = linear() + mapping(color=:z)
plt = xyc * layers
fg = draw(plt, axis=(aspect=1,), figure=(resolution=(800, 400),))

#

fg = draw(plt, axis=(aspect=1, xticks=0:0.1:1, yticks=0:0.1:1, ylabel="custom label"))

# save cover image #src
mkpath("assets") #src
save("assets/figure_tweaking.png", fg) #src
