# Mapping

Mappings determine how the data is translated into a plot.
For example, this `mapping` maps columns `weight` and `height` to positional arguments 1 and 2, and `age` to the `markersize` attribute of the `Scatter` plotting function:

```julia
mapping(:weight, :height, markersize = :age)
```

```@docs
mapping
```

## Aesthetics

The structure of a `mapping` is always directly tied to the signature of the plotting function (or analysis) that it is being connected with.
What visual aspects of the plot the positional or keyword arguments affect depends on the plotting function in use.

To be used with AlgebraOfGraphics, a plotting function has to add a declaration which aesthetics (like X, Y, Color, MarkerSize, LineStyle) its arguments map to.
This mechanism allows AlgebraOfGraphics to correctly convert the raw input data into visual attributes for each plotting function and to correctly create and label axes, colorbars and legends.

Aesthetics can also change depending on attributes passed to `visual`.

For example, for a `BarPlot`, args 1 and 2 correspond to the X and Y aesthetics by default.
But if you change the direction in the `visual`, then axis labels shift accordingly because the aesthetic mapping has changed to 1 = Y, 2 = X:

```@example
using AlgebraOfGraphics
using CairoMakie

df = (; name = ["Anna", "Beatrix", "Claire"], height_meters = [1.55, 1.76, 1.63])
m = mapping(:name, :height_meters)
spec1 = data(df) * m * visual(BarPlot)
spec2 = data(df) * m * visual(BarPlot, direction = :x)

f = Figure()
draw!(f[1, 1], spec1)
draw!(f[1, 2], spec2)
f
```

## Hardcoded aesthetics

Most aesthetics are tied to specific attributes of plot types, for example like `AesColor` to `strokecolor` of `Scatter`.
There are a few aesthetics, however, which are hardcoded to belong to certain `mapping` keywords independent of the plot type in use.

These are `layout`, `row` and `col` for facetting, `group` for creating a separate plot for each group (like separate lines instead of one long line) and `dodge_x` and `dodge_y` for dodging.

### Grouping

A common case is that multiple lines should be drawn for a population, but all with the same color. Without any grouping, the lines will all be connected in a zig-zag pattern. The `group` keyword can be used to create a separate plot per group, splitting up the lines.

```@example
using AlgebraOfGraphics
using CairoMakie

spec = data((;
   x = repeat(1:10, 8),
   y = reduce(vcat, [(1:10) .+ i for i in 1:8]),
   id = repeat(string.('A':'H'), inner = 10),
)) * mapping(:x, :y) * visual(Lines)

f = Figure()
draw!(f[1, 1], spec; axis = (; title = "no group"))
draw!(f[1, 2], spec * mapping(group = :id); axis = (; title = "group = :id"))
f
```

### Dodging

Dodging refers to the shifting of plots on a (usually categorical) scale depending on the group they belong to.
It is used to avoid overlaps. Some plot types, like `BarPlot`, have their own `dodge` keyword because their dodging logic additionally needs to transform the visual elements (for example, dodging a bar plot makes thinner bars). For all other plot types, you can use the generic `dodge_x` and `dodge_y` keywords.

They work by shifting each categorical group by some value that depends on the chosen "dodge width".
The dodge width refers to the width that all dodged elements in a group add up to at a given point.
Some plot types have an inherent width, like barplots. Others have no width, like scatters or errorbars.
For those plot types that have no width to use for dodging, you have to specify one manually in `scales`.

Here's an example of a manual width selection:

```@example
using AlgebraOfGraphics
using CairoMakie

df = (
   x = repeat(1:10, inner = 2),
   y = cos.(range(0, 2pi, length = 20)),
   ylow = cos.(range(0, 2pi, length = 20)) .- 0.2,
   yhigh = cos.(range(0, 2pi, length = 20)) .+ 0.3,
   dodge = repeat(["A", "B"], 10)
)

f = Figure()
plt = data(df) * (
   mapping(:x, :y, dodge_x = :dodge, color = :dodge) * visual(Scatter) +
   mapping(:x, :ylow, :yhigh, dodge_x = :dodge, color = :dodge) * visual(Rangebars)
)
draw!(f[1, 1], plt, scales(DodgeX = (; width = 1)), axis = (; title = "width = 1"))
draw!(f[1, 2], plt, scales(DodgeX = (; width = 0.75)), axis = (; title = "width = 0.75"))
draw!(f[2, 1], plt, scales(DodgeX = (; width = 0.5)), axis = (; title = "width = 0.5"))
draw!(f[2, 2], plt, scales(DodgeX = (; width = 0.25)), axis = (; title = "width = 0.25"))
f
```

A common scenario is plotting errorbars on top of barplots.
In this case, AlgebraOfGraphics can detect the inherent dodging width of the barplots and adjust accordingly for the errorbars. Note in this example how choosing a manual dodging width only applies to the errorbars (because the barplot plot type handles this internally) and potentially leads to a misalignment between the different plot elements:

```@example
using AlgebraOfGraphics
using CairoMakie

df = (
   x = repeat(1:10, inner = 2),
   y = cos.(range(0, 2pi, length = 20)),
   ylow = cos.(range(0, 2pi, length = 20)) .- 0.2,
   yhigh = cos.(range(0, 2pi, length = 20)) .+ 0.3,
   dodge = repeat(["A", "B"], 10)
)

f = Figure()
plt = data(df) * (
   mapping(:x, :y, dodge = :dodge, color = :dodge) * visual(BarPlot) +
   mapping(:x, :ylow, :yhigh, dodge_x = :dodge) * visual(Rangebars)
)
draw!(f[1, 1], plt, axis = (; title = "No width specified, auto-determined by AlgebraOfGraphics"))
draw!(f[2, 1], plt, scales(DodgeX = (; width = 0.25)), axis = (; title = "Manually specifying width = 0.25 leads to a mismatch"))
f
```

## Pair syntax

The `Pair` operator `=>` can be used for three different purposes within `mapping`:

- renaming columns
- transforming columns by row
- mapping data to a custom scale

## Renaming columns

```@example
using AlgebraOfGraphics
using CairoMakie

data((; name = ["Anna", "Beatrix", "Claire"], height_meters = [1.55, 1.76, 1.63])) *
   mapping(:name => "Name", :height_meters => "Height (m)") *
   visual(BarPlot) |> draw 
```

## Transforming columns

If a `Function` is paired to the column selector, it is applied by row to the data.
Often, you will want to also assign a new name that fits the transformed data, in which case you
can use the three-element `column => transformation => name` syntax:

```@example
using AlgebraOfGraphics
using CairoMakie

data((; name = ["Anna", "Beatrix", "Claire"], height_meters = [1.55, 1.76, 1.63])) *
   mapping(:name => (n -> n[1] * "."), :height_meters => (x -> x * 100) => "Height (cm)") *
   visual(BarPlot) |> draw
```

### Row-by-row versus whole-column operations

The pair syntax acts *row by row*, unlike, e.g., `DataFrames.transform`.
This has several advantages.

- Simpler for the user in most cases.
- Less error prone especially
   - with grouped data (should a column operation apply to each group or the whole dataset?)
   - when several datasets are used

Naturally, this also incurs some downsides, as whole-column operations, such as
z-score standardization, are not supported:
they should be done by adding a new column to the underlying dataset beforehand.

### Functions of several arguments

In the case of functions of several arguments, such as `isequal`, the input
variables must be passed as a `Tuple`.

```julia
accuracy = (:species, :predicted_species) => isequal => "accuracy"
```

### Helper functions

Some helper functions are provided, which can be used within the pair syntax to
either rename and reorder *unique values* of a categorical column on the fly or to
signal whether a numerical column should be treated as categorical.

The complete API of helper functions is available at [Mapping helpers](@ref), but here are a few examples:

```julia
# column `train` has two unique values, `true` and `false`
:train => renamer([true => "training", false => "testing"]) => "Dataset"
# column `price` has three unique values, `"low"`, `"medium"`, and `"high"`
:price => sorter(["low", "medium", "high"])
# column `age` is expressed in integers and we want to treat it as categorical
:age => nonnumeric
# column `labels` is expressed in strings and we do not want to treat it as categorical
:labels => verbatim
# wrap categorical values to signal that the order from the data source should be respected
:weight => presorted
```

## Custom scales

All columns mapped to the same aesthetic type are represented using the same scale by default.
This is evident if you plot two different datasets with two different plot types.

In the following example, both `Scatter` and `HLines` use the `Color` aesthetic, `Scatter` for the `strokecolor` keyword and `HLines` for `color`.
A single merged legend is rendered for both, which does not have a title because it derives from two differently named columns.

```@example scales
using AlgebraOfGraphics
using CairoMakie

df_a = (; x = 1:9, y = [1, 2, 3, 5, 6, 7, 9, 10, 11], group = repeat(["A", "B", "C"], inner = 3))

spec1 = data(df_a) * mapping(:x, :y, strokecolor = :group) * visual(Scatter, color = :transparent, strokewidth = 3, markersize = 15)

df_b = (; y = [4, 8], threshold = ["first", "second"])

spec2 = data(df_b) * mapping(:y, color = :threshold) * visual(HLines)

draw(spec1 + spec2)
```

If we want to have separate legends for both, we can assign a custom scale identifier to either the `strokecolor` or the `color` mapping.
The name can be chosen freely, it serves only to disambiguate.

```@example scales
spec2_custom_scale = data(df_b) * mapping(:y, color = :threshold => scale(:color2)) * visual(HLines)

draw(spec1 + spec2_custom_scale)
```

Each scale can be customized further by passing configuration options via `scales` as the second argument of the `draw` function.
More information on scale options can be found under [Scale options](@ref).

As an example, we can pass separate colormaps using the `palette` keyword:

```@example scales
spec2_custom_scale = data(df_b) * mapping(:y, color = :threshold => scale(:color2)) * visual(HLines)

draw(
   spec1 + spec2_custom_scale,
   scales(
      Color = (; palette = [:red, :green, :blue]),
      color2 = (; palette = [:gray30, :gray80]),
   )
)
```
