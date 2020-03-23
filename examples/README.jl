# # AlgebraOfGraphics

# [![Build Status](https://travis-ci.org/piever/AlgebraOfGraphics.jl.svg?branch=master)](https://travis-ci.org/piever/AlgebraOfGraphics.jl)
# [![codecov.io](http://codecov.io/github/piever/AlgebraOfGraphics.jl/coverage.svg?branch=master)](http://codecov.io/github/piever/AlgebraOfGraphics.jl?branch=master)

# Define a "plotting package agnostic" algebra of graphics based on a few simple building blocks that can be combined using broadcasting, `+`, and `|>` (used to be `*`). Highly experimental proof of concept, which may break often.

# ## Demo

using RDatasets: dataset

using AlgebraOfGraphics: table, data, primary, metadata
using AbstractPlotting, GLMakie

mpg = dataset("ggplot2", "mpg");
cols = data(:Displ, :Hwy);
grp = primary(color = :Cyl);
scat = metadata(Scatter, markersize = 10px)

mpg |> table |> cols |> scat |> plot

# ![test](https://user-images.githubusercontent.com/6333339/76689571-0add6900-662f-11ea-9881-918ea426e571.png)

# Now I can simply add `grp` to the pipeline to do the grouping.

mpg |> table |> cols |> grp |> scat |> plot

# ![test](https://user-images.githubusercontent.com/6333339/76689579-234d8380-662f-11ea-8626-3071283f96be.png)
#
# Traces can be added together with `+`.

using StatsMakie: linear
lin = metadata(linear, linewidth = 5)
mpg |> table |> cols |> scat + lin |> plot

# ![test](https://user-images.githubusercontent.com/6333339/77187183-fafcd380-6acb-11ea-89fa-a9e570f2b4dd.png)
# We can put grouping in the pipeline (we filter to avoid a degenerate group).

filter(row -> row.Cyl != 5, mpg) |> table |> cols |> grp |> scat + lin |> plot

# ![test](https://user-images.githubusercontent.com/6333339/77187043-c426bd80-6acb-11ea-8c4f-bac6a53652e3.png)
# This is a more complex example, where I want to split the scatter,
# but do the linear regression with all the data

different_grouping = (grp |> scat) + lin
mpg |> table |> cols |> different_grouping |> plot

# ![test](https://user-images.githubusercontent.com/6333339/77187226-0bad4980-6acc-11ea-8676-cbb7ee08843c.png)
#
# ## Pipeline

# Under the hood, `primary`, `data`, and `metadata` generate an underspecified `Trace` object. These `Trace`s can be combined with `|>` (merging the information), or `+` (plot on top of each other).
# The framework does not require that the objects listed in `Traces` are columns. They could be anything that the plotting package can deal with.

using AlgebraOfGraphics: dims
x = [-pi..0, 0..pi]
y = [sin cos]
# We use broadcasting semantics on `tuple.(x, y)`.
spec = data(x, y) |> primary(color = dims(1), linestyle = dims(2))
plot(spec, linewidth = 10)

# ![test](https://user-images.githubusercontent.com/6333339/76711535-e05fde80-6708-11ea-8790-8b20a4a5cf7c.png)
