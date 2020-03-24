using AlgebraOfGraphics, Test
using AlgebraOfGraphics: table, data, metadata, primary, mixedtuple, group, rankdicts

using RDatasets: dataset

@testset "lazy spec" begin
    mpg = dataset("ggplot2", "mpg")
    spec = data(:Cyl, :Hwy) |> primary(color = :Year)
    s = [metadata(color = :red, font = 10), data(markersize = :Year)]
    res = mpg |> table |> spec .|> s
    @test metadata(res[1]) == mixedtuple(color = :red, font = 10)
    @test metadata(res[2]) == mixedtuple()

    idx1 = mpg.Year .== 1999
    idx2 = mpg.Year .== 2008

    datas = [map(last, pairs(res[i])) for i in 1:2]
    @test datas[1][1].args == tuple(mpg[idx1, :Cyl], mpg[idx1, :Hwy])
    @test datas[1][2].args == tuple(mpg[idx2, :Cyl], mpg[idx2, :Hwy])
    @test datas[2][1].args == tuple(mpg[idx1, :Cyl], mpg[idx1, :Hwy])
    @test datas[2][2].args == tuple(mpg[idx2, :Cyl], mpg[idx2, :Hwy])

    @test datas[1][1].kwargs == NamedTuple()
    @test datas[1][2].kwargs == NamedTuple()
    @test datas[2][1].kwargs == (; markersize = mpg[idx1, :Year])
    @test datas[2][2].kwargs == (; markersize = mpg[idx2, :Year])

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
    spec = data(:Cyl, :Hwy) |> primary(color = :Year)
    s = [metadata(color = :red, font = 10), data(markersize = :Year)]
    res = mpg |> table |> spec .|> s
    @test rankdicts(res)[:color][2008] == 2
    @test rankdicts(res)[:color][1999] == 1
end
