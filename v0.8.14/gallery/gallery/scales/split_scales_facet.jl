using AlgebraOfGraphics, CairoMakie

dat = data((;
    fruit = rand(["Apple", "Orange", "Pear"], 150),
    taste = randn(150) .* repeat(1:3, inner = 50),
    weight = repeat(["Heavy", "Light", "Medium"], inner = 50),
    cost = randn(150) .+ repeat([10, 20, 30], inner = 50),
))

fruit = :fruit => "Fruit" => scale(:X1)
weights = :weight => "Weight" => scale(:Y1)
taste = :taste => "Taste Score" => scale(:X2)
cost = :cost => "Cost" => scale(:Y2)

layer1 = mapping(
    fruit,
    weights,
    col = direct("col1"), # this controls what facet this mapping belongs to
    row = direct("row1")
) * frequency()

layer2 = mapping(
    fruit,
    cost,
    col = direct("col1"),
    row = direct("row2")
) * visual(Violin)

layer3 = mapping(
    weights, # note X and Y are flipped here for a horizontal violin
    taste,
    col = direct("col2"),
    row = direct("row1")
) * visual(Violin, orientation = :horizontal)

layer4 = mapping(
    taste,
    cost,
    col = direct("col2"),
    row = direct("row2")
) * visual(Scatter)

spec = dat * (layer1 + layer2 + layer3 + layer4)

fg = draw(spec, scales(Row = (; show_labels = false), Col = (; show_labels = false)))

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
