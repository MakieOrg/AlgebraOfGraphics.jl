using AlgebraOfGraphics, CairoMakie
using AlgebraOfGraphics: density

df = (x=rand(0:99, 1000),)
plt = data(df) * mapping(:x) * histogram(bins=20)
fg = draw(plt)

df = (x=randn(1000), c=rand(["a", "b"], 1000))
plt = data(df) * mapping(:x, color=:c, stack=:c) * histogram(bins=20)
fg = draw(plt)

df = (x=rand(1000), y=randn(1000))
plt = data(df) * mapping(:x, :y) * histogram(bins=20)
draw(plt)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

