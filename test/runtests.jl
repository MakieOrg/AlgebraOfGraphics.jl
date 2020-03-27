using AlgebraOfGraphics, Test
using AlgebraOfGraphics: table,
                         data,
                         spec,
                         specs,
                         primary,
                         Series,
                         rankdicts,
                         positional,
                         keyword,
                         DataContext,
                         DefaultContext,
                         dims,
                         outputs

using DataStructures: OrderedDict
using RDatasets: dataset

@testset "calling" begin
    s = data(1:2, ["a", "b"]) |> primary(color = dims(1))
    exp = DefaultContext((; color = dims(1)), (; Symbol(1) => 1:2, Symbol(2) => ["a", "b"]))
    @test s == exp
end

@testset "lazy spec" begin
    mpg = dataset("ggplot2", "mpg")
    d = data(:Cyl, :Hwy) * primary(color = :Year)
    s = spec(color = :red, font = 10) + data(markersize = :Year)
    tree = table(mpg) * d * s
    res = outputs(tree)
    @test res[1].spec == spec(color = :red, font = 10)
    @test res[2] isa DataContext

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
    @test primaries[1][1] == (; color = 1999)
    @test primaries[1][2] == (; color = 2008)
    @test primaries[2][1] == (; color = 1999)
    @test primaries[2][2] == (; color = 2008)

    @test length(pairs(res[1])) == 2
    @test length(pairs(res[2])) == 2
end

@testset "rankdicts" begin
    mpg = dataset("ggplot2", "mpg")
    d = data(:Cyl, :Hwy) * primary(color = :Year)
    s = spec(color = :red, font = 10) + data(markersize = :Year)
    tree = table(mpg) * d * s
    res = outputs(tree)
    @test rankdicts(res)[:color][2008] == 2
    @test rankdicts(res)[:color][1999] == 1
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
    dict1 = OrderedDict(
                        (color = "a",) => spec(log, [1], [10], font = 10, color = "red"),
                        (color = "b",) => spec(log, [2], [20], font = 10, color = "blue"),
                       )
    dict2 = OrderedDict(
                        (color = "a",) => spec([1], [10], size = [3], color = "red"),
                        (color = "b",) => spec([2], [20], size = [4], color = "blue"),
                       )
    @test res[1][(color = "a",)] == dict1[(color = "a",)]
    @test res[1][(color = "b",)] == dict1[(color = "b",)]
    @test res[2][(color = "a",)] == dict2[(color = "a",)]
    @test res[2][(color = "b",)] == dict2[(color = "b",)]
    @test map(first, tree())[1] == Series(spec(log, font = 10), first(first(ds())))
end
