using AlgebraOfGraphics, CairoMakie

labels = ["a looooooong label", "an even loooooonger label", "and one more long label"]
df = (x=rand(100), y=rand(100), group=rand(labels, 100))
layers = linear() + mapping(color=:group)
plt = data(df) * layers * mapping(:x, :y)
draw(plt)

fg = draw(plt, legend=(position=:top, titleposition=:left, framevisible=true, padding=5))

layers = linear() +  mapping(color=:group => sorter(labels) => "Labels")
plt = data(df) * layers * mapping(:x, :y)
draw(plt)

makie_fig = Figure()
ax_scatter = Axis(makie_fig[1, 1])

grid = draw!(ax_scatter, plt)

legend!(makie_fig[1, 1], grid; tellheight=false, tellwidth=false, halign=:right, valign=:top)

makie_fig

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

