# Pre-grouped data

````@example pre_grouped_data
using AlgebraOfGraphics, CairoMakie


x = [rand(10) .+ i for i in 1:3]
y = [rand(10) .+ i for i in 1:3]
z = [rand(10) .+ i for i in 1:3]
c = ["a", "b", "c"]

m = pregrouped(x, y, color=c => (t -> "Type " * t ) => "Category")
draw(m)
````

````@example pre_grouped_data
m = pregrouped(x, (y, z) => (+) => "sum", color=c => (t -> "Type " * t ) => "Category")
draw(m)
````

````@example pre_grouped_data
m = pregrouped(x, [y z], color=dims(1) => renamer(["a", "b", "c"])) * visual(Scatter)
draw(m)
````

````@example pre_grouped_data
m = pregrouped(x, [y z], color=["1" "2"])
layers = visual(Scatter) + linear()
fg = draw(m * layers)
````

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

