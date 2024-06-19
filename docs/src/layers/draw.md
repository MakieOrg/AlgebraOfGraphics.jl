# Drawing Layers

A [`AlgebraOfGraphics.Layer`](@ref) or [`AlgebraOfGraphics.Layers`](@ref) object can be plotted
using the functions [`draw`](@ref) or [`draw!`](@ref).

Whereas `draw` automatically adds colorbar and legend, `draw!` does not, as it
would be hard to infer a good default placement that works in all scenarios.

Colorbar and legend, should they be necessary, can be added separately with the
[`colorbar!`](@ref) and [`legend!`](@ref) helper functions. See also
[Nested layouts](@ref) for a complex example.

## Scale options

All properties that decide how scales are visualized can be modified using the `scales` keyword of the `draw` function.
The properties that are accepted differ depending on the scale aesthetic type (for example `Color`, `Marker`, `LineStyle`) and whether the scale is categorical or continuous.

### Categorical scale options

All categorical scales take the same properties, independent of aesthetic type.

#### `palette`

The palette decides which attribute values are passed to Makie's plotting functions for each categorical value in the scale.

##### Color

A `Symbol` is converted to a colormap with `Makie.to_colormap`. 

```@example
using AlgebraOfGraphics
using CairoMakie

spec = data((; x = 1:10, y = 1:10, z = 'A':'J')) *
    mapping(:x, :y, color = :z) *
    visual(BarPlot)
draw(spec; scales = (; Color = (; palette = :tab10)))
```

It's also possible to directly specify a vector of colors, each of which `Makie.to_color` can handle:

```@example
using AlgebraOfGraphics
using CairoMakie
using CairoMakie.Colors: RGB, RGBA, Gray, HSV

spec = data((; x = 1:10, y = 1:10, z = 'A':'J')) *
    mapping(:x, :y, color = :z) *
    visual(BarPlot)
draw(spec; scales = (; Color = (; palette = [:red, :green, :blue, RGB(1, 0, 1), RGB(1, 1, 0), "#abcff0", "#c88cbccc", HSV(0.9, 0.3, 0.7), RGBA(0.7, 0.9, 0.6, 0.5), Gray(0.5)])))
```

##### Marker

A vector of values that `Makie.to_spritemarker` can handle.

```@example
using AlgebraOfGraphics
using CairoMakie

spec = data((; x = 1:10, y = 1:10, z = 'A':'J')) *
    mapping(:x, :y, marker = :z) *
    visual(Scatter, markersize = 20)

draw(
    spec;
    scales = (;
        Marker = (; palette = [:rect, :circle, :utriangle, :dtriangle, :diamond, :hline, :vline, :star5, :star6, :hexagon])
    )
)
```

##### LineStyle

A vector of values that `Makie.to_linestyle` can handle.

```@example
using AlgebraOfGraphics
using CairoMakie

spec = data((; x = 1:10, y = 1:10, z = repeat('A':'E', inner = 2))) *
    mapping(:x, :y, linestyle = :z) *
    visual(Lines, linewidth = 2)

draw(spec; scales = (;
    LineStyle = (; palette = [:solid, :dash, :dot, (:dot, :loose), Linestyle([0, 1, 2, 3, 4, 8])])
))
```

#### `categories`

The `categories` keyword can be used to reorder, label and even add categorical values.

Some reordering and renaming can be done using the `sorter` and `renamer` helper functions applied directly to columns in `mapping`.
However, this works less well when several `data` sources are combined where not all categories appear in each column.
Also, no categories can be added this way, which is something that can be useful if the existence of categories should be shown even though there is no data for them.

New labels can be assigned using the `value => label` pair syntax.

```@example
using AlgebraOfGraphics
using CairoMakie

spec = data((; group = ["A", "C", "D"], value = [1, 3, 4])) *
    mapping(:group, :value) * visual(BarPlot)

f = Figure()

draw!(f[1, 1], spec; scales = (;
    X = (; categories = ["A", "B", "C", "D"])
))
draw!(f[1, 2], spec; scales = (;
    X = (; categories = ["D", "A", "C"])
))
draw!(f[1, 3], spec; scales = (;
    X = (; categories = ["A" => "a", "C" => "c", "D" => "d"])
))

f
```

You can also pass a `Function` to `categories` which should take the vector of category values and return a new vector of categories or category/label pairs.

For example, you could add summary statistics to the facet layout titles this way, by grabbing them from a dictionary computed separately.

```@example
using AlgebraOfGraphics
using CairoMakie

summary_stats = Dict("A" => 1.32, "B" => 4.19, "C" => 0.04)

df = (;
    x = randn(90),
    y = randn(90) .+ repeat([0, 5, 10], inner = 30),
    group = repeat(["A", "B", "C"], inner = 30)
)

spec = data(df) * mapping(:x, :y, col = :group) * visual(Scatter)

draw(spec; scales = (; Col = (;
    categories = cats -> [
        cat => rich("$cat\n", rich("λ = $(summary_stats[cat])", font = :italic))
            for cat in reverse(cats)
        ]
)))
```


### Continous scale options

#### Color

Continuous color scales can be modified using the familiar Makie attributes `colormap`, `colorrange`, `highclip`, `lowclip` and `nan_color`. By default, `colorrange` is set to the extrema of the encountered values, so no clipping occurs.

```@example
using AlgebraOfGraphics
using CairoMakie

spec = data((; x = 1:10, y = 1:10, z = [1:4; NaN; 6:10])) *
    mapping(:x, :y, color = :z) *
    visual(Scatter, markersize = 20)

draw(spec; scales = (;
    Color = (;
        colormap = :plasma,
        nan_color = :cyan,
        lowclip = :lime,
        highclip = :red,
        colorrange = (2, 9)
    )
))
```

#### MarkerSize

The range of marker sizes can be set with the `sizerange` attribute.
Marker sizes are computed such that their area, and not `markersize` itself, grows linearly with the scale values. 

```@example
using AlgebraOfGraphics
using CairoMakie

spec = data((; x = 1:10, y = 1:10, z = 10:10:100)) *
    mapping(:x, :y, markersize = :z) *
    visual(Scatter)

f = Figure()

grid = draw!(f[1, 1], spec; scales = (;
    MarkerSize = (;
        sizerange = (5, 15)
    )
))
legend!(f[1, 2], grid)

grid2 = draw!(f[2, 1], spec; scales = (;
    MarkerSize = (;
        sizerange = (5, 30)
    )
))
legend!(f[2, 2], grid2)

f
```