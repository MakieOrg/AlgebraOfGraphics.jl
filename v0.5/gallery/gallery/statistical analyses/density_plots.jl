using AlgebraOfGraphics, CairoMakie
using AlgebraOfGraphics: density

df = (x=randn(1000), c=rand(["a", "b"], 1000))
plt = data(df) * mapping(:x, color=:c) * density(bandwidth=0.5)
fg = draw(plt)

df = (x=randn(1000), c=rand(["a", "b"], 1000))
plt = data(df) * mapping(:x, color=:c) * density(bandwidth=0.5) * visual(orientation=:vertical)
"Not yet supported" # hide

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

