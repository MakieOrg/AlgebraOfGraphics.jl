# # Tutorial
#
# Here we will see what are the basic building blocks of AlgebraOfGraphics, and how to
# combine them to create complex plots based on tables or other style formats.
#
# ## Basic building blocks
#
# The most important functions are `style`, and `spec`.
# `style` determines the mapping from data to plot. Its positional arguments correspond to
# the `x`, `y` or `z` axes of the plot, whereas the keyword arguments correspond to plot
# attributes that can vary continuously or discretely, such as `color` or `markersize`.
# The style is split according to the categorical attributes in it, and then styled using
# a default palette.
# Finally `spec` can be used to give style-independent specifications about the plot
# (plotting function or attributes).
#
# `style` and `spec` work in various context. In the following we will explore
# `DataContext`, which is introduced doing `data(df)` for any tabular style structure `df`.
# In this context, `style` and `group` accept symbols and integers, which correspond to
# columns of the data.
#
# ## Operations
#
# The outputs of `style`, `spec`, and `data` can be combined with `+` or `*`,
# to generate an `AlgebraicList` object, which can then be plotted using the
# function `draw`. The actual drawing is done by AbstractPlotting.
#
# The operation `+` is used to create separate layer. `a + b` has as many layers as `la + lb`,
# where `la` and `lb` are the number of layers in `a` and `b` respectively.
#
# The operation `a * b` create `la * lb` layers, where `la` and `lb` are the number of layers
# in `a` and `b` respectively. Each layer of `a * b` contains the combined information of
# the corresponding layer in `a` and the corresponding layer in `b`. In simple cases,
# however, both `a` and `b` will only have one layer, and `a * b` simply combines the
# information.
#
# ## Working with tables

using RDatasets: dataset
using AlgebraOfGraphics, AbstractPlotting, CairoMakie
mpg = dataset("ggplot2", "mpg");
cols = style(:Displ, :Hwy);
grp = style(color = :Cyl => categorical);
scat = spec(Scatter)
pipeline = cols * scat
data(mpg) * pipeline |> draw
AbstractPlotting.save("scatter.svg", AbstractPlotting.current_scene()); nothing #hide

# ![](scatter.svg)
#
# Now let's simply add `grp` to the pipeline to style the color.

data(mpg) * grp * pipeline |> draw
AbstractPlotting.save("grouped_scatter.svg", AbstractPlotting.current_scene()); nothing #hide

# ![](grouped_scatter.svg)
# Traces can be added together with `+`.

using AlgebraOfGraphics: linear
pipenew = cols * (scat + linear)
data(mpg) * pipenew |> draw
AbstractPlotting.save("linear.svg", AbstractPlotting.current_scene()); nothing #hide

# ![](linear.svg)
# We can put grouping in the pipeline (we get a warning because of a degenerate group).

data(mpg) * grp * pipenew |> draw
AbstractPlotting.save("grouped_linear.svg", AbstractPlotting.current_scene()); nothing #hide

# ![](grouped_linear.svg)
# This is a more complex example, where we split the scatter plot,
# but do the linear regression with all the style. Moreover, we pass weights to `linear`
# to compute the regression line with weighted least squares.

different_grouping = grp * scat + linear * style(wts=:Hwy)
data(mpg) * cols * different_grouping |> draw
AbstractPlotting.save("semi_grouped.svg", AbstractPlotting.current_scene()); nothing #hide

# ![](semi_grouped.svg)
#
# Different analyses are also possible, always with the same syntax:

using AlgebraOfGraphics: smooth, density
data(mpg) * cols * grp * (scat + smooth(span = 0.8)) |> draw
AbstractPlotting.save("loess.svg", AbstractPlotting.current_scene()); nothing #hide

# ![](loess.svg)

data(mpg) * cols * density |> draw
AbstractPlotting.save("density.svg", AbstractPlotting.current_scene()); nothing #hide

# ![](density.svg)
#
# We can also add styling that only makes sense in one spec (e.g. `markersize`) by
# multiplying them:
#
newstyle = style(markersize = :Cyl) * spec(markersize = (0.1, 5))
data(mpg) * cols * (scat * newstyle + smooth(span = 0.8)) |> draw
AbstractPlotting.save("loess_markersize.svg", AbstractPlotting.current_scene()); nothing #hide

# ![](loess_markersize.svg)
#
# ## Layout
#
# Thanks to the MakieLayout package it is possible to create plots where categorical variables
# inform the layout.

iris = dataset("datasets", "iris")
cols = style(:SepalLength, :SepalWidth)
grp = style(layout_x = :Species)
geom = spec(Scatter) + linear
data(iris) * cols * grp * geom |> draw
AbstractPlotting.save("layout.svg", AbstractPlotting.current_scene()); nothing #hide

# ![](layout.svg)
#
# ## Non tabular style (slicing context)
#
# The framework is not specific to tables., but can be used in different contexts.
# For instance, `dims()` introduces a context where each entry of the array corresponds
# to a trace.

x = [-pi..0, 0..pi]
y = [sin cos] # We use broadcasting semantics on `tuple.(x, y)`.
dims() * style(x, y, color = dims(1), linestyle = dims(2)) |> draw
AbstractPlotting.save("functions.svg", AbstractPlotting.current_scene()); nothing #hide

# ![](functions.svg)

using Distributions
IGpdf(μ, λ) = t -> pdf(InverseGaussian(μ, λ), t)
pdfs = IGpdf.(1:4, [6 10])
dims() * style(fill(0..5), pdfs, color = dims(1), linestyle = dims(2)) |> draw
AbstractPlotting.save("distributions.svg", AbstractPlotting.current_scene()); nothing #hide

# ![](distributions.svg)
#
# More generally, one can pass arguments to `dims` to implement the
# "slices are series" approach.

s = dims(1) * style(rand(50, 3), rand(50, 3, 2))
grp = style(color = dims(2), layout_x = dims(3))
s * grp * spec(Scatter) |> draw
AbstractPlotting.save("arrays.svg", AbstractPlotting.current_scene()); nothing #hide

# ![](arrays.svg)

# This approach can be used in combination with the tabular context to work
# with "wide" data, where grouping is done by column.

iris = dataset("datasets", "iris")
cols = style([:SepalLength, :SepalWidth], [:PetalLength :PetalWidth])
grp = style(layout_x = dims(1), layout_y = dims(2), color = :Species)
geom = spec(Scatter) + linear
data(iris) * cols * grp * geom |> draw
AbstractPlotting.save("layout_wide.svg", AbstractPlotting.current_scene()); nothing #hide

# ![](layout_wide.svg)
