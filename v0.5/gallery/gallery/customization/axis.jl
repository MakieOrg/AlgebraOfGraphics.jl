using AlgebraOfGraphics, CairoMakie

df = (x=rand(100), y=rand(100), z=rand(100))
layers = linear() + mapping(color=:z)
plt = data(df) * layers * mapping(:x, :y)
draw(plt, axis=(aspect=1,))

fg = draw(plt, axis=(aspect=1, xticks=0:0.1:1, yticks=0:0.1:1, ylabel="custom label"))

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

