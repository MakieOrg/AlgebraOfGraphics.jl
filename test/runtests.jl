using AlgebraOfGraphics, Test
using AlgebraOfGraphics: data,
                         bind,
                         Spec,
                         spec,
                         layers,
                         positional,
                         keyword,
                         dims,
                         run_pipeline

using CategoricalArrays: categorical
using NamedDims
using RDatasets: dataset
using Observables: to_value
using AbstractPlotting: default_palettes

@testset "product" begin
    s = dims() * bind(1:2, ["a", "b"], color = dims(1))
    ps = pairs(s)
    @test ps[1] == Pair((color = 1,), bind(1, "a"))
    @test ps[2] == Pair((color = 2,), bind(2, "b"))
end

@testset "contexts" begin
    mpg = dataset("ggplot2", "mpg")
    d = bind(:Cyl, :Hwy, color = :Year => categorical)
    s = visual(color = :red, font = 10) + bind(markersize = :Year)
    res = data(mpg) * d * s
    @test res[1].options == (color = :red, font = 10)

    idx1 = mpg.Year .== 1999
    idx2 = mpg.Year .== 2008

    binds = pairs.(getproperty.(res, :bind))
    @test last(binds[1][1]).value == bind(mpg[idx1, :Cyl], mpg[idx1, :Hwy]).value
    @test last(binds[1][2]).value == bind(mpg[idx2, :Cyl], mpg[idx2, :Hwy]).value
    @test last(binds[2][1]).value == bind(mpg[idx1, :Cyl], mpg[idx1, :Hwy], markersize = mpg[idx1, :Year]).value
    @test last(binds[2][2]).value == bind(mpg[idx2, :Cyl], mpg[idx2, :Hwy], markersize = mpg[idx2, :Year]).value

    @test first(binds[1][1]).color isa NamedDimsArray
    @test only(first(binds[1][1]).color) == 1999
    @test dimnames(first(binds[1][1]).color) == (:Year,)

    @test first(binds[1][2]).color isa NamedDimsArray
    @test only(first(binds[1][2]).color) == 2008
    @test dimnames(first(binds[1][2]).color) == (:Year,)

    @test first(binds[2][1]).color isa NamedDimsArray
    @test only(first(binds[2][1]).color) == 1999
    @test dimnames(first(binds[2][1]).color) == (:Year,)

    @test first(binds[2][2]).color isa NamedDimsArray
    @test only(first(binds[2][2]).color) == 2008
    @test dimnames(first(binds[2][2]).color) == (:Year,)

    x = rand(5, 3, 2)
    y = rand(5, 3)
    s = dims(1) * bind(x, y, color = dims(2)) 

    res = pairs(s)
    for (i, r) in enumerate(res)
        group, st = r
        @test group == (; color = mod1(i, 3))
        xsl = x[:, mod1(i, 3), (i > 3) + 1]
        ysl = y[:, mod1(i, 3)]
        @test st.value == bind(xsl, ysl).value
    end
end

@testset "compute specs" begin
    wong = default_palettes[:color][]
    t = (x = [1, 2], y = [10, 20], z = [3, 4], c = ["a", "b"])
    d = bind(:x, :y, color = :c)
    s = visual(:log) * visual(font = 10) + bind(size = :z)
    ds = data(t) * d
    sl = ds * s
    @test length(sl) == 2

    res = run_pipeline(sl)

    @test res[1].options.color == wong[1]
    @test res[2].options.color == wong[2]
    @test dimnames(res[1].pkeys.color) == (:c,)
    @test dimnames(res[2].pkeys.color) == (:c,)
    @test res[1].bind.value == bind([1], [10]).value
    @test res[2].bind.value == bind([2], [20]).value

    @test res[3].options.color == wong[1]
    @test res[4].options.color == wong[2]
    @test dimnames(res[3].pkeys.color) == (:c,)
    @test dimnames(res[4].pkeys.color) == (:c,)
    @test res[3].bind.value == bind([1], [10], size = [3]).value
    @test res[4].bind.value == bind([2], [20], size = [4]).value
end
