using AlgebraOfGraphics, Test
using AlgebraOfGraphics: Data,
                         Select,
                         Group,
                         Analysis,
                         Trace,
                         traces,
                         bycolumn,
                         AbstractElement

using RDatasets: dataset

struct Metadata{T} <: AbstractElement
    x::T
end

@testset "traces" begin
    mpg = dataset("ggplot2", "mpg")
    spec = Data(mpg) * Select(:Cyl, :Hwy) * Group(color = :Year)
    s = Metadata(log) + Metadata(exp)
    ts = traces(s, spec)
    @test ts[1][1] == (Metadata(log),)
    @test ts[2][1] == (Metadata(exp),)
    @test ts[1][2] isa Vector{<:Trace}
    @test length(ts) == 2

    m1, ts1 = traces(Data(mpg), Select(:Cyl, :Hwy), Group(color=:Year))
    m2, ts2 = traces(Data(mpg) * Select(:Cyl, :Hwy) * Group(color=:Year))
    @test ts1[1].attributes == ts2[1].attributes
    @test ts1[1].select.args == ts2[1].select.args
    @test ts1[1].select.kwargs == ts2[1].select.kwargs
    @test m1 == m2 == ()
    
    m1, ts1 = traces(Select((rand(10), rand(10))) * Group(color=bycolumn))
    @test m1 == ()
    @test size(ts1) == (1, 2)

end
