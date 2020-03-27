using AlgebraOfGraphics, Test
using AlgebraOfGraphics: table, data, spec, primary, rankdicts, positional, keyword, DataContext

using RDatasets: dataset

@testset "lazy spec" begin
    mpg = dataset("ggplot2", "mpg")
    d = data(:Cyl, :Hwy) * primary(color = :Year)
    s = spec(color = :red, font = 10) + data(markersize = :Year)
    tree = table(mpg) * d * s
    res = map(first, tree())
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
    res = map(first, tree())
    @test rankdicts(res)[:color][2008] == 2
    @test rankdicts(res)[:color][1999] == 1
end
