using AlgebraOfGraphics, CairoMakie

x = 1:100
y = @. sqrt(x) + 20x + 100
df = (; x, y)
plt = data(df) *
    mapping(
        :x,
        :y => log => "√x + 20x + 100 (log scale)",
    ) * visual(Lines)
draw(plt)

x = 1:100
y = @. sqrt(x) + 20x + 100
df = (; x, y)
plt = data(df) *
    mapping(
        :x,
        :y => "√x + 20x + 100 (log scale)",
    ) * visual(Lines)
draw(plt, axis=(yscale=log,))

x = 0:100
y = @. 0.01 + x/1000
df = (; x, y)
plt = data(df) *
    mapping(
        :x,
        :y => "y",
    ) * visual(Lines)
fg = draw(plt, axis=(yscale=log,))

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

