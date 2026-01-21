using AlgebraOfGraphics, CairoMakie

df = (x=rand(100), y=rand(100), z=rand(100), c=rand(["a", "b"], 100))
layers = linear() + mapping(color=:z)
plt = data(df) * layers * mapping(:x, (:x, :y, :z) => (+) => "x + y + z", layout=:c)
fg = draw(plt)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

