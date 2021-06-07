# Frequently Asked Questions

## What is the algebraic structure of AlgebraOfGraphics?

AlgebraOfGraphics is based on two operators, `+` and `*`. The algebraic structure these
operators induce is that of a [semiring](https://en.wikipedia.org/wiki/Semiring), with a small
caveat. Addition is commutative only up to the drawing order. For example `visual(Lines) + visual(Scatter)`
is slightly different from `visual(Scatter) + visual(Lines)`, in that the former draws the scatter on top
of the lines, and the latter draws the lines on top of the scatter. As a consequence, only right distributivity
holds with full generality, while left distributivity only holds up to the drawing order.

## Why is the mapping pair syntax different from DataFrames?

The transformations passed within a mapping, e.g. `mapping(:x => log => "log(x)")`, are applied
element-wise, whereas operations that require the whole column are not supported on purpose.
An important reason to prefer row-wise operations (other than performance) is that whole-column operations
can be error prone in this setting, especially when

- the data is grouped or
- different datasets are used.

If you do need column-wise transformations, consider implementing a custom analysis, such as `density`,
which takes the whole data as input, or apply the transformation directly in your data before
passing it to AlgebraOfGraphics.

See also [Pair syntax](@ref) for a detailed description of the pair syntax within a `mapping`

## What is the difference between axis scales and data transformations?

There are two overlapping but distinct approaches to rescale data. One can either transform
the data directly, e.g. `mapping(:x => log => "log(x)")`, or keep the data as is and use
a nonlinear scale, e.g. by passing `axis = (xscale = log,)` to the `draw` function.

Note that the resulting plots may "look different" in some cases. Consider for instance
the following example.

```@example logscaledensity
using AlgebraOfGraphics
using AlgebraOfGraphics: density
df = (x = exp.(randn(1000)),)
kde1 = data(df) * mapping(:x) * density()
draw(kde1, axis=(width=225, height=225, xscale=log,))
```

```@example logscaledensity
df = (x = exp.(randn(1000)),)
kde2 = data(df) * mapping(:x => log => "log(x)") * density()
draw(kde2, axis=(width=225, height=225))
```

The two plots look different. The first represent the pdf of `x` in a log scale,
while the second represent the pdf of `log(x)` in a linear scale. The two curves
are distinct: they differ by a factor `1 / x`, the derivative of `log(x)`.
See e.g.
[this post](https://math.stackexchange.com/questions/613614/scaling-a-probability-distribution-function/613623#613623)
for a more detailed explanation.

In general the second approach (plotting the density of `log(x)`) could be considered
more principled, as the total are under the density curve will be `1`, which would not
be the case when showing the density of `x` in a log scale.

The same reasoning applies to histograms:

```@example logscalehist
using AlgebraOfGraphics
df = (x = exp.(rand(1000)),)
hist1 = data(df) * mapping(:x) * histogram()
draw(hist1, axis=(width=225, height=225, xscale=log))
```

```@example logscalehist
df = (x = exp.(rand(1000)),)
hist2 = data(df) * mapping(:x => log => "log(x)") * histogram()
draw(hist2, axis=(width=225, height=225))
```

The data transformation approach is preferable as it produces uniform bins.
