using AlgebraOfGraphics, CairoMakie
using Colors

x = rand(100)
y = rand(100)
z = rand([colorant"teal", colorant"orange"], 100)
df = (; x, y, z)
plt = data(df) * mapping(:x, :y, color=:z => verbatim)
draw(plt)

x = rand(100)
y = rand(100)
label = rand(["a", "b"], 100)
df = (; x, y, label)
plt = data(df) * mapping(:label => verbatim, (:x, :y) => Point) * visual(Annotations)
fg = draw(plt)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

