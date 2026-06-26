using AlgebraOfGraphics, CairoMakie

df = (x=rand(["a", "b", "c"], 100), y=rand(100))
plt = data(df) * mapping(:x, :y) * visual(BoxPlot)
draw(plt)

plt = data(df) * mapping(:x, :y) * visual(BoxPlot)
draw(plt, scales(X = (;
    categories = ["a" => "label1", "b" => "label2", "c" => "label3"]
)))

plt = data(df) *
    mapping(
        :x => renamer("a" => "label1", "b" => "label2", "c" => "label3"),
        :y
    ) * visual(BoxPlot)
draw(plt)

plt = data(df) * mapping(:x, :y) * visual(BoxPlot)
draw(plt, scales(X = (;
    categories = ["a", "missing", "b", "c"]
)))

plt = data(df) * mapping(:x, :y) * visual(BoxPlot)
draw(plt, scales(X = (;
    categories = ["b" => "label b", "a" => "label a", "c" => "label c"]
)))

plt = data(df) *
    mapping(
        :x => renamer("b" => "label b", "a" => "label a", "c" => "label c"),
        :y
    ) * visual(BoxPlot)
fg = draw(plt)

df1 = (; x = rand(["one", "two"], 100), y = randn(100))
df2 = (; x = rand(["three", "four"], 50), y = randn(50))
plt = (data(df1) + data(df2)) * mapping(:x, :y) * visual(BoxPlot)
draw(plt)

draw(plt, scales(X = (;
    categories = ["one", "two", "three", "four"]
)))

df = (; name = ["Anna Coolidge", "Berta Bauer", "Charlie Archer"], age = [34, 79, 58])
plt = data(df) * mapping(:name, :age) * visual(BarPlot)
draw(plt)

draw(plt, scales(X = (;
    categories = cats -> sort(cats; by = name -> split(name)[2])
)))

function initialed(name)
    a, b = split(name)
    return name => "$(first(a)). $b"
end

draw(plt, scales(X = (;
    categories = cats -> initialed.(sort(cats; by = name -> split(name)[2]))
)))

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
