using AlgebraOfGraphics, CairoMakie, DataFrames

countries = ["Algeria", "Bolivia", "China", "Denmark", "Ecuador", "France"]
group = ["2", "3", "1", "1", "3", "2"]
some_value = exp.(sin.(1:6))

df = DataFrame(; countries, group, some_value)
sort!(df, :some_value)

df

spec = data(df) *
    mapping(:countries, :some_value, color = :group) *
    visual(BarPlot, direction = :x)
draw(spec)

spec = data(df) *
    mapping(:countries => presorted, :some_value, color = :group) *
    visual(BarPlot, direction = :x)
fg = draw(spec)

spec = data(df) *
    mapping(:countries => presorted, :some_value, color = :group => presorted) *
    visual(BarPlot, direction = :x)
draw(spec)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
