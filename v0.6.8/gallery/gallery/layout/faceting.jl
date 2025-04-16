using AlgebraOfGraphics, CairoMakie

df = let
    N = 100
    x0 = rand(1:10, N)
    i = rand(["α", "β"], N)
    j = rand(["a", "b", "c"], N)

    x = map(zip(x0, j)) do (xx, jj)
        shift = jj == "a" ? -2.9 : jj == "c" ? 2.9 : 0.0
        xx + shift
    end

    y = map(zip(x0, i)) do (xx, ii)
        shift = ii == "α" ? -3.9 : 3.9
        xx + 2 + shift + rand()
    end

    (; x, y, i, j)
end

plt = data(df) * mapping(:x, :y, row=:i, col=:j)

draw(plt)

draw(plt, facet=(; linkxaxes=:minimal, linkyaxes=:minimal))

draw(plt, facet=(; linkxaxes=:none))

df = (x=rand(100), y=rand(100), l=rand(["a", "b", "c", "d", "e"], 100))
plt = data(df) * mapping(:x, :y, layout=:l)
draw(plt)

draw(plt, facet=(; linkxaxes=:none, linkyaxes=:none))

draw(plt, palettes=(layout=[(1, 1), (1, 2), (2, 1), (2, 2), (3, 1)],))

df1 = (x=rand(100), y=rand(100), i=rand(["a", "b", "c"], 100), j=rand(["d", "e", "f"], 100))
df2 = (x=[0, 1], y=[0.5, 0.5], i=fill("a", 2), j=fill("e", 2))
layers = data(df1) * visual(Scatter) + data(df2) * visual(Lines)
fg = draw(layers * mapping(:x, :y, col=:i, row=:j))

df = (x=rand(100), y=rand(100), l=rand([1, 2, 3, 4, 5], 100))
plt = data(df) * mapping(:x, :y, layout=:l => nonnumeric)
draw(plt)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

