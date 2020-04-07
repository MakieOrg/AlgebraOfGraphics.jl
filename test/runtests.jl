using AlgebraOfGraphics, Test
using AlgebraOfGraphics: data,
                         style,
                         Spec,
                         spec,
                         layers,
                         positional,
                         keyword,
                         dims

using OrderedCollections: OrderedDict
using CategoricalArrays: categorical
using NamedDims
using RDatasets: dataset
using Observables: to_value

@testset "product" begin
    s = dims() * style(1:2, ["a", "b"], color = dims(1))
    v = values(s.layers)
    @test length(v) == 1
    st = first(v)
    @test length(st) == 1
    ps = pairs(only(st))
    @test ps[1] == Pair((color = 1,), (var"1" = 1, var"2" = "a"))
    @test ps[2] == Pair((color = 2,), (var"1" = 2, var"2" = "b"))
end

@testset "lazy spec" begin
    mpg = dataset("ggplot2", "mpg")
    d = style(:Cyl, :Hwy, color = :Year => categorical)
    s = spec(color = :red, font = 10) + style(markersize = :Year)
    sl = data(mpg) * d * s
    res = layers(sl)
    st = res[spec(color = :red, font = 10)]
    @test first(res[1]) == Spec{Any}((), (color = :red, font = 10))

    idx1 = mpg.Year .== 1999
    idx2 = mpg.Year .== 2008

    styles = [map(last, pairs(last(res[i]))) for i in 1:2]
    @test Tuple(positional(styles[1][1])) == tuple(mpg[idx1, :Cyl], mpg[idx1, :Hwy])
    @test Tuple(positional(styles[1][2])) == tuple(mpg[idx2, :Cyl], mpg[idx2, :Hwy])
    @test Tuple(positional(styles[2][1])) == tuple(mpg[idx1, :Cyl], mpg[idx1, :Hwy])
    @test Tuple(positional(styles[2][2])) == tuple(mpg[idx2, :Cyl], mpg[idx2, :Hwy])

    @test (; keyword(styles[1][1])...) == NamedTuple()
    @test (; keyword(styles[1][2])...) == NamedTuple()
    @test (; keyword(styles[2][1])...) == (; markersize = mpg[idx1, :Year])
    @test (; keyword(styles[2][2])...) == (; markersize = mpg[idx2, :Year])

    primaries = [map(first, pairs(last(res[i]))) for i in 1:2]
    @test primaries[1][1] == (; color = NamedEntry(:Year, 1999))
    @test primaries[1][2] == (; color = NamedEntry(:Year, 2008))
    @test primaries[2][1] == (; color = NamedEntry(:Year, 1999))
    @test primaries[2][2] == (; color = NamedEntry(:Year, 2008))

    @test length(collect(pairs(last(res[1])))) == 2
    @test length(collect(pairs(last(res[2])))) == 2

    x = rand(5, 3, 2)
    y = rand(5, 3)
    s = dims(1) * style(x, y) * group(color = dims(2)) 

    res = pairs(s)
    for (i, r) in enumerate(res)
        group, style = r
        @test group == (; color = mod1(i, 3))
        xsl = x[:, mod1(i, 3), (i > 3) + 1]
        ysl = y[:, mod1(i, 3)]
        @test style == (; Symbol(1) => xsl, Symbol(2) => ysl)
    end
end

_to_value(s::Spec{T}) where {T} = Spec{T}(_to_value(s.args), _to_value(s.kwargs))
_to_value(s::Union{Tuple, NamedTuple}) = map(_to_value, s)
_to_value(s) = to_value(s)

@testset "specs" begin
    palette = (color = ["red", "blue"],)
    t = (x = [1, 2], y = [10, 20], z = [3, 4], c = ["a", "b"])
    d = style(:x, :y) * group(color = :c)
    s = spec(:log) * spec(font = 10) + style(size = :z)
    ds = data(t) * d
    sl = ds * s
    res = specs(sl, palette)
    @test length(res) == 2

    ns = (; Symbol(1) => :x, Symbol(2) => :y)
    ns_attr = (; Symbol(1) => :x, Symbol(2) => :y, :size => :z)
    @test _to_value(res[1][(color = NamedEntry(:c, "a"),)]) ==
        Spec{:log}(([1], [10]), (font = 10, color = "red", names = ns))
    @test _to_value(res[1][(color = NamedEntry(:c, "b"),)]) ==
        Spec{:log}(([2], [20]), (font = 10, color = "blue", names = ns))
    @test _to_value(res[2][(color = NamedEntry(:c, "a"),)]) ==
        Spec{Any}(([1], [10]), (size = [3], color = "red", names = ns_attr))
    @test _to_value(res[2][(color = NamedEntry(:c, "b"),)]) ==
        Spec{Any}(([2], [20]), (size = [4], color = "blue", names = ns_attr))

    @test layers(sl)[1] == (Spec{:log}((), (; font = 10)) => ds)
end
