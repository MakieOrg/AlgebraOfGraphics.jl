# AlgebraOfGraphics

[![Build Status](https://travis-ci.org/piever/AlgebraOfGraphics.jl.svg?branch=master)](https://travis-ci.org/piever/AlgebraOfGraphics.jl)
[![codecov.io](http://codecov.io/github/piever/AlgebraOfGraphics.jl/coverage.svg?branch=master)](http://codecov.io/github/piever/AlgebraOfGraphics.jl?branch=master)

Define a "plotting package agnostic" algebra of graphics based on a few simple building blocks that can be combined using `*` and `+`. Highly experimental proof of concept, which may break often.

## Demo

```julia
using RDatasets: dataset

using AlgebraOfGraphics: table, data, primary, metadata
using AbstractPlotting, GLMakie

mpg = dataset("ggplot2", "mpg");
cols = data(:Displ, :Hwy);
grp = primary(color = :Cyl);
scat = metadata(Scatter, markersize = 10px)

mpg |> table |> cols |> scat |> plot
```

![test](https://user-images.githubusercontent.com/6333339/76689571-0add6900-662f-11ea-9881-918ea426e571.png)

Now I can simply add `grp` to do the grouping

```julia
mpg |> table |> cols |> grp |> scat |> plot
```

![test](https://user-images.githubusercontent.com/6333339/76689579-234d8380-662f-11ea-8626-3071283f96be.png)
This is almost a recipe with scatter and linear regression :)
It can be applied to the arguments just by multiplying them

```julia
using StatsMakie: linear
lin = metadata(linear, linewidth = 5)
mpg |> table |> cols |> scat + lin |> plot
```

![test](https://user-images.githubusercontent.com/6333339/77187183-fafcd380-6acb-11ea-89fa-a9e570f2b4dd.png)
Again, if I multiply by the grouping, I add it to the scene (we filter to avoid a degenerate group).

```julia
filter(row -> row.Cyl != 5, mpg) |> table |> cols |> scat + lin |> grp |> plot
```

![test](https://user-images.githubusercontent.com/6333339/77187043-c426bd80-6acb-11ea-8c4f-bac6a53652e3.png)
This is a more complex example, where I want to split the scatter,
but do the linear regression with all the data

```julia
different_grouping = (grp |> scat) + lin
mpg |> table |> cols |> different_grouping |> plot
```

![test](https://user-images.githubusercontent.com/6333339/77187226-0bad4980-6acc-11ea-8676-cbb7ee08843c.png)

## Pipeline

Under the hood, `primary`, `data`, and `metadata` generate an underspecified `Trace` object. These `Trace`s can be combined with `*` (merging the information), and `+` (making lists of `Trace`s). The two operation interact following the distributive law.
The framework does not requires that the objects listed in `Traces` are columns. They could be anything that the plotting package can deal with.

```julia
using AlgebraOfGraphics: dims
x = [-pi..0, 0..pi]
y = [sin cos]
spec = data(x, y) |> primary(color = dims(1), linestyle = dims(2))
plot(spec, linewidth = 10)
```

![test](https://user-images.githubusercontent.com/6333339/76711535-e05fde80-6708-11ea-8790-8b20a4a5cf7c.png)

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

