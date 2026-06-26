using AlgebraOfGraphics, CairoMakie

df = (x=rand(100), y=rand(100), i=rand(["a", "b", "c"], 100), j=rand(["d", "e", "f"], 100))
plt = data(df) * mapping(:x, :y, col=:i, row=:j)
draw(plt)

df = (x=rand(100), y=rand(100), l=rand(["a", "b", "c", "d", "e"], 100))
plt = data(df) * mapping(:x, :y, layout=:l)
draw(plt)

df1 = (x=rand(100), y=rand(100), i=rand(["a", "b", "c"], 100), j=rand(["d", "e", "f"], 100))
df2 = (x=[0, 1], y=[0.5, 0.5], i=fill("a", 2), j=fill("e", 2))
layers = data(df1) * visual(Scatter) + data(df2) * visual(Lines)
fg = draw(layers * mapping(:x, :y, col=:i, row=:j))

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

