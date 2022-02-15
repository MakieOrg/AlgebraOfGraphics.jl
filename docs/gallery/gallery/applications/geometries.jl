# ---
# title: Geometries
# cover: assets/geometries.png
# description: Visualizing geometries.
# author: "[Pietro Vertechi](https://github.com/piever)"
# ---

using AlgebraOfGraphics, CairoMakie
using GeometryBasics
set_aog_theme!() #src

geometry = [Rect(Vec(i, j), Vec(1, 1)) for i in 0:7 for j in 0:7]
group = [isodd(i + j) ? "light square" : "dark square" for i in 0:7 for j in 0:7]
df = (; geometry, group)

plt = data(df) * visual(Poly) * mapping(:geometry, color = :group)
fg = draw(plt; axis=(aspect=1,))

# save cover image #src
mkpath("assets") #src
save("assets/geometries.png", fg) #src
