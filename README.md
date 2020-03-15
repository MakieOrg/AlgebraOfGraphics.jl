# AlgebraOfGraphics

[![Build Status](https://travis-ci.org/piever/AlgebraOfGraphics.jl.svg?branch=master)](https://travis-ci.org/piever/AlgebraOfGraphics.jl)
[![codecov.io](http://codecov.io/github/piever/AlgebraOfGraphics.jl/coverage.svg?branch=master)](http://codecov.io/github/piever/AlgebraOfGraphics.jl?branch=master)

Define a "plotting package agnostic" algebra of graphics based on a few simple building blocks that can be combined using `*` and `+`. Highly experimental proof of concept. Requires the branch StatsMakie/pv/aog to work in conjunction with Makie.

## Demo

```julia
using RDatasets: dataset

using StatsMakie: linear
using AbstractPlotting, GLMakie

using AlgebraOfGraphics: Data, Select, Group

mpg = dataset("ggplot2", "mpg");
cols = Data(mpg) * Select(:Displ, :Hwy);
grp = Group(color = :Cyl);

plot(Scatter * cols * Attributes(markersize=10px))
```

![test](https://user-images.githubusercontent.com/6333339/76689571-0add6900-662f-11ea-9881-918ea426e571.png)

```julia
# Now I can simply add `grp` to do the grouping
plot(Scatter * cols * grp * Attributes(markersize=10px))
```
![test](https://user-images.githubusercontent.com/6333339/76689579-234d8380-662f-11ea-8626-3071283f96be.png)

```julia
# This is almost a recipe with scatter and linear regression :)
# It can be applied to the arguments just by multiplying them
plots = Scatter * Attributes(markersize = 10px) + linear * Attributes(linewidth = 5)
plot(plots * cols)
```
![test](https://user-images.githubusercontent.com/6333339/76689587-49732380-662f-11ea-8d36-dae71b919d7b.png)

```julia
# Again, if I multiply by the grouping, I add it to the scene
plot(plots * cols * grp)
```
![test](https://user-images.githubusercontent.com/6333339/76689612-8f2fec00-662f-11ea-8b9e-dd7ce1aff8bd.png)

```julia
# This is a more complex example, where I want to split the scatter,
# but do the linear regression with all the data
different_grouping = grp * Scatter * Attributes(markersize = 10px) + linear * Attributes(linewidth = 5)
plot(cols * different_grouping)
```
![test](https://user-images.githubusercontent.com/6333339/76689601-6c053c80-662f-11ea-8998-1723fb7b2dff.png)

## Pipeline

Under the hood, `Group` and `Select` are combined into a `Traces` object, which contains a list of "traces" to be plotted, indexed by some primary keys, that will be used also to style the plot. The `Traces` object can also be passed by hand. It needs to iterate `Pair{NamedTuple, Select}`, where the named tuple acts as a "primary key". If there are multiple `Traces` objects, all the "consistent options" are kept (i.e. where the shared primary keys match). If the primary keys are "disjoint", all combinations are allowed. `counter` simply gives values from `1` to `n` to all the attributes that are passed to it as symbols.

## Examples

```julia
julia> using AlgebraOfGraphics: Select, Traces

julia> ts1 = Select(rand(10));

julia> ts2 = Traces(counter(:color), eachcol(rand(10, 3)));

julia> plot(Scatter * ts1 * ts2, markersize = 10px)
```

![test](https://user-images.githubusercontent.com/6333339/76711577-549a8200-6709-11ea-8c9b-f2bcd56adbc9.png)

```julia
julia> ts1 = Traces(counter(:marker), eachcol(rand(10, 3)));

julia> ts2 = Traces(counter(:color), eachcol(rand(10, 3)));

julia> plot(Scatter * ts1 * ts2, markersize = 10px)
```

![test](https://user-images.githubusercontent.com/6333339/76711603-7c89e580-6709-11ea-8207-99e8b55112e3.png)

The framework does not requires that the objects listed in `Traces` are columns. They could be anything that the plotting package can deal with.

```julia
julia> ts1 = Traces(counter(:color), [-pi..0, 0..pi]);

julia> ts2 = Traces(counter(:linestyle), [sin, cos]);

julia> plot(ts1 * ts2, linewidth = 10)
```

![test](https://user-images.githubusercontent.com/6333339/76711535-e05fde80-6708-11ea-8790-8b20a4a5cf7c.png)

