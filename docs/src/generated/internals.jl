# # Internals
#
# AlgebraOfGraphics is based on *contexts*, which can be extended. Each context is then
# associated to a named tuple `data` (used for `x`, `y` axes or attributes in the plot)
# and a named tuple `primary` used for grouping, forming a `ContextualPair`.
#
# ## Contexts
#
# In the default context, all variables in `data` are broadcasted to a common shape, and
# each entry correspond to a separate trace. The syntax `dims` exists to allow setting 
# `primary` variables that only vary with one of the dimensions.

using RDatasets: dataset
using AlgebraOfGraphics: table, data, primary
d = data(:Cyl, :Hwy) |> primary(color = :Year)

# The `primary => data` pairs corresponding to each group can be accessed with `Base.pairs`:

pairs(d)

# The `DataContext` is invoked with `table(df)`, where `df` respects the Tables.jl interface.
# `DefaultContext`s can be merged onto a `DataContext` (column names are replaced by the
# corresponding arrays).

mpg = dataset("ggplot2", "mpg")
t = table(mpg)
pairs(t |> d)

# The `SliceContext` is another example. It is invoked with `slice(I::Int...)`, and signals
# along which dimension on the data to slice to extract series.

using AlgebraOfGraphics: slice, dims
ctx = slice(1)
x = rand(5, 3, 2)
y = rand(5, 3)
pairs(slice(1) |> data(x, y) |> primary(color=dims(2), marker=dims(3)))

# ## Combining operations using trees
#
# Under the hood, all outputs of `primary`, `data`, `table`, and `slice` inherit from
# (oriented) `AbstractEdge`. `AbstractEdge`s (and more generally `Tree`s) can be combined
# using `+` (join at the root), or `*` (attach the root of one at the leaf of the other).

mpg1 = copy(mpg)
mpg1.Displ = mpg.Displ .* 0.1
tree = (table(mpg) + table(mpg1)) * data(:Hwy, :Displ) * primary(color=:Cyl)

# The resulting `Tree` is a lazy representation of the operations to be performed. One can
# inspect the results by calling

using AlgebraOfGraphics: outputs
outputs(tree)

# or even

using AbstractPlotting, CairoMakie, MakieLayout
using AlgebraOfGraphics: spec, draw
tree * spec(Scatter, markersize=10px) |> draw
AbstractPlotting.save("tree.svg", AbstractPlotting.current_scene()); nothing #hide

# ![](tree.svg)
#
# ## Implementing a new context
#
# To implement a new context, one needs to:
#
# - inherit from `AbstractEdge` (to support `+` and `*` operations),
#
# - define a method `(s2::DefaultContext)(s1::MyContext)` (to allow applying `primary` and `data` to `MyContext`),
#
# - define `Base.pairs(s::MyContext)`, which iterates `primary => data` pairs.
# 
# See example implementation in the [context file](https://github.com/JuliaPlots/AlgebraOfGraphics.jl/blob/master/src/context.jl).
