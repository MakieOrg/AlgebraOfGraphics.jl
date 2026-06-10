using AlgebraOfGraphics, CairoMakie

x = rand(100)
y = @. randn() + x
df = (; x, y)
xy = data(df) * mapping(:x, :y)
layers = linear() + visual(Scatter)
draw(layers * xy)

x = rand(100)
y = @. randn() + 5 * x ^ 2
df = (; x, y)
xy = data(df) * mapping(:x, :y)
layers = smooth() + visual(Scatter)
fg = draw(layers * xy)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

