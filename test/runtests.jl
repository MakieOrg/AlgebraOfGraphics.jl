using AlgebraOfGraphics, Makie, Test
using AlgebraOfGraphics: Sorted
using AlgebraOfGraphics: map_pairs, separate
using AlgebraOfGraphics: Arguments, NamedArguments

@testset "utils" begin
    v1 = [1, 2, 7, 11]
    v2 = [1, 3, 4, 5.1]
    @test AlgebraOfGraphics.mergesorted(v1, v2) == [1, 2, 3, 4, 5.1, 7, 11]
    @test AlgebraOfGraphics.mergesorted(v2, v1) == [1, 2, 3, 4, 5.1, 7, 11]
    @test_throws ArgumentError AlgebraOfGraphics.mergesorted([2, 1], [1, 3])
    @test_throws ArgumentError AlgebraOfGraphics.mergesorted([1, 2], [10, 3])

    e1 = (-3, 11)
    e2 = (-5, 10)
    @test AlgebraOfGraphics.extend_extrema(e1, e2) == (-5, 11)

    @test AlgebraOfGraphics.midpoints(1:10) == 1.5:9.5

    s = Any[1, 2]
    t = NamedArguments((a=3, b=4))
    u = NamedArguments((b=5, c=6))
    v = Any[]
    w = AlgebraOfGraphics.concatenate_values(s, t, u)
    @test w == Any[1, 2, 3, 4, 5, 6]
end

@testset "arguments" begin
    s = Arguments([10, 20, 30])
    @test s == Any[10, 20, 30]
    t = map_pairs(s) do (k, v)
        return "key $k and value $v"
    end
    @test t == ["key 1 and value 10", "key 2 and value 20", "key 3 and value 30"]

    s = NamedArguments([:a, :b, :c], [10, 20, 30])
    @test s == NamedArguments((a=10, b=20, c=30))
    t = map_pairs(s) do (k, v)
        return "key $k and value $v"
    end
    @test t == NamedArguments(
        [:a, :b, :c],    
        ["key a and value 10", "key b and value 20", "key c and value 30"]
    )

    s = NamedArguments([:a, :b, :c], [1, 2, 3])
    odd, even = separate(isodd, s)
    @test odd == NamedArguments((a=1, c=3))
    @test even == NamedArguments((b=2,))

    t = AlgebraOfGraphics.set(s, :d => 5, :a => 3)
    @test t == NamedArguments([:a, :b, :c, :d], [3, 2, 3, 5])

    s = NamedArguments([:a, :b, :c], [1, 2, 3])
    t = AlgebraOfGraphics.set(s)
    @test s == t
    @test keys(s) !== keys(t)

    s = NamedArguments([:a, :b, :c], [1, 2, 3])
    t = AlgebraOfGraphics.unset(s, :a, :b)
    @test t == NamedArguments([:c], [3])
end

@testset "layers" begin
    df = (x = rand(1000), y = rand(1000), c = rand(["a", "b", "c"], 1000))
    d = mapping(:x, :y, color=:c)
    s = visual(color=:red) + mapping(markersize=:c)
    layers = data(df) * d * s
    @test layers[1].transformation isa AlgebraOfGraphics.Visual
    @test layers[1].transformation.attributes[:color] == :red
    @test layers[1].positional == Any[:x, :y]
    @test layers[1].named == NamedArguments((color=:c,))
    @test layers[1].data == df
end

@testset "process_mappings" begin
    df = (x=rand(1000), y=rand(1000), z=rand(1000), c=rand(["a", "b", "c"], 1000))
    d = mapping(:x => exp, [:y, :z], color=:c, marker = dims(1) => renamer(["a", "b"]))
    layer = data(df) * d
    pl = AlgebraOfGraphics.process_mappings(layer)
    @test pl.positional[1] == fill(map(exp, df.x))
    @test pl.positional[2] == [df.y, df.z]
    @test pl.primary[:color] == fill(df.c)
    @test pl.primary[:marker] == [fill(Sorted(1, "a")), fill(Sorted(2, "b"))]
    @test pl.named == NamedArguments((;))
    @test pl.labels[1] == fill("x")
    @test pl.labels[2] ==  ["y", "z"]
    @test pl.labels[:color] == fill("c")
    @test pl.labels[:marker] == ""
end

@testset "grouping" begin
    df = (x=rand(1000), y=rand(1000), z=rand(1000), w=rand(1000), c=rand(["a", "b", "c"], 1000))
    df.c[1:3] .= ["a", "b", "c"] # ensure all three values exist
    d = mapping(:x => exp, [:y, :z], color=:c, marker=dims(1) => t -> ["1", "2"][t], markersize=:w)
    layer = data(df) * d
    pl = AlgebraOfGraphics.to_processedlayer(layer)
    pls = map(CartesianIndices(AlgebraOfGraphics.shape(pl))) do c
        primary, positional, named = map((pl.primary, pl.positional, pl.named)) do tup
            return map(v -> v[c], tup)
        end
        labels = map(l -> AlgebraOfGraphics.getnewindex(l, c), pl.labels)
        return ProcessedLayer(pl; primary, positional, named, labels)
    end
    @test length(pls) == 6
    for i in 1: 6
        @test pls[i].plottype === Any
        @test isempty(pls[i].attributes)
        @test pls[i].labels[1] == "x"
        @test pls[i].labels[2] == (i ≤ 3 ? "y" : "z")
        @test pls[i].labels[:color] == "c"
        @test pls[i].labels[:marker] == ""
        @test pls[i].labels[:markersize] == "w"
    end

    @test pls[1].primary[:color] == "a"
    @test pls[1].primary[:marker] == "1"
    @test pls[1].positional[1] == exp.(df.x[df.c .== "a"])
    @test pls[1].positional[2] == df.y[df.c .== "a"]
    @test pls[1].named[:markersize] == df.w[df.c .== "a"]
    
    @test pls[2].primary[:color] == "b"
    @test pls[2].primary[:marker] == "1"
    @test pls[2].positional[1] == exp.(df.x[df.c .== "b"])
    @test pls[2].positional[2] == df.y[df.c .== "b"]
    @test pls[2].named[:markersize] == df.w[df.c .== "b"]
    
    @test pls[3].primary[:color] == "c"
    @test pls[3].primary[:marker] == "1"
    @test pls[3].positional[1] == exp.(df.x[df.c .== "c"])
    @test pls[3].positional[2] == df.y[df.c .== "c"]
    @test pls[3].named[:markersize] == df.w[df.c .== "c"]

    @test pls[4].primary[:color] == "a"
    @test pls[4].primary[:marker] == "2"
    @test pls[4].positional[1] == exp.(df.x[df.c .== "a"])
    @test pls[4].positional[2] == df.z[df.c .== "a"]
    @test pls[4].named[:markersize] == df.w[df.c .== "a"]

    @test pls[5].primary[:color] == "b"
    @test pls[5].primary[:marker] == "2"
    @test pls[5].positional[1] == exp.(df.x[df.c .== "b"])
    @test pls[5].positional[2] == df.z[df.c .== "b"]
    @test pls[5].named[:markersize] == df.w[df.c .== "b"]

    @test pls[6].primary[:color] == "c"
    @test pls[6].primary[:marker] == "2"
    @test pls[6].positional[1] == exp.(df.x[df.c .== "c"])
    @test pls[6].positional[2] == df.z[df.c .== "c"]
    @test pls[6].named[:markersize] == df.w[df.c .== "c"]
end

@testset "helpers" begin
    r = renamer("a" => "A", "b" => "B", "c" => "C")
    @test r("a") == Sorted(1, "A")
    @test r("b") == Sorted(2, "B")
    @test r("c") == Sorted(3, "C")
    @test_throws KeyError r("d")
    @test string(r("a")) == "A"
    @test string(r("b")) == "B"
    @test string(r("c")) == "C"
    @test r("a") < r("b") < r("c")
    @test r("a") == r("a")
    @test r("a") != r("b")
    r̂ = renamer(["a" => "A", "b" => "B", "c" => "C"])
    @test r̂("a") == Sorted(1, "A")
    @test r̂("b") == Sorted(2, "B")
    @test r̂("c") == Sorted(3, "C")
    @test_throws KeyError r̂("d")
    @test string(r̂("a")) == "A"
    @test string(r̂("b")) == "B"
    @test string(r̂("c")) == "C"
    @test r̂("a") < r̂("b") < r̂("c")
    @test r̂("a") == r̂("a")
    @test r̂("a") != r̂("b")

    s = sorter("b", "c", "a")
    @test s("a") == Sorted(3, "a")
    @test s("b") == Sorted(1, "b")
    @test s("c") == Sorted(2, "c")
    @test_throws KeyError s("d")
    @test string(s("a")) == "a"
    @test string(s("b")) == "b"
    @test string(s("c")) == "c"
    @test s("b") < s("c") < s("a")
    @test s("a") == s("a")
    @test s("a") != s("b")
    ŝ = sorter(["b", "c", "a"])
    @test ŝ("a") == Sorted(3, "a")
    @test ŝ("b") == Sorted(1, "b")
    @test ŝ("c") == Sorted(2, "c")
    @test_throws KeyError ŝ("d")
    @test string(ŝ("a")) == "a"
    @test string(ŝ("b")) == "b"
    @test string(ŝ("c")) == "c"
    @test ŝ("b") < ŝ("c") < ŝ("a")
    @test ŝ("a") == ŝ("a")
    @test ŝ("a") != ŝ("b")

    a = Sorted(1, [1, 2])
    b = Sorted(1, [1, 2])
    c = Sorted(1, [1, 3])
    @test a == b
    @test hash(a) == hash(b)
    @test a != c
    @test hash(a) != hash(c)

    @test string(nonnumeric(1)) == "1"
    @test isless(nonnumeric(1), nonnumeric(2))
end

@testset "legend_merging" begin
    mwe_data = (; t = 1:20, y1 = ones(20), y2 = rand(20))
    mwe_names = ["f_n", "f_d"]
    plt = data(mwe_data) *
        mapping("t", ["y1", "y2"] .=> "y"; color = dims(1) => (i -> mwe_names[i]), marker=dims(1)) *
        (visual(Lines) + visual(Scatter))
    @test_throws ArgumentError draw(plt)
end