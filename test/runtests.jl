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
    st = first(v)[NamedTuple()]
    ps = pairs(st)
    @test ps[1] == Pair((color = [1],), style(1, "a"))
    @test ps[2] == Pair((color = [2],), style(2, "b"))
end

@testset "lazy spec" begin
    mpg = dataset("ggplot2", "mpg")
    d = style(:Cyl, :Hwy, color = :Year => categorical)
    s = spec(color = :red, font = 10) + style(markersize = :Year)
    res = data(mpg) * d * s
    st = res[spec(color = :red, font = 10)][NamedTuple()]
    @test first(keys(res)) == Spec{Any}((), (color = :red, font = 10))

    idx1 = mpg.Year .== 1999
    idx2 = mpg.Year .== 2008

    styles = map(t -> pairs(t[NamedTuple()]), values(res))
    @test last(styles[1][1]).value == style(mpg[idx1, :Cyl], mpg[idx1, :Hwy]).value
    @test last(styles[1][2]).value == style(mpg[idx2, :Cyl], mpg[idx2, :Hwy]).value
    @test last(styles[2][1]).value == style(mpg[idx1, :Cyl], mpg[idx1, :Hwy], markersize = mpg[idx1, :Year]).value
    @test last(styles[2][2]).value == style(mpg[idx2, :Cyl], mpg[idx2, :Hwy], markersize = mpg[idx2, :Year]).value

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
    for (i, r) in enumerate(pairs(s[spec()][NamedTuple()]))
        group, st = r
        @test group == (; color = [mod1(i, 3)])
        xsl = x[:, mod1(i, 3), (i > 3) + 1]
        ysl = y[:, mod1(i, 3)]
        @test st.value == style(xsl, ysl).value
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

    # TODO: fix when reworking legend entry structure and scales
    @test map(getindex∘last, k1) == (color = NamedDimsArray{(:c,)}([wong[1]]),)
    @test map(getindex∘last, k2) == (color = NamedDimsArray{(:c,)}([wong[2]]),)
    @test v1.value == style([1], [10]).value
    @test v2.value == style([2], [20]).value

    r = res[spec()]
    (k1, v1), (k2, v2) = r

    @test map(getindex∘last, k1) == (color = NamedDimsArray{(:c,)}([wong[1]]),)
    @test map(getindex∘last, k2) == (color = NamedDimsArray{(:c,)}([wong[2]]),)
    @test v1.value == style([1], [10], size = [3]).value
    @test v2.value == style([2], [20], size = [4]).value
end
