using AlgebraOfGraphics, CairoMakie

x = 1:100
y = sin.(range(0, 2pi, length = 100))

plt = mapping(x, y, color = repeat(["high", "low"], inner = 50)) *
    visual(Lines) +
    mapping([20, 28, 51], color = "marker" => scale(:secondary)) *
    visual(VLines, linestyle = :dash)

fg = draw(plt, scales(secondary = (; palette = [:gray80])))

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
