# Axis options

````@example axis
using AlgebraOfGraphics, CairoMakie
````

To tweak one or more axes, simply use the `axis` keyword when plotting. For example

````@example axis
df = (x=rand(100), y=rand(100), z=rand(100))
layers = linear() + mapping(color=:z)
plt = data(df) * layers * mapping(:x, :y)
draw(plt, axis=(aspect=1,))
````

````@example axis
fg = draw(plt, axis=(aspect=1, xticks=0:0.1:1, yticks=0:0.1:1, ylabel="custom label"))
````

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

