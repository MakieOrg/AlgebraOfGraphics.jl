using AlgebraOfGraphics, CairoMakie


x = [rand(10) for i in 1:3]
y = [rand(10) for i in 1:3]
z = [rand(10) for i in 1:3]
c = ["a", "b", "c"]

m = mapping(x, y, color=c => (t -> "Type " * t ) => "Category")
draw(m)

m = mapping(x, (y, z) => (+) => "sum", color=c => (t -> "Type " * t ) => "Category")
draw(m)

m = mapping(x, [y z], color=dims(1) => renamer(["a", "b", "c"]))
draw(m)

m = mapping(x, [y z], color=["1" "2"])
layers = visual(Scatter) + linear()
fg = draw(m * layers)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

