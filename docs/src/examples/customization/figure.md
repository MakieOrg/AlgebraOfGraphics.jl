# Figure tweaking

````@example figure
using AlgebraOfGraphics, CairoMakie
````

You can pass attributes to the underlying `Makie.Figure` using the `figure` keyword of [`draw`](@ref).

````@example figure
df = (x=rand(100), y=rand(100), z=rand(100), c=rand(["a", "b"], 100))
xyc = data(df) * mapping(:x, :y, layout=:c)
layers = linear() + mapping(color=:z)
plt = xyc * layers
draw(
    plt,
    figure = (;
        figure_padding = 10,
        backgroundcolor = :gray80,
        size = (800, 400)
    )
)
````

You can also add a figure title, subtitle and footnotes.

````@example figure
fg = draw(
    plt,
    figure = (;
        figure_padding = 10,
        backgroundcolor = :gray80,
        size = (800, 400),
        title = "Figure title",
        subtitle = "Some subtitle below the figure title",
        footnotes = [
            rich(superscript("1"), "First footnote"),
            rich(superscript("2"), "Second footnote"),
        ]
    )
)
````

The appearance of these elements can be modified further, for all options check the [`draw`](@ref) function.

````@example figure
draw(
    plt,
    figure = (;
        figure_padding = 10,
        backgroundcolor = :gray80,
        size = (800, 400),
        title = "Figure title",
        subtitle = "Some subtitle below the figure title",
        footnotes = [
            rich(superscript("1"), "First footnote"),
            rich(superscript("2"), "Second footnote"),
        ],
        titlecolor = :firebrick,
        titlealign = :right,
        footnotefont = :bold,
    )
)
````

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

