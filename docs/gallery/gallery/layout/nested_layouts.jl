# ---
# title: Nested layouts
# cover: assets/nested_layouts.png
# description: Embedding AlgebraOfGraphics plots in a Makie figure
# author: "[Pietro Vertechi](https://github.com/piever)"
# ---

using AlgebraOfGraphics, CairoMakie
set_aog_theme!() #src

# All AlgebraOfGraphics plots can be inserted in any figure position, where the rest
# of the figure is managed by vanilla Makie.
# For example

resolution = (800, 600)
fig = Figure(; resolution)
ax = Axis(fig[1, 1], title="Some plot")

df = (
    x=rand(500),
    y=rand(500),
    i=rand(["a", "b", "c"], 500),
    j=rand(["d", "e", "f"], 500),
    k=rand(Bool, 500),
    l=rand(Bool, 500)
)
plt = data(df) * mapping(:x, :y, col=:i, row=:j, color=:k, marker=:l)

subfig = fig[1, 2:3]
ag = draw!(subfig, plt)
for ae in ag
    ae.axis.xticklabelrotation[] = π/2
end
legend!(fig[end+1, 2], ag, orientation=:horizontal, tellheight=true)
fig

# save cover image #src
mkpath("assets") #src
save("assets/nested_layouts.png", fig) #src
