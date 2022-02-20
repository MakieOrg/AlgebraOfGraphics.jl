# ---
# title: Time series
# cover: assets/time_series.png
# description: Visualizing time series data.
# author: "[Pietro Vertechi](https://github.com/piever)"
# ---

using AlgebraOfGraphics, CairoMakie
using Dates
set_aog_theme!() #src

x = today() - Year(1) : Day(1) : today()
y = cumsum(randn(length(x)))
z = cumsum(randn(length(x)))
df = (; x, y, z)
labels = ["series 1", "series 2", "series 3", "series 4", "series 5"]
plt = data(df) *
    mapping(:x, [:y, :z] .=> "value", color=dims(1) => renamer(labels) => "series ") *
    visual(Lines)
draw(plt)

#

x = now() - Hour(6) : Minute(1) : now()
y = cumsum(randn(length(x)))
z = cumsum(randn(length(x)))
df = (; x, y, z)
plt = data(df) *
    mapping(:x, [:y, :z] .=> "value", color=dims(1) => renamer(labels) =>"series ") *
    visual(Lines)
fg = draw(plt)


# save cover image #src
mkpath("assets") #src
save("assets/time_series.png", fg) #src
