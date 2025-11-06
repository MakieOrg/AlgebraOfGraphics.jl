```@meta
EditURL = "analyses.jl"
```

# Analyses

## Histogram

```@docs
histogram
```

```@example analyses
using AlgebraOfGraphics, CairoMakie
set_aog_theme!()

df = (x=randn(5000), y=randn(5000), z=rand(["a", "b", "c"], 5000))
specs = data(df) * mapping(:x, layout=:z) * histogram(bins=range(-2, 2, length=15))
draw(specs)
```

```@example analyses
specs = data(df) * mapping(:x, dodge=:z, color=:z) * histogram(bins=range(-2, 2, length=15))
draw(specs)
```

```@example analyses
specs = data(df) * mapping(:x, stack=:z, color=:z) * histogram(bins=range(-2, 2, length=15))
draw(specs)
```

```@example analyses
specs = data(df) *
    mapping((:x, :z) => ((x, z) -> x + 5 * (z == "b")) => "new x", col=:z) *
    histogram(datalimits=extrema, bins=20)
draw(specs, facet=(linkxaxes=:minimal,))
```

```@example analyses
data(df) * mapping(:x, :y, layout=:z) * histogram(bins=15) |> draw
```

## Density

```@docs
AlgebraOfGraphics.density
```

```@example analyses
df = (x=randn(5000) .+ repeat([0, 2, 4, 6], inner = 1250), y=randn(5000), z=repeat(["a", "b", "c", "d"], inner = 1250))
specs = data(df) * mapping(:x, layout=:z) * AlgebraOfGraphics.density()

draw(specs)
```

```@example analyses
data(df) * mapping(:x, layout=:z) * AlgebraOfGraphics.density(datalimits = (0, 8)) |> draw
```

```@example analyses
draw(specs * visual(direction = :y))
```

```@example analyses
specs = data(df) *
    mapping((:x, :z) => ((x, z) -> x + 5 * (z ∈ ["b", "d"])) => "new x", layout=:z) *
    AlgebraOfGraphics.density(datalimits=extrema)
draw(specs, facet=(linkxaxes=:minimal,))
```

```@example analyses
data(df) * mapping(:x, :y, layout=:z) * AlgebraOfGraphics.density(npoints=50) |> draw
```

```@example analyses
specs = data(df) * mapping(:x, :y, layout=:z) *
    AlgebraOfGraphics.density(npoints=50) * visual(Surface)

draw(specs, axis=(type=Axis3, zticks=0:0.1:0.2, limits=(nothing, nothing, (0, 0.2))))
```

## Frequency

```@docs
frequency
```

```@example analyses
df = (x=rand(["a", "b", "c"], 100), y=rand(["a", "b", "c"], 100), z=rand(["a", "b", "c"], 100))
specs = data(df) * mapping(:x, layout=:z) * frequency()
draw(specs)
```

```@example analyses
specs = data(df) * mapping(:x, layout=:z, color=:y, stack=:y) * frequency()
draw(specs)
```

```@example analyses
specs = data(df) * mapping(:x, :y, layout=:z) * frequency()
draw(specs)
```

## Expectation

```@docs
expectation
```

```@example analyses
df = (x=rand(["a", "b", "c"], 100), y=rand(["a", "b", "c"], 100), z=rand(100), c=rand(["a", "b", "c"], 100))
specs = data(df) * mapping(:x, :z, layout=:c) * expectation()
draw(specs)
```

```@example analyses
specs = data(df) * mapping(:x, :z, layout=:c, color=:y, dodge=:y) * expectation()
draw(specs)
```

```@example analyses
specs = data(df) * mapping(:x, :y, :z, layout=:c) * expectation()
draw(specs)
```

## Linear

```@docs
linear
```

```@example analyses
x = 1:0.05:10
a = rand(1:7, length(x))
y = 1.2 .* x .+ a .+ 0.5 .* randn.()
df = (; x, y, a)
specs = data(df) * mapping(:x, :y, color=:a => nonnumeric) * (linear() + visual(Scatter))
draw(specs)
```

## Smoothing

```@docs
smooth
```

```@example analyses
x = 1:0.05:10
a = rand(1:7, length(x))
y = sin.(x) .+ a .+ 0.1 .* randn.()
df = (; x, y, a)
specs = data(df) * mapping(:x, :y, color=:a => nonnumeric) * (smooth() + visual(Scatter))
draw(specs)
```

## Contours

```@docs
contours
```

```@example analyses
x = repeat(1:10, 10)
y = repeat(11:20, inner = 10)
z = sqrt.(x .* y)
df = (; x, y, z)
specs = data(df) * mapping(:x, :y, :z) * contours(levels = 8)
draw(specs)
```

```@example analyses
x = repeat(1:10, 10)
y = repeat(11:20, inner = 10)
z = sqrt.(x .* y)
df = (; x, y, z)
specs = data(df) * mapping(:x, :y, :z) * contours(levels = 8, labels = true)
draw(specs)
```

## Filled Contours

```@docs
filled_contours
```

```@example analyses
x = repeat(1:10, 10)
y = repeat(11:20, inner = 10)
z = sqrt.(x .* y)
df = (; x, y, z)
specs = data(df) * mapping(:x, :y, :z) * filled_contours(levels = 3:2:15)
draw(specs)
```

Because `filled_contours` bands are represented as categories of `Bin`s under the hood, you cannot use the settings `colormap`, `highclip` and `lowclip` as known from continuous colors. The `clipped` helper can be used to turn a palette into one that will set high and low clip colors on top of another palette.
In combination with `from_continuous`, this works well with `filled_contours` when bands reach to minus or plus infinity:

```@example analyses
x = repeat(1:10, 10)
y = repeat(11:20, inner = 10)
z = sqrt.(x .* y)
df = (; x, y, z)
specs = data(df) *
    mapping(:x, :y, :z) *
    filled_contours(levels = [-Inf, 5, 8, 10, 12, 13, 14, Inf])
draw(specs, scales(Color = (; palette = clipped(from_continuous(:plasma), low = :cyan, high = :red))))
```

## Aggregate

```@docs
aggregate
```

The `aggregate` transformation allows you to perform flexible aggregations on your data.
All mapped columns that are not explicitly aggregated are automatically used for grouping.

This analysis layer is intended for aggregations that are only needed for a visualization, otherwise it may make more sense to compute values in a separate data wrangling step and add a separate `data` layer.

### Basic Aggregation

Compute the mean body mass for each penguin species:

```@example analyses
using AlgebraOfGraphics
using Statistics

penguins = AlgebraOfGraphics.penguins()

data(penguins) *
    mapping(:species, :body_mass_g) *
    aggregate(2 => mean) *
    visual(BarPlot) |> draw
```

### Multiple Grouping Dimensions

Group by both species and sex, computing mean body mass:

```@example analyses
data(penguins) *
    mapping(:species, :body_mass_g, color = :sex, dodge = :sex) *
    aggregate(2 => mean) *
    visual(BarPlot) |> draw
```

### Aggregating Multiple Columns

Compute both mean and standard deviation:

```@example analyses
data(penguins) *
    mapping(:species, :body_mass_g) *
    (
        aggregate(2 => mean) * visual(BarPlot) +
        aggregate(2 => mean, 2 => std => 3) * visual(Errorbars)
    ) |> draw
```

### Splitting Aggregation Results

Sometimes an aggregation function may return multiple values which
should form separate inputs for the subsequent visual. In this
case you can assign a vector of accessor specifications via the pair syntax.
Each vector element must specify an accessor function (here `first` and `last`) and the mapping that the result should be assigned to, either given as integers for positional arguments or symbols for named arguments.

```@example analyses
data(penguins) *
    mapping(:species, :body_mass_g, color = :sex, dodge_x = :sex) *
    aggregate(2 => extrema => [first => 2, last => 3]) *
    visual(Rangebars, linewidth = 3) |> draw(scales(DodgeX = (; width = 0.2)))
```

### Vector-Valued Aggregations

Aggregate functions can return vectors, which will be automatically expanded. If you have another aggregation that returns scalars, the scalars will be repeated to match the length of the vector aggregation. If you have multiple aggregations returning vectors, the lengths of all vectors in a given group must be the same.

```@example analyses
# Get lower and upper quartiles as a vector
lower_upper_quartile(x) = quantile(x, [0.25, 0.75])

data(penguins) *
    mapping(:species, :body_mass_g, color = :sex) *
    aggregate(2 => lower_upper_quartile) *
    visual(Scatter, markersize = 15) |> draw
```

### Custom Labels

Provide custom labels for aggregated outputs:

```@example analyses
data(penguins) *
    mapping(:species, :body_mass_g) *
    aggregate(2 => mean => "Average Mass (g)") *
    visual(BarPlot) |> draw
```
