using AlgebraOfGraphics, CairoMakie

df = (x=rand(100), y=rand(100), group=rand(["a looooooong label", "an even loooooonger label", "and one more long label"], 100))
layers = linear() + mapping(color=:group)
plt = data(df) * layers * mapping(:x, :y)
draw(plt)

fg = draw(plt, legend=(position=:top, titleposition=:left, framevisible=true, padding=5))

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

