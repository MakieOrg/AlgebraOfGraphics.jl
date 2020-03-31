using AlgebraOfGraphics, Test
using AlgebraOfGraphics: table,
                         data,
                         Spec,
                         spec,
                         specs,
                         layers,
                         primary,
                         rankdicts,
                         positional,
                         keyword,
                         dims,
                         NamedEntry,
                         ContextualPair,
                         ContextualMap

using OrderedCollections: OrderedDict
using NamedDims
using RDatasets: dataset

@testset "product" begin
    s = data(1:2, ["a", "b"]) * primary(color = dims(1))
    exp = ContextualPair(
                         nothing,
                         (; color = dims(1)),
                         (; Symbol(1) => 1:2, Symbol(2) => ["a", "b"])
                        )
    @test s == exp
end

@testset "lazy spec" begin
    mpg = dataset("ggplot2", "mpg")
    d = data(:Cyl, :Hwy) * primary(color = :Year)
    s = spec(color = :red, font = 10) + data(markersize = :Year)
    sl = table(mpg) * d * s
    res = layers(sl)
    @test first(res[1]) == Spec{Any}((), (color = :red, font = 10))

    idx1 = mpg.Year .== 1999
    idx2 = mpg.Year .== 2008

    datas = [map(last, pairs(last(res[i]))) for i in 1:2]
    @test Tuple(positional(datas[1][1])) == tuple(mpg[idx1, :Cyl], mpg[idx1, :Hwy])
    @test Tuple(positional(datas[1][2])) == tuple(mpg[idx2, :Cyl], mpg[idx2, :Hwy])
    @test Tuple(positional(datas[2][1])) == tuple(mpg[idx1, :Cyl], mpg[idx1, :Hwy])
    @test Tuple(positional(datas[2][2])) == tuple(mpg[idx2, :Cyl], mpg[idx2, :Hwy])

    @test (; keyword(datas[1][1])...) == NamedTuple()
    @test (; keyword(datas[1][2])...) == NamedTuple()
    @test (; keyword(datas[2][1])...) == (; markersize = mpg[idx1, :Year])
    @test (; keyword(datas[2][2])...) == (; markersize = mpg[idx2, :Year])

    primaries = [map(first, pairs(last(res[i]))) for i in 1:2]
    @test primaries[1][1] == (; color = NamedEntry(:Year, 1999))
    @test primaries[1][2] == (; color = NamedEntry(:Year, 2008))
    @test primaries[2][1] == (; color = NamedEntry(:Year, 1999))
    @test primaries[2][2] == (; color = NamedEntry(:Year, 2008))

    @test length(collect(pairs(last(res[1])))) == 2
    @test length(collect(pairs(last(res[2])))) == 2

    x = rand(5, 3, 2)
    y = rand(5, 3)
    s = dims(1) * data(x, y) * primary(color = dims(2)) 

    res = pairs(s)
    for (i, r) in enumerate(res)
        primary, data = r
        @test primary == (; color = mod1(i, 3))
        xsl = x[:, mod1(i, 3), (i > 3) + 1]
        ysl = y[:, mod1(i, 3)]
        @test data == (; Symbol(1) => xsl, Symbol(2) => ysl)
    end
end

@testset "rankdicts" begin
    mpg = dataset("ggplot2", "mpg")
    d = data(:Cyl, :Hwy) * primary(color = :Year)
    s = spec(color = :red, font = 10) + data(markersize = :Year)
    sl = table(mpg) * d * s
    @test rankdicts(sl)[:color][NamedEntry(:Year, 2008)] == 2
    @test rankdicts(sl)[:color][NamedEntry(:Year, 1999)] == 1
end

@testset "specs" begin
    palette = Dict(:color => ["red", "blue"])
    t = (x = [1, 2], y = [10, 20], z = [3, 4], c = ["a", "b"])
    d = data(:x, :y) * primary(color = :c)
    s = spec(log) * spec(font = 10) + data(size = :z)
    ds = table(t) * d
    sl = ds * s
    res = specs(sl, palette)
    @test length(res) == 2

    ns = (; Symbol(1) => :x, Symbol(2) => :y)
    ns_attr = (; Symbol(1) => :x, Symbol(2) => :y, :size => :z)
    @test res[1][(color = NamedEntry(:c, "a"),)] ==
        Spec{Any}((log, [1], [10]), (font = 10, color = "red", names = ns))
    @test res[1][(color = NamedEntry(:c, "b"),)] ==
        Spec{Any}((log, [2], [20]), (font = 10, color = "blue", names = ns))
    @test res[2][(color = NamedEntry(:c, "a"),)] ==
        Spec{Any}(([1], [10]), (size = [3], color = "red", names = ns_attr))
    @test res[2][(color = NamedEntry(:c, "b"),)] ==
        Spec{Any}(([2], [20]), (size = [4], color = "blue", names = ns_attr))

    @test layers(sl)[1] == (Spec{Any}((log,), (; font = 10)) => ds)
end
