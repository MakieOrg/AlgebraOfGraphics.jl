using AlgebraOfGraphics, CairoMakie

N = 40

x = [1:N; 1:N]
y = [cumsum(randn(N)); cumsum(randn(N))]
grp = [fill("a", N); fill("b", N)]

df = (; x, y, grp)

layers = visual(Lines) + visual(Scatter) * mapping(marker = :grp)
plt = data(df) * layers * mapping(:x, :y, color = :grp)

fg = draw(plt)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

