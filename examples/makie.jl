using AbstractPlotting, GLMakie
using Observables
using AbstractPlotting: SceneLike, PlotFunc
using StatsMakie: linear, density

using AlgebraOfGraphics, Test
using AlgebraOfGraphics: TraceList,
                         TraceOrList,
                         data,
                         metadata,
                         primary,
                         mixedtuple,
                         rankdicts,
                         traces

using RDatasets: dataset

iris = dataset("datasets", "iris")
spec = iris |> data(:SepalLength, :SepalWidth) * primary(color = :Species)
s = metadata(Scatter, markersize = 10px) + metadata(linear)
plot(s * spec)

plt = metadata(Wireframe, density) * spec |> plot
scatter!(plt, spec)

df = iris
x = data(:PetalLength) * primary(marker = fill(1)) +
    data(:PetalWidth) * primary(marker = fill(2))
y = data(:SepalLength, color = :SepalWidth)
df |> metadata(Scatter) * x * y |> plot

x = [-pi..0, 0..pi]
y = [sin, cos]
ts1 = sum(((i, el),) -> primary(color = i) * data(el), enumerate(x))
ts2 = sum(((i, el),) -> primary(linestyle = i) * data(el), enumerate(y))
plot(ts1 * ts2 * metadata(linewidth = 10))
