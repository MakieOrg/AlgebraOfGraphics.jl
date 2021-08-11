# ---
# title: Discrete scales
# cover: assets/discrete_scales.png
# author: "[Pietro Vertechi](https://github.com/piever)"
# ---

using AlgebraOfGraphics, CairoMakie
set_aog_theme!() #src

# By default categorical ticks, as well as names from legend entries, are taken from the 
# value of the variable converted to a string. Scales can be equipped with labels to
# overwrite that

df = (x=rand(["a", "b", "c"], 100), y=rand(100))
plt = data(df) * mapping(:x, :y) * visual(BoxPlot)
draw(plt)

#

df = (x=rand(["a", "b", "c"], 100), y=rand(100))
plt = data(df) *
    mapping(
        :x => renamer("a" => "label1", "b" => "label2", "c" => "label3"),
        :y
    ) * visual(BoxPlot)
draw(plt)

# The order can also be changed by tweaking the scale

plt = data(df) *
    mapping(
        :x => renamer("b" => "label b", "a" => "label a", "c" => "label c"),
        :y
    ) * visual(BoxPlot)
fg = draw(plt)

# save cover image #src
mkpath("assets") #src
save("assets/discrete_scales.png", fg) #src
