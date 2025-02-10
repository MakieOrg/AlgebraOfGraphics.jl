```@meta
EditURL = "analyses.jl"
```

# Analyses

## Histogram

```@docs
histogram
```

````@example analyses
using AlgebraOfGraphics, CairoMakie
set_aog_theme!()

df = (x=randn(5000), y=randn(5000), z=rand(["a", "b", "c"], 5000))
specs = data(df) * mapping(:x, layout=:z) * histogram(bins=range(-2, 2, length=15))
draw(specs)
````

````@example analyses
specs = data(df) * mapping(:x, dodge=:z, color=:z) * histogram(bins=range(-2, 2, length=15))
draw(specs)
````

````@example analyses
specs = data(df) * mapping(:x, stack=:z, color=:z) * histogram(bins=range(-2, 2, length=15))
draw(specs)
````

````@example analyses
specs = data(df) *
    mapping((:x, :z) => ((x, z) -> x + 5 * (z == "b")) => "new x", col=:z) *
    histogram(datalimits=extrema, bins=20)
draw(specs, facet=(linkxaxes=:minimal,))
````

````@example analyses
data(df) * mapping(:x, :y, layout=:z) * histogram(bins=15) |> draw
````

## Density

```@docs
AlgebraOfGraphics.density
```

````@example analyses
df = (x=randn(5000), y=randn(5000), z=rand(["a", "b", "c", "d"], 5000))
specs = data(df) * mapping(:x, layout=:z) * AlgebraOfGraphics.density(datalimits=((-2.5, 2.5),))

draw(specs)
````

````@example analyses
specs = data(df) *
    mapping((:x, :z) => ((x, z) -> x + 5 * (z ∈ ["b", "d"])) => "new x", layout=:z) *
    AlgebraOfGraphics.density(datalimits=extrema)
draw(specs, facet=(linkxaxes=:minimal,))
````

````@example analyses
data(df) * mapping(:x, :y, layout=:z) * AlgebraOfGraphics.density(npoints=50) |> draw
````

````@example analyses
specs = data(df) * mapping(:x, :y, layout=:z) *
    AlgebraOfGraphics.density(npoints=50) * visual(Surface)

draw(specs, axis=(type=Axis3, zticks=0:0.1:0.2, limits=(nothing, nothing, (0, 0.2))))
````

## Frequency

```@docs
frequency
```

````@example analyses
df = (x=rand(["a", "b", "c"], 100), y=rand(["a", "b", "c"], 100), z=rand(["a", "b", "c"], 100))
specs = data(df) * mapping(:x, layout=:z) * frequency()
draw(specs)
````

````@example analyses
specs = data(df) * mapping(:x, layout=:z, color=:y, stack=:y) * frequency()
draw(specs)
````

````@example analyses
specs = data(df) * mapping(:x, :y, layout=:z) * frequency()
draw(specs)
````

## Expectation

```@docs
expectation
```

````@example analyses
df = (x=rand(["a", "b", "c"], 100), y=rand(["a", "b", "c"], 100), z=rand(100), c=rand(["a", "b", "c"], 100))
specs = data(df) * mapping(:x, :z, layout=:c) * expectation()
draw(specs)
````

````@example analyses
specs = data(df) * mapping(:x, :z, layout=:c, color=:y, dodge=:y) * expectation()
draw(specs)
````

````@example analyses
specs = data(df) * mapping(:x, :y, :z, layout=:c) * expectation()
draw(specs)
````

## Linear

```@docs
linear
```

````@example analyses
x = 1:0.05:10
a = rand(1:7, length(x))
y = 1.2 .* x .+ a .+ 0.5 .* randn.()
df = (; x, y, a)
specs = data(df) * mapping(:x, :y, color=:a => nonnumeric) * (linear() + visual(Scatter))
draw(specs)
````

## Smoothing

```@docs
smooth
```

````@example analyses
x = 1:0.05:10
a = rand(1:7, length(x))
y = sin.(x) .+ a .+ 0.1 .* randn.()
df = (; x, y, a)
specs = data(df) * mapping(:x, :y, color=:a => nonnumeric) * (smooth() + visual(Scatter))
draw(specs)
````

## Contours

```@docs
contours
```

````@example analyses
x = repeat(1:10, 10)
y = repeat(11:20, inner = 10)
z = sqrt.(x .* y)
df = (; x, y, z)
specs = data(df) * mapping(:x, :y, :z) * contours(levels = 8)
draw(specs)
````

````@example analyses
x = repeat(1:10, 10)
y = repeat(11:20, inner = 10)
z = sqrt.(x .* y)
df = (; x, y, z)
specs = data(df) * mapping(:x, :y, :z) * contours(levels = 8, labels = true)
draw(specs)
````

## Filled Contours

```@docs
filled_contours
```

````@example analyses
x = repeat(1:10, 10)
y = repeat(11:20, inner = 10)
z = sqrt.(x .* y)
df = (; x, y, z)
specs = data(df) * mapping(:x, :y, :z) * filled_contours(levels = 3:2:15)
draw(specs)
````

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

