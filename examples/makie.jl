using AbstractPlotting, GLMakie
using StatsMakie: linear, density, histogram

using AlgebraOfGraphics: data, metadata, primary, dims, table

using RDatasets: dataset

iris = dataset("datasets", "iris")
spec = iris |> table |> data(:SepalLength, :SepalWidth) |> primary(color = :Species)
s = metadata(Scatter, markersize = 10px) + metadata(linear)
spec |> s |> plot

# Just as a test
spec |> metadata(linewidth = 3) .|> [metadata(Lines), metadata(linear)] |>
    primary(linestyle = dims(1)) |> plot

plt = spec |> metadata(Wireframe, density) |> plot
scatter!(plt, spec)

x = data.([:PetalLength, :PetalWidth])
y = data.([:SepalLength :SepalWidth])
s = iris |> table .|> x .|> y |> primary(color = dims(1), marker = dims(2)) |> scatter

data([rand(10), rand(10)], Ref(rand(10)), color = Ref(rand(100))) |> primary(marker = 1:2) |> scatter
(randn(1000), rand(100)) |> primary(color = 1:2) |> metadata(density, linewidth=10) |> plot

# TODO fix stacking and choose edges globally
(randn(1000), rand(100)) |>
    primary(color = 1:2) |>
    metadata(histogram(edges = -3:0.1:3)) |>
    plot

using Distributions
mus = 1:4
shapes = [6, 10]
gs = InverseGaussian.(mus, shapes')
geom = metadata(linewidth = 5)
grp = primary(color = dims(1), linestyle = dims(2))
data(fill(0..5), gs) |> grp |> geom |> plot

x = [-pi..0, 0..pi]
y = [sin cos]
spec = data(x, y) |> primary(color = dims(1), linestyle = dims(2))
plot(spec, linewidth = 10)
