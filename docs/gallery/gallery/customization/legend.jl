# ---
# title: Axis tweaking
# cover: assets/legend_tweaking.png
# description: Setting legend attributes
# ---

using AlgebraOfGraphics, CairoMakie
set_aog_theme!() #src

# To tweak the position and appearance of the legend, simply use the `legend` keyword when plotting. For example

df = (x=rand(100), y=rand(100), z=rand(100))
layers = linear() + mapping(color=:z)
plt = data(df) * layers * mapping(:x, :y)
draw(plt, axis=(aspect=1,))

#

fg = draw(plt, legend=(position = :top, framevisible = true))

# save cover image #src
mkpath("assets") #src
save("assets/legend_tweaking.png", fg) #src
