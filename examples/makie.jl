using AbstractPlotting, GLMakie, MakieLayout
using StatsMakie: linear, density, histogram

using AlgebraOfGraphics: data, spec, primary, dims, table, draw

using RDatasets: dataset

iris = dataset("datasets", "iris")
d = data(:SepalLength, :SepalWidth) * primary(color = :Species)
s = spec(Scatter, markersize = 10px) + spec(linear)
table(iris) * d * s |> draw

table(iris) * d * spec(Wireframe, density) |> draw

cols = data([:PetalLength, :PetalWidth], [:SepalLength :SepalWidth])
style = primary(color = dims(1), marker = dims(2))
table(iris) * cols * style * spec(Scatter) |> draw

data([rand(100), rand(100)], Ref(rand(100)), color = Ref(rand(100))) * primary(marker = 1:2) * spec(Scatter, markersize=10px) |> draw

data((randn(1000), rand(100))) * primary(color = 1:2) * spec(density, linewidth=10) |> draw

# TODO fix stacking and choose edges globally
data((randn(1000), rand(100))) * primary(color = 1:2) * spec(histogram(edges = -3:0.1:3)) |> draw

using AbstractPlotting, GLMakie, MakieLayout
using StatsMakie: linear
using AlgebraOfGraphics: dims, primary, data, spec, table, draw
using RDatasets: dataset
iris = dataset("datasets", "iris")
iris.Rare = rand(Bool, 150)
d = data([:SepalLength, :SepalWidth], [:PetalLength :PetalWidth])
grp = primary(layout_x = dims(1), layout_y = dims(2), color = :Species)
s = primary(marker = :Rare) * spec(Scatter, markersize = 10px) + spec(linear)
table(iris) * d * grp * s |> draw

using AlgebraOfGraphics: slice

slice(1) * data(rand(5, 3, 2), rand(5, 3)) * primary(color=dims(2)) * spec(Scatter) |> draw

