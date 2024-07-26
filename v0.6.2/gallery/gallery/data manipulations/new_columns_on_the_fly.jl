using AlgebraOfGraphics, CairoMakie

df = (x=rand(100), y=rand(100), z=rand(100), c=rand(["a", "b"], 100))
layers = linear() + mapping(color=:z)

plt = data(df) * layers * mapping(:x => (x -> x^2) => L"x^2", :y => L"This variable is called $y$")
fg = draw(plt)

plt = data(df) * layers * mapping(:x, (:x, :y, :z) => (+) => L"the new variable $x + y + z$", layout=:c)
fg = draw(plt)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

