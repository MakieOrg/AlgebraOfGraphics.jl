# ---
# title: Pre-grouped data
# cover: assets/pregrouped_data.png
# description: Working with arrays of arrays
# author: "[Pietro Vertechi](https://github.com/piever)"
# ---

using AlgebraOfGraphics, CairoMakie
set_aog_theme!() #src


x = [rand(10) for i in 1:3]
y = [rand(10) for i in 1:3]
z = [rand(10) for i in 1:3]
c = ["a", "b", "c"]

m = mapping(x, y, color=c => (t -> "Type " * t ) => "Category")
draw(m)

#

m = mapping(x, (y, z) => (+) => "sum", color=c => (t -> "Type " * t ) => "Category")
draw(m)

#

m = mapping(x, [y z], color=dims(1) => renamer(["a", "b", "c"]))
draw(m)

#

m = mapping(x, [y z], color=["1" "2"])
layers = visual(Scatter) + linear()
fg = draw(m * layers)


# save cover image #src
mkpath("assets") #src
save("assets/pregrouped_data.png", fg) #src
