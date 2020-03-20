# # AlgebraOfGraphics

# [![Build Status](https://travis-ci.org/piever/AlgebraOfGraphics.jl.svg?branch=master)](https://travis-ci.org/piever/AlgebraOfGraphics.jl)
# [![codecov.io](http://codecov.io/github/piever/AlgebraOfGraphics.jl/coverage.svg?branch=master)](http://codecov.io/github/piever/AlgebraOfGraphics.jl?branch=master)

# Define a "plotting package agnostic" algebra of graphics based on a few simple building blocks that can be combined using `*` and `+`. Highly experimental proof of concept, which may break often. Examples below require running the code in examples/makie.jl.

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

# ![test](https://user-images.githubusercontent.com/6333339/76689587-49732380-662f-11ea-8d36-dae71b919d7b.png)
# Again, if I multiply by the grouping, I add it to the scene

mpg = filter(row -> row.Cyl != 5, mpg) # matrix is degenerate otherwise
mpg |> cols * (scat + lin) * grp |> plot

# ![test](https://user-images.githubusercontent.com/6333339/76689612-8f2fec00-662f-11ea-8b9e-dd7ce1aff8bd.png)
# This is a more complex example, where I want to split the scatter,
# but do the linear regression with all the data

different_grouping = grp * scat + lin
mpg |> cols * different_grouping |> plot

# ![test](https://user-images.githubusercontent.com/6333339/76689601-6c053c80-662f-11ea-8998-1723fb7b2dff.png)
# ## Pipeline

# Under the hood, `primary`, `data`, and `metadata` generate an underspecified `Trace` object. These `Trace`s can be combined with `*` (merging the information), and `+` (making lists of `Trace`s). The two operation interact following the distributive law.

# ## Examples

using AlgebraOfGraphics: data

ts1 = data(rand(10));

ts2 = TraceList(data.(eachcol(rand(10, 3))), :color)

scat * ts1 * ts2 |> plot

# ![test](https://user-images.githubusercontent.com/6333339/76711577-549a8200-6709-11ea-8c9b-f2bcd56adbc9.png)

ts1 = Sum(data.(eachcol(rand(10, 3))), :marker);

ts2 = Sum(data.(eachcol(rand(10, 3))), :color);

plot(scat * ts1 * ts2)

# ![test](https://user-images.githubusercontent.com/6333339/76711603-7c89e580-6709-11ea-8207-99e8b55112e3.png)
# The framework does not requires that the objects listed in `Traces` are columns. They could be anything that the plotting package can deal with.

ts1 = Sum(data.([-pi..0, 0..pi]), :color);

ts2 = Sum(data.([sin, cos]), :linestyle);

plot(ts1 * ts2, linewidth = 10)

# ![test](https://user-images.githubusercontent.com/6333339/76711535-e05fde80-6708-11ea-8790-8b20a4a5cf7c.png)

