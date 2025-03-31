using AlgebraOfGraphics, CairoMakie
using GeometryBasics

geometry = [Rect(Vec(i, j), Vec(1, 1)) for i in 0:7 for j in 0:7]
group = [isodd(i + j) ? "light square" : "dark square" for i in 0:7 for j in 0:7]
df = (; geometry, group)

plt = data(df) * visual(Poly) * mapping(:geometry, color = :group)
fg = draw(plt; axis=(aspect=1,))

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

