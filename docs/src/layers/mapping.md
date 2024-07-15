# Mapping

Mappings determine how the data is translated into a plot.
For example, this `mapping` maps columns `weight` and `height` to positional arguments 1 and 2, and `age` to the `markersize` attribute of the `Scatter` plotting function:

```
mapping(:weight, :height, markersize = :age)
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
