using AlgebraOfGraphics, Test
using AlgebraOfGraphics: table, data, metadata, primary, mixedtuple, group, rankdicts
using AlgebraOfGraphics: aos

using RDatasets: dataset

@testset "lazy spec" begin
    mpg = dataset("ggplot2", "mpg")
    spec = data(:Cyl, :Hwy) |> primary(color = :Year)
    s = [metadata(color = :red, font = 10), data(markersize = :Year)]
    res = map(group, mpg |> table |> spec .|> s)
    @test res[1].metadata == mixedtuple(color = :red, font = 10)
    @test res[2].metadata == mixedtuple()
    idx1 = mpg.Year .== 1999
    idx2 = mpg.Year .== 2008

    dt = aos(res[1].data)
    @test dt[1].args == tuple(mpg[idx1, :Cyl], mpg[idx1, :Hwy])
    @test dt[2].args == tuple(mpg[idx2, :Cyl], mpg[idx2, :Hwy])
    @test dt[1].kwargs == NamedTuple()

    dt = aos(res[2].data)
    @test dt[1].args == tuple(mpg[idx1, :Cyl], mpg[idx1, :Hwy])
    @test dt[2].args == tuple(mpg[idx2, :Cyl], mpg[idx2, :Hwy])
    @test dt[1].kwargs == (; markersize = mpg[idx1, :Year])
    @test dt[2].kwargs == (; markersize = mpg[idx2, :Year])
    @test length(res) == 2
end

@testset "rankdicts" begin
    mpg = dataset("ggplot2", "mpg")
    spec = data(:Cyl, :Hwy) |> primary(color = :Year)
    s = [metadata(color = :red, font = 10), data(markersize = :Year)]
    res = map(group, mpg |> table |> spec .|> s)
    @test rankdicts(res)[:color][2008] == 2
    @test rankdicts(res)[:color][1999] == 1
end
