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

mpg |> merge(cols, grp, scat)

plot(scat * cols)

# Now I can simply add `grp` to do the grouping

plot(scat * cols * grp)

# This is almost a recipe with scatter and linear regression :)
# It can be applied to the arguments just by multiplying them
lin = analysis(linear) * metadata(linewidth = 5)
plots = scat + lin
plot(plots * cols)

# Again, if I multiply by the grouping, I add it to the scene

plot(plots * cols * grp)

# This is a more complex example, where I want to split the scatter,
# but do the linear regression with all the data
different_grouping = grp * scat + lin
plot(cols * different_grouping)

# ## Pipeline

Under the hood, `table`, `data`, `primary`, `analysis`, and `metadata` generate an underspecified `Spec` object. These `Spec`s can be combined with `*` (merging the information), and `+` (making lists of `Spec`s). The two operation interact following the distributive law.

# ## Examples

using AlgebraOfGraphics: data

ts1 = data(rand(10));

ts2 = Sum(data.(eachcol(rand(10, 3))), :color)

plot(scat * ts1 * ts2)

ts1 = Sum(data.(eachcol(rand(10, 3))), :marker);

ts2 = Sum(data.(eachcol(rand(10, 3))), :color);

plot(scat * ts1 * ts2)

# The framework does not requires that the objects listed in `Traces` are columns. They could be anything that the plotting package can deal with.

ts1 = Sum(data.([-pi..0, 0..pi]), :color);

ts2 = Sum(data.([sin, cos]), :linestyle);

plot(ts1 * ts2, linewidth = 10)

