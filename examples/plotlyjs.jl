using AlgebraOfGraphics: style, spec, group, dims, data, draw, to_dict
using AlgebraOfGraphics
import DefaultApplication

using RDatasets: dataset

function myplot(s)
    file = tempname() * ".html"
    AlgebraOfGraphics.writeplot(s, file)
    DefaultApplication.open(file)
    return file
end

iris = dataset("datasets", "iris")
d = style(x = :SepalLength, y = :SepalWidth) * group(layout_x = :Species) * spec(mode = "markers")
data(iris) * d |> myplot

cols = style(x = [:PetalLength, :PetalWidth], y = [:SepalLength :SepalWidth])
style = group(marker = (color = dims(1), symbol = dims(2),)) * spec(mode = "markers", type = "scatter")
data(iris) * cols * style |> myplot

style = group(marker = (color = :Species,), layout_x = dims(1), layout_y = dims(2)) *
    spec(mode = "markers", type = "scatter")
data(iris) * cols * style |> myplot

dims(1) *
    style(x = rand(5, 3, 2), y = rand(5, 3)) *
    group(marker = (color = dims(2),)) *
    spec(mode = "markers", type = "scatter") |> myplot

