using AlgebraOfGraphics, Test
using AlgebraOfGraphics: Data, Select, Group, Analysis, Trace, traces, ⊗, ⊕
using RDatasets: dataset

@testset "traces" begin
    mpg = dataset("ggplot2", "mpg")
    spec = Data(mpg) ⊗ Select(:Cyl, :Hwy) ⊗ Group(color = :Year)
    s = log ⊕ exp
    ts = traces(s, spec)
    @test ts[1][1] == (log,)
    @test ts[2][1] == (exp,)
    @test ts[1][2] isa Vector{<:Trace}
    @test length(ts) == 2

    m1, ts1 = traces(Data(mpg), Select(:Cyl, :Hwy), Group(color=:Year))
    m2, ts2 = traces(Data(mpg) ⊗ Select(:Cyl, :Hwy) ⊗ Group(color=:Year))
    @test ts1[1].attributes == ts2[1].attributes
    @test ts1[1].select.args == ts2[1].select.args
    @test ts1[1].select.kwargs == ts2[1].select.kwargs
    @test m1 == m2 == ()
end
