using AlgebraOfGraphics, CairoMakie

df = (x=rand(["a", "b", "c"], 100), y=rand(100))
plt = data(df) * mapping(:x, :y) * visual(BoxPlot)
draw(plt)

df = (x=rand(["a", "b", "c"], 100), y=rand(100))
plt = data(df) *
    mapping(
        :x => renamer("a" => "label1", "b" => "label2", "c" => "label3"),
        :y
    ) * visual(BoxPlot)
draw(plt)

plt = data(df) *
    mapping(
        :x => renamer("b" => "label b", "a" => "label a", "c" => "label c"),
        :y
    ) * visual(BoxPlot)
fg = draw(plt)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

