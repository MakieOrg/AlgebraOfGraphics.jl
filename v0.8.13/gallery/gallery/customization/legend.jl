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

df = (;
    x = repeat(1:100, 5),
    y = reduce(vcat, [[cos(x) for x in range(0, 8pi, length = 100)] .+ 0.3 .* randn.() for _ in 1:5]),
    group = repeat(1:5, inner = 100),
)

lin = data(df) *
    mapping(:x, :y, group = :group => nonnumeric) *
    visual(Lines, linewidth = 0.3, label = "Lines", legend = (; linewidth = 1.5))
sca = data(df) *
    mapping(:x, :y => y -> y + 5, group = :group => nonnumeric) *
    visual(Scatter, markersize = 3, label = "Scatter", legend = (; markersize = 12))

draw(lin + sca)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
