# # Internals
#
# AlgebraOfGraphics is based on *contexts*, which can be extended. A context, together with
# a named tuple (used for `x`, `y` axes or attributes in the plot) forms a `Bind`.
# Each `Bind` can actually encode many traces, encoded as a list of `NamedTuple => Bind`
# pairs, accessible using `pairs(st::Bind)`.
#
# ## Contexts
#
# The `DataContext` is invoked with `data(df)`, where `df` respects the Tables.jl interface.

using RDatasets: dataset
using AlgebraOfGraphics
mpg = dataset("ggplot2", "mpg")
t = data(mpg)
st = bind(:Cyl, color = :Year => categorical)

pairs(t * st)

# In the `dims(i)` context, all variables in `bind` are sliced along the `i`-th dimension.
# The resulting arrays of arrays broadcasted to a common shape, and
# each "inner array" corresponds to a separate trace. The syntax `dims` exists to allow setting 
# discrete attributes variables that only vary with one of the dimensions.

d = dims(1) * bind(rand(5, 3, 2), rand(5, 3), color = dims(2))
pairs(d)

# ## Combining binds and contexts together
#
# All outputs of `bind`, `data`, and `dims` inherit can be combined using `+`
# (adding a new layer), or `*` (merge information in existing layer).

using AbstractPlotting, CairoMakie
mpg1 = copy(mpg)
mpg1.Displ = mpg.Displ .* 0.1
ts = data(mpg) * visual(markersize = 5) + data(mpg1) * visual(markersize=10)
sl = ts * bind(:Hwy, :Displ, color = :Cyl => categorical)

# The result can then be plotted using the `draw` function:

sl * visual(Scatter) |> draw
AbstractPlotting.save("combine.svg", AbstractPlotting.current_scene()); nothing #hide

# ![](combine.svg)
#
# ## Implementing a new context
#
# To implement a new context, one can overload:
#
# - `AlgebraOfGraphics._merge(c::MyContext, s1::Bind, s2::Bind)`, to allow applying `bind` to `MyContext`,
#
# - `AlgebraOfGraphics._pairs(c::MyContext, s::Bind)`, which must iterates `group::NamedTuple => bind::Bind` pairs.
# 
# See example implementation in the [context file](https://github.com/JuliaPlots/AlgebraOfGraphics.jl/blob/master/src/context.jl).
