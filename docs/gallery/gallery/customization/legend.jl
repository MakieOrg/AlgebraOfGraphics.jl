# ---
# title: Legend tweaking
# cover: assets/legend_tweaking.png
# description: Setting legend attributes.
# ---

using AlgebraOfGraphics, CairoMakie
set_aog_theme!() #src

# To tweak the position and appearance of the legend, simply use the `legend` keyword when plotting. For example

labels = ["a looooooong label", "an even loooooonger label", "and one more long label"]
df = (x=rand(100), y=rand(100), group=rand(labels, 100))
layers = linear() + mapping(color=:group)
plt = data(df) * layers * mapping(:x, :y)
draw(plt)

#

fg = draw(plt, legend=(position=:top, titleposition=:left, framevisible=true, padding=5))

# To adjust the title and order of labels in a legend you can use the pair syntax.

layers = linear() +  mapping(color=:group => sorter(labels) => "Labels")
plt = data(df) * layers * mapping(:x, :y)
draw(plt)

# save cover image #src
mkpath("assets") #src
save("assets/legend_tweaking.png", fg) #src


# Adding a plot to a pre-existing figure with `draw!` will not draw the legend
# automatically.  In this case, one must use `legend!` and specify the axis to
# which it should be added.
#
# The `tellheight = false, tellwidth = false` arguments are useful to avoid
# changing the dimensions of the axis.

makie_fig = Figure()
ax_scatter = Axis(makie_fig[1, 1])

grid = draw!(ax_scatter, plt)

legend!(makie_fig[1, 1], grid; tellheight=false, tellwidth=false, halign=:right, valign=:top)

makie_fig

# If the automatic legend elements are not legible enough, you can change their properties
# by passing overrides to the `legend` attribute of a `visual`.

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