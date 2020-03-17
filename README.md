# AlgebraOfGraphics

[![Build Status](https://travis-ci.org/piever/AlgebraOfGraphics.jl.svg?branch=master)](https://travis-ci.org/piever/AlgebraOfGraphics.jl)
[![codecov.io](http://codecov.io/github/piever/AlgebraOfGraphics.jl/coverage.svg?branch=master)](http://codecov.io/github/piever/AlgebraOfGraphics.jl?branch=master)

Define a "plotting package agnostic" algebra of graphics based on a few simple building blocks that can be combined using `*` and `+`. Highly experimental proof of concept, which may break often. Examples below require running the code in examples/makie.jl.

## Demo

```julia
using RDatasets: dataset

using StatsMakie: linear
using AbstractPlotting, GLMakie

using AlgebraOfGraphics: table, data, primary, analysis, metadata

mpg = dataset("ggplot2", "mpg");
cols = table(mpg) * data(:Displ, :Hwy);
grp = primary(color = :Cyl);
scat = metadata(Scatter, markersize = 10px)

plot(scat * cols)
```

![test](https://user-images.githubusercontent.com/6333339/76689571-0add6900-662f-11ea-9881-918ea426e571.png)

```julia
# Now I can simply add `grp` to do the grouping
plot(scat * cols * grp)
```
![test](https://user-images.githubusercontent.com/6333339/76689579-234d8380-662f-11ea-8626-3071283f96be.png)

```julia
# This is almost a recipe with scatter and linear regression :)
# It can be applied to the arguments just by multiplying them
lin = analysis(linear) * metadata(linewidth = 5)
plots = scat + lin
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
different_grouping = grp * scat + lin
plot(cols * different_grouping)
```
![test](https://user-images.githubusercontent.com/6333339/76689601-6c053c80-662f-11ea-8998-1723fb7b2dff.png)

## Pipeline

Under the hood, `table`, `data`, `primary`, `analysis`, and `metadata` generate an underspecified `Spec` object. These `Spec`s can be combined with `*` (merging the information), and `+` (making lists of `Spec`s). The two operation interact following the distributive law.

## Examples

```julia
julia> using AlgebraOfGraphics: data

julia> ts1 = data(rand(10));

julia> ts2 = Sum(data.(eachcol(rand(10, 3))), :color)

julia> plot(scat * ts1 * ts2)
```

![test](https://user-images.githubusercontent.com/6333339/76711577-549a8200-6709-11ea-8c9b-f2bcd56adbc9.png)

```julia
julia> ts1 = Sum(data.(eachcol(rand(10, 3))), :marker);

julia> ts2 = Sum(data.(eachcol(rand(10, 3))), :color);

julia> plot(scat * ts1 * ts2)
```

![test](https://user-images.githubusercontent.com/6333339/76711603-7c89e580-6709-11ea-8207-99e8b55112e3.png)

The framework does not requires that the objects listed in `Traces` are columns. They could be anything that the plotting package can deal with.

```julia
julia> ts1 = Sum(data.([-pi..0, 0..pi]), :color);

julia> ts2 = Sum(data.([sin, cos]), :linestyle);

julia> plot(ts1 * ts2, linewidth = 10)
```

![test](https://user-images.githubusercontent.com/6333339/76711535-e05fde80-6708-11ea-8790-8b20a4a5cf7c.png)

