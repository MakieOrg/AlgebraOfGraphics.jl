# # AlgebraOfGraphics

# [![Build Status](https://travis-ci.org/piever/AlgebraOfGraphics.jl.svg?branch=master)](https://travis-ci.org/piever/AlgebraOfGraphics.jl)
# [![codecov.io](http://codecov.io/github/piever/AlgebraOfGraphics.jl/coverage.svg?branch=master)](http://codecov.io/github/piever/AlgebraOfGraphics.jl?branch=master)

# Define a "plotting package agnostic" algebra of graphics based on a few simple building blocks that can be combined using `+` and `*`. Highly experimental proof of concept, which may break often.
# The functions `primary`, `data`, and `spec` generate `Tree` objects. These `Tree`s can be combined with `*` (vertical composition), or `+` (horizontal composition). The resulting `Tree` can then be plotted with a package that supports it.

# ## Demo

using RDatasets: dataset

using AlgebraOfGraphics: table, data, primary, spec
using AbstractPlotting, GLMakie

mpg = dataset("ggplot2", "mpg");
cols = data(:Displ, :Hwy);
grp = primary(color = :Cyl);
scat = spec(Scatter, markersize = 10px)
pipeline = cols * scat

table(mpg) * pipeline |> plot

# ![test](https://user-images.githubusercontent.com/6333339/76689571-0add6900-662f-11ea-9881-918ea426e571.png)

# Now I can simply add `grp` to the pipeline to do the grouping.

table(mpg) * grp * pipeline |> plot

# ![test](https://user-images.githubusercontent.com/6333339/76689579-234d8380-662f-11ea-8626-3071283f96be.png)
#
# Traces can be added together with `+`.

using StatsMakie: linear
lin = spec(linear, linewidth = 5)
pipenew = cols * (scat + lin)
table(mpg) * pipenew |> plot

# ![test](https://user-images.githubusercontent.com/6333339/77187183-fafcd380-6acb-11ea-89fa-a9e570f2b4dd.png)
# We can put grouping in the pipeline (we filter to avoid a degenerate group).

table(filter(row -> row.Cyl != 5, mpg)) * grp * pipenew |> plot

# ![test](https://user-images.githubusercontent.com/6333339/77187043-c426bd80-6acb-11ea-8c4f-bac6a53652e3.png)
# This is a more complex example, where I want to split the scatter,
# but do the linear regression with all the data

different_grouping = grp * scat + lin
table(mpg) * cols * different_grouping |> plot

# ![test](https://user-images.githubusercontent.com/6333339/77187226-0bad4980-6acc-11ea-8676-cbb7ee08843c.png)
#
# ## Non tabular data

# The framework is not specific to tables, but can be used with anything that the plotting package supports.

using AlgebraOfGraphics: dims
x = [-pi..0, 0..pi]
y = [sin cos]
# We use broadcasting semantics on `tuple.(x, y)`.
data(x, y) * primary(color = dims(1), linestyle = dims(2)) * spec(linewidth = 10) |> plot

# ![test](https://user-images.githubusercontent.com/6333339/76711535-e05fde80-6708-11ea-8790-8b20a4a5cf7c.png)
#
# ## Layout
#
# Using the MakieLayout package it is possible to create plots where categorical variables inform the layout.

using MakieLayout
using AlgebraOfGraphics: dims, layoutplot
using StatsMakie: linear
iris = dataset("datasets", "iris")
cols = data([:SepalLength, :SepalWidth], [:PetalLength :PetalWidth])
grp = primary(layout_x = dims(1), layout_y = dims(2), color = :Species)
geom = spec(Scatter, markersize = 10px) + spec(linear, linewidth = 3)
table(iris) * cols * grp * geom |> layoutplot
#
# ![scatter](https://user-images.githubusercontent.com/6333339/77751711-1f9e0180-701e-11ea-85f8-608064d0f3dd.png)
#
# ## Slicing context
#
# The algebra of graphics logic can be easily extended to novel context.
# For example, `slice` implements the "slices are series" approach of Plots.

using MakieLayout
using AlgebraOfGraphics: slice, primary, data, spec, dims, layoutplot
s = slice(1) * data(rand(5, 3), rand(5, 3, 2))
grp = primary(color = dims(2), layout_x = dims(3))
s * grp * spec(Scatter, markersize = 10px) |> layoutplot

# ![layout](https://user-images.githubusercontent.com/6333339/77761800-7e6c7680-7030-11ea-992c-0acc22d2d61c.png)
