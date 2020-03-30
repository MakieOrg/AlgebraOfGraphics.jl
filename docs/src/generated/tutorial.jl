# # Tutorial
#
# Below are some examples on how to use AlgebraOfGraphics to create plots based on tables
# or other data formats.
# The most important functions are `primary`, `data`, and `spec`. They generate
# `SeriesList` objects, which can be combined with `*` (merge information),
# or `+` (add as separate layers). The resulting `SeriesList` can then be plotted with a
# package that supports it (so far MakieLayout).
#
# `data` determines what is the data to be plotted. Its positional arguments correspond to
# the `x`, `y.` or `z` axes of the plot, whereas the keyword arguments correspond to plot
# attributes that can vary continuously, such as `color` or `markersize`. `primary`
# determines the grouping of the data. The data is split according to the variables listed
# in `primary`, and then styled using a default palette. Finally `spec` can be used to
# give data-independent specifications about the plot (plotting function or attributes).
#
# `data`, `primary`, and `spec` work in various context. In the following we will explore
# `DataContext`, which is introduced doing `table(df)` for any tabular data structure `df`.
# In this context, `data` and `primary` accept symbols and integers, which correspond to
# columns of the table.
#
# ## Working with tables

using RDatasets: dataset
using AbstractPlotting, CairoMakie, MakieLayout
using AlgebraOfGraphics: table, data, primary, spec, draw
mpg = dataset("ggplot2", "mpg");
cols = data(:Displ, :Hwy);
grp = primary(color = :Cyl);
scat = spec(Scatter, markersize = 10px)
pipeline = cols * scat
table(mpg) * pipeline |> draw
AbstractPlotting.save("scatter.svg", AbstractPlotting.current_scene()); nothing #hide

# ![](scatter.svg)
#
# Now let's simply add `grp` to the pipeline to do the grouping.

table(mpg) * grp * pipeline |> draw
AbstractPlotting.save("grouped_scatter.svg", AbstractPlotting.current_scene()); nothing #hide

# ![](grouped_scatter.svg)
# Traces can be added together with `+`.

using StatsMakie: linear
lin = spec(linear, linewidth = 5)
pipenew = cols * (scat + lin)
table(mpg) * pipenew |> draw
AbstractPlotting.save("linear.svg", AbstractPlotting.current_scene()); nothing #hide

# ![](linear.svg)
# We can put grouping in the pipeline (we filter to avoid a degenerate group).

table(filter(row -> row.Cyl != 5, mpg)) * grp * pipenew |> draw
AbstractPlotting.save("grouped_linear.svg", AbstractPlotting.current_scene()); nothing #hide

# ![](grouped_linear.svg)
# This is a more complex example, where we split the scatter plot,
# but do the linear regression with all the data.
different_grouping = grp * scat + lin
table(mpg) * cols * different_grouping |> draw
AbstractPlotting.save("semi_grouped.svg", AbstractPlotting.current_scene()); nothing #hide

# ![](semi_grouped.svg)
#
# ## Non tabular data
#
# The framework is not specific to tables, but can be used with anything that the plotting
# package supports.

using AlgebraOfGraphics: dims
x = [-pi..0, 0..pi]
y = [sin cos] # We use broadcasting semantics on `tuple.(x, y)`.
data(x, y) * primary(color = dims(1), linestyle = dims(2)) * spec(linewidth = 10) |> draw
AbstractPlotting.save("functions.svg", AbstractPlotting.current_scene()); nothing #hide

# ![](functions.svg)

using Distributions
mus = 1:4
shapes = [6, 10]
gs = InverseGaussian.(mus, shapes')
geom = spec(linewidth = 5)
grp = primary(color = dims(1), linestyle = dims(2))
data(fill(0..5), gs) * grp * geom |> draw
AbstractPlotting.save("distributions.svg", AbstractPlotting.current_scene()); nothing #hide

# ![](distributions.svg)
#
# ## Layout
#
# Thanks to the MakieLayout package it is possible to create plots where categorical variables
# inform the layout.

iris = dataset("datasets", "iris")
cols = data([:SepalLength, :SepalWidth], [:PetalLength :PetalWidth])
grp = primary(layout_x = dims(1), layout_y = dims(2), color = :Species)
geom = spec(Scatter, markersize = 10px) + spec(linear, linewidth = 3)
table(iris) * cols * grp * geom |> draw
AbstractPlotting.save("layout.svg", AbstractPlotting.current_scene()); nothing #hide

# ![](layout.svg)
#
# ## Slicing context
#
# The algebra of graphics logic can be easily extended to novel contexts.
# For example, `slice` implements the "slices are series" approach.

using AlgebraOfGraphics: slice
s = slice(1) * data(rand(50, 3), rand(50, 3, 2))
grp = primary(color = dims(2), layout_x = dims(3))
s * grp * spec(Scatter, markersize = 10px) |> draw
AbstractPlotting.save("arrays.svg", AbstractPlotting.current_scene()); nothing #hide

# ![](arrays.svg)
