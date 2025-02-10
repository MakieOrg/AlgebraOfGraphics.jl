# Regression plots

````@example regression_plots
using AlgebraOfGraphics, CairoMakie

x = rand(100)
y = @. randn() + x
df = (; x, y)
xy = data(df) * mapping(:x, :y)
layers = linear() + visual(Scatter)
draw(layers * xy)
````

````@example regression_plots
x = rand(100)
y = @. randn() + 5 * x ^ 2
df = (; x, y)
xy = data(df) * mapping(:x, :y)
layers = smooth() + visual(Scatter)
fg = draw(layers * xy)
````

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

