using AlgebraOfGraphics: data, spec, primary, dims, table, draw, to_dict
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
d = data(x = :SepalLength, y = :SepalWidth) * primary(layout_x = :Species) * spec(mode = "markers")
table(iris) * d |> myplot

# table(iris) * d * spec(Wireframe, density) |> draw

cols = data(x = [:PetalLength, :PetalWidth], y = [:SepalLength :SepalWidth])
style = primary(marker = (color = dims(1), symbol = dims(2),)) * spec(mode = "markers", type = "scatter")
table(iris) * cols * style |> myplot

dims(1) *
    data(x = rand(5, 3, 2), y = rand(5, 3)) *
    primary(marker = (color = dims(2),)) *
    spec(mode = "markers") |> to_dict

