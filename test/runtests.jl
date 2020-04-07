using AlgebraOfGraphics, Test
using AlgebraOfGraphics: data,
                         style,
                         Spec,
                         spec,
                         layers,
                         positional,
                         keyword,
                         dims,
                         extract_names,
                         compute

using OrderedCollections: OrderedDict
using CategoricalArrays: categorical
using NamedDims
using RDatasets: dataset
using Observables: to_value
using AbstractPlotting: default_palettes

@testset "product" begin
    s = dims() * style(1:2, ["a", "b"], color = dims(1))
    v = values(s)
    @test length(v) == 1
    st = first(v)
    ps = pairs(st)
    @test ps[1] == Pair((color = [1],), (var"1" = 1, var"2" = "a"))
    @test ps[2] == Pair((color = [2],), (var"1" = 2, var"2" = "b"))
end

@testset "lazy spec" begin
    mpg = dataset("ggplot2", "mpg")
    d = style(:Cyl, :Hwy, color = :Year => categorical)
    s = spec(color = :red, font = 10) + style(markersize = :Year)
    res = data(mpg) * d * s
    st = res[spec(color = :red, font = 10)]
    @test first(keys(res)) == Spec{Any}((), (color = :red, font = 10))

    idx1 = mpg.Year .== 1999
    idx2 = mpg.Year .== 2008

    styles = map(pairs, values(res))
    @test Tuple(last(styles[1][1])) == tuple(mpg[idx1, :Cyl], mpg[idx1, :Hwy])
    @test Tuple(last(styles[1][2])) == tuple(mpg[idx2, :Cyl], mpg[idx2, :Hwy])
    @test Tuple(last(styles[2][1]))[1:2] == tuple(mpg[idx1, :Cyl], mpg[idx1, :Hwy])
    @test Tuple(last(styles[2][2]))[1:2] == tuple(mpg[idx2, :Cyl], mpg[idx2, :Hwy])

    @test keyword(last(styles[1][1])) == NamedTuple()
    @test keyword(last(styles[1][2])) == NamedTuple()
    @test keyword(last(styles[2][1])) == (; markersize = mpg[idx1, :Year])
    @test keyword(last(styles[2][2])) == (; markersize = mpg[idx2, :Year])

    @test extract_names(first(styles[1][1])) ==
        ((color = :Year,), (color = categorical([1999]),))
    @test extract_names(first(styles[1][2])) ==
        ((color = :Year,), (color = categorical([2008]),))
    @test extract_names(first(styles[2][1])) ==
        ((color = :Year,), (color = categorical([1999]),))
    @test extract_names(first(styles[2][2])) ==
        ((color = :Year,), (color = categorical([2008]),))

    x = rand(5, 3, 2)
    y = rand(5, 3)
    s = dims(1) * style(x, y, color = dims(2)) 

    res = pairs(s)
    for (i, r) in enumerate(pairs(s[spec()]))
        group, style = r
        @test group == (; color = [mod1(i, 3)])
        xsl = x[:, mod1(i, 3), (i > 3) + 1]
        ysl = y[:, mod1(i, 3)]
        @test style == (; Symbol(1) => xsl, Symbol(2) => ysl)
    end
end

@testset "specs" begin
    wong = default_palettes[:color][]
    t = (x = [1, 2], y = [10, 20], z = [3, 4], c = ["a", "b"])
    d = style(:x, :y, color = :c)
    s = spec(:log) * spec(font = 10) + style(size = :z)
    ds = data(t) * d
    sl = ds * s
    res = compute(sl)
    @test length(res) == 2

    r = res[Spec{:log}((), (font = 10,))]
    (k1, v1), (k2, v2) = r

    @test map(getindex, k1) == (color = NamedDimsArray{(:c,)}([wong[1]]),)
    @test map(getindex, k2) == (color = NamedDimsArray{(:c,)}([wong[2]]),)
    @test v1 == (var"1" = [1], var"2" = [10])
    @test v2 == (var"1" = [2], var"2" = [20])

    r = res[spec()]
    (k1, v1), (k2, v2) = r

    @test map(getindex, k1) == (color = NamedDimsArray{(:c,)}([wong[1]]),)
    @test map(getindex, k2) == (color = NamedDimsArray{(:c,)}([wong[2]]),)
    @test v1 == (var"1" = [1], var"2" = [10], size = [3])
    @test v2 == (var"1" = [2], var"2" = [20], size = [4])
end
