using AlgebraOfGraphics, Test
using AlgebraOfGraphics: table,
                         data,
                         spec,
                         specs,
                         slice,
                         primary,
                         Series,
                         rankdicts,
                         positional,
                         keyword,
                         dims,
                         outputs,
                         NamedEntry,
                         ContextualPair,
                         ContextualMap

using DataStructures: OrderedDict
using NamedDims
using RDatasets: dataset

@testset "calling" begin
    s = data(1:2, ["a", "b"]) |> primary(color = dims(1))
    exp = ContextualMap(ContextualPair(
                                       nothing,
                                       (; color = dims(1)),
                                       (; Symbol(1) => 1:2, Symbol(2) => ["a", "b"])
                                      )
                       )
    @test s == exp
end

@testset "lazy spec" begin
    mpg = dataset("ggplot2", "mpg")
    d = data(:Cyl, :Hwy) * primary(color = :Year)
    s = spec(color = :red, font = 10) + data(markersize = :Year)
    tree = table(mpg) * d * s
    res = outputs(tree)
    @test res[1].spec == spec(color = :red, font = 10)

    idx1 = mpg.Year .== 1999
    idx2 = mpg.Year .== 2008

    datas = [map(last, pairs(res[i])) for i in 1:2]
    @test Tuple(positional(datas[1][1])) == tuple(mpg[idx1, :Cyl], mpg[idx1, :Hwy])
    @test Tuple(positional(datas[1][2])) == tuple(mpg[idx2, :Cyl], mpg[idx2, :Hwy])
    @test Tuple(positional(datas[2][1])) == tuple(mpg[idx1, :Cyl], mpg[idx1, :Hwy])
    @test Tuple(positional(datas[2][2])) == tuple(mpg[idx2, :Cyl], mpg[idx2, :Hwy])

    @test (; keyword(datas[1][1])...) == NamedTuple()
    @test (; keyword(datas[1][2])...) == NamedTuple()
    @test (; keyword(datas[2][1])...) == (; markersize = mpg[idx1, :Year])
    @test (; keyword(datas[2][2])...) == (; markersize = mpg[idx2, :Year])

    primaries = [map(first, pairs(res[i])) for i in 1:2]
    @test primaries[1][1] == (; color = NamedEntry(:Year, 1999))
    @test primaries[1][2] == (; color = NamedEntry(:Year, 2008))
    @test primaries[2][1] == (; color = NamedEntry(:Year, 1999))
    @test primaries[2][2] == (; color = NamedEntry(:Year, 2008))

    @test length(pairs(res[1])) == 2
    @test length(pairs(res[2])) == 2

    x = rand(5, 3, 2)
    y = rand(5, 3)
    s = slice(1) * data(x, y) * primary(color = dims(2)) 

    @test length(outputs(s)) == 1
    res = pairs(outputs(s)[1])
    for i = 1:6
        @test first(res[i]) == (; color = mod1(i, 3))
        xsl = x[:, mod1(i, 3), (i > 3) + 1]
        ysl = y[:, mod1(i, 3)]
        @test last(res[i]) == (; Symbol(1) => xsl, Symbol(2) => ysl)
    end
end

@testset "rankdicts" begin
    mpg = dataset("ggplot2", "mpg")
    d = data(:Cyl, :Hwy) * primary(color = :Year)
    s = spec(color = :red, font = 10) + data(markersize = :Year)
    tree = table(mpg) * d * s
    res = outputs(tree)
    @test rankdicts(res)[:color][NamedEntry(:Year, 2008)] == 2
    @test rankdicts(res)[:color][NamedEntry(:Year, 1999)] == 1
end

@testset "specs" begin
    palette = Dict(:color => ["red", "blue"])
    t = (x = [1, 2], y = [10, 20], z = [3, 4], c = ["a", "b"])
    d = data(:x, :y) * primary(color = :c)
    s = spec(log) * spec(font = 10) + data(size = :z)
    ds = table(t) * d
    tree = ds * s
    res = specs(tree, palette)
    @test length(res) == 2

    ns = (; Symbol(1) => :x, Symbol(2) => :y)
    ns_attr = (; Symbol(1) => :x, Symbol(2) => :y, :size => :z)
    @test res[1][(color = NamedEntry(:c, "a"),)] ==
        spec(log, [1], [10], font = 10, color = "red", names = ns)
    @test res[1][(color = NamedEntry(:c, "b"),)] ==
        spec(log, [2], [20], font = 10, color = "blue", names = ns)
    @test res[2][(color = NamedEntry(:c, "a"),)] ==
        spec([1], [10], size = [3], color = "red", names = ns_attr)
    @test res[2][(color = NamedEntry(:c, "b"),)] ==
        spec([2], [20], size = [4], color = "blue", names = ns_attr)

    @test map(first, tree())[1] == Series(spec(log, font = 10), first(first(ds())))
end
