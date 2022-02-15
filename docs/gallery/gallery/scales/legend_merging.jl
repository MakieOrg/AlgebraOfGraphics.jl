# ---
# title: Legend merging
# cover: assets/legend_merging.png
# description: Multiple scales for the same variable.
# author: "[Pietro Vertechi](https://github.com/piever)"
# ---

using AlgebraOfGraphics, CairoMakie
set_aog_theme!() #src

N = 40

x = [1:N; 1:N]
y = [cumsum(randn(N)); cumsum(randn(N))]
grp = [fill("a", N); fill("b", N)]

df = (; x, y, grp)

layers = visual(Lines) + visual(Scatter) * mapping(marker = :grp)
plt = data(df) * layers * mapping(:x, :y, color = :grp)

fg = draw(plt)

# save cover image #src
mkpath("assets") #src
save("assets/legend_merging.png", fg) #src
