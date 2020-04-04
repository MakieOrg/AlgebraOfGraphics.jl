using AbstractPlotting, GLMakie, MakieLayout

using AlgebraOfGraphics: style, spec, group, dims, data, draw, linear, smooth, AlgebraOfGraphics

using RDatasets: dataset

iris = dataset("datasets", "iris")
d = style(:SepalLength, :SepalWidth) * group(color = :Species)
s = spec(Scatter, markersize = 10px) + spec(smooth, linewidth = 3)
data(iris) * d * s |> draw

data(iris) * d * spec(Wireframe, density) |> draw

cols = style([:PetalLength, :PetalWidth], [:SepalLength :SepalWidth])
style = group(color = dims(1), marker = dims(2))
data(iris) * cols * style * spec(Scatter) |> draw

style([rand(100), rand(100)], Ref(rand(100)), color = Ref(rand(100))) * group(marker = 1:2) * spec(Scatter, markersize=10px) |> draw

style((randn(1000), rand(100))) * group(color = 1:2) * spec(density, linewidth=10) |> draw

# TODO fix stacking and choose edges globally
style((randn(1000), rand(100))) * group(color = 1:2) * spec(histogram(edges = -3:0.1:3)) |> draw

using AbstractPlotting, GLMakie, MakieLayout
using StatsMakie: linear
using AlgebraOfGraphics: dims, group, style, spec, data, draw
using RDatasets: dataset
iris = dataset("datasets", "iris")
iris.Rare = rand(Bool, 150)
d = style([:SepalLength, :SepalWidth], [:PetalLength :PetalWidth])
grp = group(layout_x = dims(1), layout_y = dims(2), color = :Species)
s = group(marker = :Rare) * spec(Scatter, markersize = 10px) + spec(linear)
data(iris) * d * grp * s |> draw

dims(1) *
    style(rand(5, 3, 2), rand(5, 3)) *
    group(color=dims(2)) *
    spec(Scatter, markersize = 20px) |> draw

