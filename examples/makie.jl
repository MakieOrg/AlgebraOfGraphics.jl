using AbstractPlotting, GLMakie
using StatsMakie: linear, density, histogram

using AlgebraOfGraphics: data, spec, primary, dims, table

using RDatasets: dataset

iris = dataset("datasets", "iris")
d = data(:SepalLength, :SepalWidth) * primary(color = :Species)
s = spec(Scatter, markersize = 10px) + spec(linear)
table(iris) * d * s |> plot

table(iris) * d * spec(Wireframe, density) |> plot

x = data([:PetalLength, :PetalWidth])
y = data([:SepalLength :SepalWidth])
style = primary(color = dims(1), marker = dims(2))
s = table(iris) * x * y * style |> scatter

data([rand(10), rand(10)], Ref(rand(10)), color = Ref(rand(100))) * primary(marker = 1:2) |> scatter
data((randn(1000), rand(100))) * primary(color = 1:2) * spec(density, linewidth=10) |> plot

# TODO fix stacking and choose edges globally
data((randn(1000), rand(100))) * primary(color = 1:2) * spec(histogram(edges = -3:0.1:3)) |> plot

using Distributions
mus = 1:4
shapes = [6, 10]
gs = InverseGaussian.(mus, shapes')
geom = spec(linewidth = 5)
grp = primary(color = dims(1), linestyle = dims(2))
data(fill(0..5), gs) * grp * geom |> plot
