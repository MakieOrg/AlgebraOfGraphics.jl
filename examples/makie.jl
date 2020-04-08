using AbstractPlotting, GLMakie

using AlgebraOfGraphics
using AlgebraOfGraphics: data
using AlgebraOfGraphics: linear, smooth

using RDatasets: dataset

iris = dataset("datasets", "iris")
d = style(:SepalLength, :SepalWidth, color = :Species)
s = spec(Scatter) + smooth
data(iris) * d * s |> draw

data(iris) * style(:SepalLength, :SepalWidth, color = :PetalLength) * spec(:Scatter) |> draw

# data(iris) * d * spec(Wireframe, density) |> draw

cols = style([:PetalLength, :PetalWidth], [:SepalLength :SepalWidth])
st = style(color = dims(1), marker = dims(2))
data(iris) * cols * st * spec(Scatter, markersize = 10px) |> draw

dims() * style([rand(100), rand(100)], Ref(rand(100)), color = Ref(rand(100)), marker = dims(1)) * spec(Scatter, markersize=10px) |> draw

dims() * style((randn(1000), rand(100)), color = dims(1)) * spec(density, linewidth=10) |> draw

# TODO fix stacking and choose edges globally
style((randn(1000), rand(100))) * style(color = 1:2) * spec(histogram(edges = -3:0.1:3)) |> draw

using AbstractPlotting, GLMakie, MakieLayout
using AlgebraOfGraphics: dims, style, spec, draw
using RDatasets: dataset
using CategoricalArrays: categorical
iris = dataset("datasets", "iris")
iris.Rare = rand(Bool, 150)
d = style([:SepalLength, :SepalWidth], [:PetalLength :PetalWidth])
grp = style(layout_x = dims(1), layout_y = dims(2), color = :Rare => categorical)
s = spec(Scatter, markersize = 10px) #+ spec(linear)
data(iris) * d * grp * s |> draw

dims(1) * style(rand(5, 3, 2), rand(5, 3), color = dims(2), marker = dims(3)) * spec(Scatter, markersize = 20px) |> draw

