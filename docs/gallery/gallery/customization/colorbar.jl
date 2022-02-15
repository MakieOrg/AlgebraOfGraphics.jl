# ---
# title: Colorbar tweaking
# cover: assets/colorbar_tweaking.png
# description: Setting colorbar attributes.
# ---

using AlgebraOfGraphics, CairoMakie
set_aog_theme!() #src

# To tweak the position and appearance of the colorbar, simply use the `colorbar` keyword when plotting. For example

df = (x=rand(100), y=rand(100), z=rand(100))
plt = data(df) * mapping(:x, :y, color=:z)
draw(plt)

#

fg = draw(plt, colorbar=(position=:top, size=25))

# save cover image #src
mkpath("assets") #src
save("assets/colorbar_tweaking.png", fg) #src
