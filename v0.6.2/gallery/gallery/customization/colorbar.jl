using AlgebraOfGraphics, CairoMakie

df = (x=rand(100), y=rand(100), z=rand(100))
plt = data(df) * mapping(:x, :y, color=:z)
draw(plt)

fg = draw(plt, colorbar=(position=:top, size=25))

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

