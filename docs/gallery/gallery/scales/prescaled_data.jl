# ---
# title: Pre-scaled data
# cover: assets/multiple_color_scales.png
# author: "[Pietro Vertechi](https://github.com/piever)"
# ---

using AlgebraOfGraphics, CairoMakie
using Colors
set_aog_theme!() #src

x = rand(100)
y = rand(100)
z = rand([colorant"teal", colorant"orange"], 100)
df = (; x, y, z)
plt = data(df) * mapping(:x, :y, color=:z => verbatim)
draw(plt)

#

x = rand(100)
y = rand(100)
label = rand(["a", "b"], 100)
df = (; x, y, label)
plt = data(df) * mapping(:label => verbatim, (:x, :y) => Point) * visual(Annotations)
fg = draw(plt)


# save cover image #src
mkpath("assets") #src
save("assets/multiple_color_scales.png", fg) #src
