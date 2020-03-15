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
