# # AlgebraOfGraphics

# [![Build Status](https://travis-ci.org/piever/AlgebraOfGraphics.jl.svg?branch=master)](https://travis-ci.org/piever/AlgebraOfGraphics.jl)
# [![codecov.io](http://codecov.io/github/piever/AlgebraOfGraphics.jl/coverage.svg?branch=master)](http://codecov.io/github/piever/AlgebraOfGraphics.jl?branch=master)

# Define a "plotting package agnostic" algebra of graphics based on a few simple building blocks that can be combined using `*` and `+`. Highly experimental proof of concept, which may break often.

# ## Demo

using RDatasets: dataset

using AlgebraOfGraphics: data, primary, metadata
using AbstractPlotting, GLMakie

mpg = dataset("ggplot2", "mpg");
cols = data(:Displ, :Hwy);
grp = primary(color = :Cyl);
scat = metadata(Scatter, markersize = 10px)

mpg |> cols * scat |> plot

# ![test](https://user-images.githubusercontent.com/6333339/76689571-0add6900-662f-11ea-9881-918ea426e571.png)

# Now I can simply add `grp` to do the grouping

mpg |> cols * grp * scat |> plot

# ![test](https://user-images.githubusercontent.com/6333339/76689579-234d8380-662f-11ea-8626-3071283f96be.png)
# This is almost a recipe with scatter and linear regression :)
# It can be applied to the arguments just by multiplying them

lin = metadata(linear, linewidth = 5)
mpg |> cols * (scat + lin) |> plot

# ![test](https://user-images.githubusercontent.com/6333339/77187183-fafcd380-6acb-11ea-89fa-a9e570f2b4dd.png)
# Again, if I multiply by the grouping, I add it to the scene (we filter to avoid a degenerate group).

filter(row -> row.Cyl != 5, mpg) |> cols * (scat + lin) * grp |> plot

# ![test](https://user-images.githubusercontent.com/6333339/77187043-c426bd80-6acb-11ea-8c4f-bac6a53652e3.png)
# This is a more complex example, where I want to split the scatter,
# but do the linear regression with all the data

different_grouping = grp * scat + lin
mpg |> cols * different_grouping |> plot

# ![test](https://user-images.githubusercontent.com/6333339/77187226-0bad4980-6acc-11ea-8676-cbb7ee08843c.png)
#
# ## Pipeline

# Under the hood, `primary`, `data`, and `metadata` generate an underspecified `Trace` object. These `Trace`s can be combined with `*` (merging the information), and `+` (making lists of `Trace`s). The two operation interact following the distributive law.
# The framework does not requires that the objects listed in `Traces` are columns. They could be anything that the plotting package can deal with.

using AlgebraOfGraphics: data

ts1 = data(-pi..0) * primary(color = 1) + data(0..pi) * primary(color = 2)
ts2 = data(sin) * primary(linestyle = 1) + data(cos) * primary(linestyle = 2)
ts1 * ts2 * metadata(linewidth = 10 ) |> plot

# ![test](https://user-images.githubusercontent.com/6333339/76711535-e05fde80-6708-11ea-8790-8b20a4a5cf7c.png)

