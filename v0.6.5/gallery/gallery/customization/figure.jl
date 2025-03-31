using AlgebraOfGraphics, CairoMakie

df = (x=rand(100), y=rand(100), z=rand(100), c=rand(["a", "b"], 100))
xyc = data(df) * mapping(:x, :y, layout=:c)
layers = linear() + mapping(color=:z)
plt = xyc * layers
fg = draw(plt, axis=(aspect=1,), figure=(resolution=(800, 400),))

fg = draw(plt, axis=(aspect=1, xticks=0:0.1:1, yticks=0:0.1:1, ylabel="custom label"))

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

