using AlgebraOfGraphics, Test
using AlgebraOfGraphics: table, data, metadata, primary, mixedtuple, group, rankdicts
using AlgebraOfGraphics: aos

using RDatasets: dataset

@testset "lazy spec" begin
    mpg = dataset("ggplot2", "mpg")
    spec = data(:Cyl, :Hwy) |> primary(color = :Year)
    s = [metadata(color = :red, font = 10), data(markersize = :Year)]
    res = mpg |> table |> spec .|> s
    @test res[1][1].metadata == mixedtuple(color = :red, font = 10)
    @test res[2][1].metadata == mixedtuple()
    idx1 = mpg.Year .== 1999
    idx2 = mpg.Year .== 2008

    @test res[1][1].data.args == tuple(mpg[idx1, :Cyl], mpg[idx1, :Hwy])
    @test res[1][2].data.args == tuple(mpg[idx2, :Cyl], mpg[idx2, :Hwy])
    @test res[2][1].data.args == tuple(mpg[idx1, :Cyl], mpg[idx1, :Hwy])
    @test res[2][2].data.args == tuple(mpg[idx2, :Cyl], mpg[idx2, :Hwy])

    @test res[1][1].data.kwargs == NamedTuple()
    @test res[1][2].data.kwargs == NamedTuple()
    @test res[2][1].data.kwargs == (; markersize = mpg[idx1, :Year])
    @test res[2][2].data.kwargs == (; markersize = mpg[idx2, :Year])

    @test length(res) == 2
end

@testset "rankdicts" begin
    mpg = dataset("ggplot2", "mpg")
    spec = data(:Cyl, :Hwy) |> primary(color = :Year)
    s = [metadata(color = :red, font = 10), data(markersize = :Year)]
    res = mpg |> table |> spec .|> s
    @test rankdicts(res)[:color][2008] == 2
    @test rankdicts(res)[:color][1999] == 1
end
