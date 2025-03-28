# Drawing Layers

A [`AlgebraOfGraphics.Layer`](@ref) or [`AlgebraOfGraphics.Layers`](@ref) object can be plotted
using the functions [`draw`](@ref) or [`draw!`](@ref).

Whereas `draw` automatically adds colorbar and legend, `draw!` does not, as it
would be hard to infer a good default placement that works in all scenarios.

Colorbar and legend, should they be necessary, can be added separately with the
[`colorbar!`](@ref) and [`legend!`](@ref) helper functions. See also
TODO REFLINK Nested layouts for a complex example.

## Scale options

All properties that decide how scales are visualized can be modified by passing scale options (using the `scales` function) as the second argument of `draw` .
The properties that are accepted differ depending on the scale aesthetic type (for example `Color`, `Marker`, `LineStyle`) and whether the scale is categorical or continuous.

### Shared categorical scale options

All categorical scales share the following options:
    - `legend`
    - `palette`
    - `categories`

#### `legend`

Setting `legend = false` hides the legend for the respective scale. For `Row`, `Col` and `Layout` this refers to the facet labels.

```@example
using AlgebraOfGraphics
using CairoMakie

spec = data((; x = 1:9, y = 1:9, group = repeat(["A", "B", "C"], inner = 3))) *
    mapping(:x, :y, color = :group, marker = :group) *
    visual(Scatter)

f = Figure()

fg1 = draw!(f[1, 1], spec, scales(Color = (; legend = false)))
legend!(f[1, 2], fg1)

fg2 = draw!(f[2, 1], spec, scales(Marker = (; legend = false)))
legend!(f[2, 2], fg2)

f
```

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
draw(spec, scales(Color = (; palette = :tab10)))
```

It's also possible to directly specify a vector of colors, each of which `Makie.to_color` can handle:

```@example
using AlgebraOfGraphics
using CairoMakie
using CairoMakie.Colors: RGB, RGBA, Gray, HSV

spec = data((; x = 1:10, y = 1:10, z = 'A':'J')) *
    mapping(:x, :y, color = :z) *
    visual(BarPlot)
draw(spec, scales(Color = (; palette = [:red, :green, :blue, RGB(1, 0, 1), RGB(1, 1, 0), "#abcff0", "#c88cbccc", HSV(0.9, 0.3, 0.7), RGBA(0.7, 0.9, 0.6, 0.5), Gray(0.5)])))
```

If you want to use a continuous colormap for categorical data, you can use the `from_continuous`
helper function. It automatically takes care that the continuous colormap is sampled evenly
from start to end depending on the number of categories. Any colormap that Makie understands can
be passed, including named colormaps such as `:viridis`.

This example shows the difference in behavior when the two-element colormap `[:red, :blue]` is used with or without `from_continuous`:

```@example
using AlgebraOfGraphics
using CairoMakie

spec = data((; x = 1:10, y = 1:10, z = 'A':'J')) *
    mapping(:x, :y, color = :z) *
    visual(BarPlot)

f = Figure()
fg1 = draw!(f[1, 1], spec, scales(Color = (; palette = [:red, :blue])))
legend!(f[1, 2], fg1)
fg2 = draw!(f[1, 3], spec, scales(Color = (; palette = from_continuous([:red, :blue]))))
legend!(f[1, 4], fg2)
f
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
    spec,
    scales(
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

draw(spec, scales(
    LineStyle = (; palette = [:solid, :dash, :dot, (:dot, :loose), Linestyle([0, 1, 2, 3, 4, 8])])
))
```

##### X & Y

The "palette" values for X and Y axes are by default simply the numbers from 1 to N, the number of categories.
In some circumstances, it might be useful to change these values, for example to visualize that one category is different than others.
The palette values are normally assigned category-by-category in the sorted order, or in the order provided manually through the `categories` keyword. However, if you pass a vector of values, you can always use the `category => value` pair option to assign a specific category directly to a value, while the others cycle. Here, we do this with `"Unknown"` as it would otherwise be sorted before `"X"`.

```@example
using AlgebraOfGraphics
using CairoMakie

df = (; group = ["A", "B", "C", "X", "Y", "Unknown"], count = [45, 10, 20, 32, 54, 72])

spec = data(df) * mapping(:group, :count) * visual(BarPlot)

draw(spec, scales(X = (; palette = [1, 2, 3, 5, 6, "Unknown" => 8])))
```

##### Layout

Normally, with the `Layout` aesthetic, rows wrap automatically such that an approximately square distribution of facets is attained.
The [`wrapped`](@ref) function is a convenient helper to control the shape of the layout. You can control the maximum rows or columns, and the direction in which the layout is filled, which is row-by-row by default.

Here we cap the number of columns and leave the order by row:

```@example
using AlgebraOfGraphics
using CairoMakie

df = (;
    group = repeat(["A", "B", "C", "D", "E", "F", "G", "H", "I"], inner =20),
    x = repeat(1:20, 9),
    y = cumsum(randn(180)),
)

spec = data(df) * mapping(:x, :y, layout = :group) * visual(Scatter)

draw(spec, scales(Layout = (; palette = wrapped(cols = 4)));
    figure = (; title = "wrapped(cols = 4))", titlealign = :center)
)
```

Here we cap the number of rows instead and change the order with `by_col`:

```@example
using AlgebraOfGraphics
using CairoMakie

df = (;
    group = repeat(["A", "B", "C", "D", "E", "F", "G", "H", "I"], inner =20),
    x = repeat(1:20, 9),
    y = cumsum(randn(180)),
)

spec = data(df) * mapping(:x, :y, layout = :group) * visual(Scatter)

draw(spec, scales(Layout = (; palette = wrapped(rows = 4, by_col = true)));
    figure = (; title = "wrapped(rows = 4, by_col = true))", titlealign = :center)
)
```

You can also pass completely custom positions as a vector of tuples (you could also compute these values on the fly by passing a `Function` to `palette`):

```@example
using AlgebraOfGraphics
using CairoMakie

df = (;
    group = repeat(["A", "B", "C", "D", "E", "F", "G", "H"], inner =20),
    x = repeat(1:20, 8),
    y = cumsum(randn(160)),
)

spec = data(df) * mapping(:x, :y, layout = :group) * visual(Scatter)

clockwise = [(1, 1), (1, 2), (1, 3), (2, 3), (3, 3), (3, 2), (3, 1), (2, 1)]

draw(spec, scales(Layout = (; palette = clockwise)))
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

draw!(f[1, 1], spec, scales(
    X = (; categories = ["A", "B", "C", "D"])
))
draw!(f[1, 2], spec, scales(
    X = (; categories = ["D", "A", "C"])
))
draw!(f[1, 3], spec, scales(
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

draw(spec, scales(Col = (;
    categories = cats -> [
        cat => rich("$cat\n", rich("λ = $(summary_stats[cat])", font = :italic))
            for cat in reverse(cats)
        ]
)))
```

### Shared categorical scale options

#### Unit

AlgebraOfGraphics supports input data with units, currently [Unitful.jl](https://github.com/PainterQubits/Unitful.jl) and [DynamicQuantities.jl](https://github.com/SymbolicML/DynamicQuantities.jl) have extensions implemented.

If a continuous scale detects units, the units will be attached to the respective scale label.
The display unit can be overridden using the `unit` scale keyword, which will appropriately rescale the data:

```@example
using AlgebraOfGraphics
using CairoMakie
using Unitful
using DataFrames

df = DataFrame(AlgebraOfGraphics.penguins())
df.bill_length = df.bill_length_mm .* u"mm"
df.bill_depth = uconvert.(u"cm", df.bill_depth_mm .* u"mm")

spec = data(df) * mapping(:bill_length, :bill_depth, color = :species) * visual(Scatter)

f = Figure()
draw!(f[1, 1], spec)
draw!(f[1, 2], spec, scales(X = (; unit = u"m"), Y = (; unit = u"mm")))
f
```

### Special continuous scale options

#### Color

Continuous color scales can be modified using the familiar Makie attributes `colormap`, `colorrange`, `highclip`, `lowclip` and `nan_color`. By default, `colorrange` is set to the extrema of the encountered values, so no clipping occurs.

```@example
using AlgebraOfGraphics
using CairoMakie

spec = data((; x = 1:10, y = 1:10, z = [1:4; NaN; 6:10])) *
    mapping(:x, :y, color = :z) *
    visual(Scatter, markersize = 20)

draw(spec, scales(
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

grid = draw!(f[1, 1], spec, scales(
    MarkerSize = (;
        sizerange = (5, 15)
    )
))
legend!(f[1, 2], grid)

grid2 = draw!(f[2, 1], spec, scales(
    MarkerSize = (;
        sizerange = (5, 30)
    )
))
legend!(f[2, 2], grid2)

f
```

The values which are chosen for the legend can be controlled with the `ticks` and `tickformat` scale properties.
Ticks and ticklabels are computed using Makie's `Axis` infrastructure and therefore work with all objects that Makie supports for `Axis` attributes `xticks`/`yticks` and `xtickformat`/`ytickformat`.

```@example
using AlgebraOfGraphics
using CairoMakie

spec = data((; x = 1:10, y = 1:10, z = 10:10:100)) *
    mapping(:x, :y, markersize = :z) *
    visual(Scatter)

draw(spec, scales(MarkerSize = (; ticks = [10, 50, 100])))
```

```@example
using AlgebraOfGraphics
using CairoMakie

spec = data((; x = 1:10, y = 1:10, z = 10:10:100)) *
    mapping(:x, :y, markersize = :z) *
    visual(Scatter)

draw(spec, scales(MarkerSize = (; tickformat = "{:.1f} mg")))
```


## Legend options

The `legend` keyword forwards most attributes to Makie's `Legend` function.
The exceptions are listed here.

### `show`

Setting `show = false` hides the legend completely. This applies to `draw` and not `draw!` as the latter doesn't draw the legend automatically.

```@example
using AlgebraOfGraphics
using CairoMakie

spec = data((x = 1:3, y = 1:3, group = ["A", "B", "C"])) * mapping(:x, :y, color = :group) * visual(Scatter)

draw(spec; legend = (; show = false))
```

### `order`

By default, the legend order depends on the order in which layers and mappings have been defined, as well as whether scales are categorical or continuous.

```@example legendorder
using AlgebraOfGraphics
using CairoMakie

df = (;
    x = 1:12,
    y = 1:12,
    z = 1:12,
    group1 = repeat(["A", "B", "C"], inner = 4),
    group2 = repeat(["X", "Y"], 6),
)

spec = data(df) *
    mapping(:x, :y, markersize = :z, color = :group1, marker = :group2) *
    visual(Scatter)

draw(spec)
```

You can reorder the legend with the `order` keyword.
This expects a vector with either `Symbol`s or `Vector{Symbol}`s as elements, where each `Symbol` is the identifier for a scale that's represented in the legend.

Plain `Symbol`s can be used for simple reordering:


```@example legendorder
draw(spec; legend = (; order = [:MarkerSize, :Color, :Marker]))
```

`Symbol`s that are grouped into `Vector`s indicate that their groups should be merged together.
For example, consider this plot that features two color scales, but one for a scatter plot and one for a line plot.

```@example legendorder2
using AlgebraOfGraphics
using CairoMakie

df_a = (; x = 1:9, y = [1, 2, 3, 5, 6, 7, 9, 10, 11], group = repeat(["A", "B", "C"], inner = 3))

spec1 = data(df_a) * mapping(:x, :y, strokecolor = :group) * visual(Scatter, color = :transparent, strokewidth = 3, markersize = 15)

df_b = (; y = [4, 8], threshold = ["first", "second"])

spec2_custom_scale = data(df_b) * mapping(:y, color = :threshold => scale(:color2)) * visual(HLines)

draw(spec1 + spec2_custom_scale)
```

You can group the two scales together using `order`. The titles are dropped.

```@example legendorder2
draw(spec1 + spec2_custom_scale; legend = (; order = [[:Color, :color2]]))
```

If you want to add a title to a merged group, you can add it with the `group => title` pair syntax:

```@example legendorder2
draw(spec1 + spec2_custom_scale; legend = (; order = [[:Color, :color2] => "Title"]))
```

## Figure options

AlgebraOfGraphics can add a title, subtitle and footnotes to a figure automatically.
Settings for these must be passed to the `figure` keyword.
Check the [`draw`](@ref) function for a complete list.

```@example
using AlgebraOfGraphics
using CairoMakie

spec = pregrouped(
    fill(1:5, 6),
    fill(11:15, 6),
    [reshape(sin.(1:25), 5, 5) .+ i for i in 1:6],
    layout = 1:6 => nonnumeric) * visual(Heatmap)

draw(
    spec;
    figure = (;
        title = "Numbers in square configuration",
        subtitle = "Arbitrary data exhibits sinusoidal properties",
        footnotes = [
            rich(superscript("1"), "First footnote"),
            rich(superscript("2"), "Second ", rich("footnote", color = :red)),
        ],
    ),
    axis = (; width = 100, height = 100)
)
```
