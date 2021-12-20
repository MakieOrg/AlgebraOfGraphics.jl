using AlgebraOfGraphics, Makie, Test
using AlgebraOfGraphics: Sorted
using AlgebraOfGraphics: map_pairs, separate
using AlgebraOfGraphics: arguments, Arguments, namedarguments, NamedArguments

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
end

@testset "arguments" begin
    s = Arguments([10, 20, 30])
    @test s == arguments([10, 20, 30])
    t = map_pairs(s) do (k, v)
        return "key $k and value $v"
    end
    @test t == ["key 1 and value 10", "key 2 and value 20", "key 3 and value 30"]

    s = NamedArguments([:a, :b, :c], [10, 20, 30])
    @test s == namedarguments((a=10, b=20, c=30))
    t = map_pairs(s) do (k, v)
        return "key $k and value $v"
    end
    @test t == NamedArguments(
        [:a, :b, :c],    
        ["key a and value 10", "key b and value 20", "key c and value 30"]
    )

    s = NamedArguments([:a, :b, :c], [1, 2, 3])
    odd, even = separate(isodd, s)
    @test odd == namedarguments((a=1, c=3))
    @test even == namedarguments((b=2,))
end

@testset "layers" begin
    df = (x = rand(1000), y = rand(1000), c = rand(["a", "b", "c"], 1000))
    d = mapping(:x, :y, color=:c)
    s = visual(color=:red) + mapping(markersize=:c)
    layers = data(df) * d * s
    @test layers[1].transformation isa AlgebraOfGraphics.Visual
    @test layers[1].transformation.attributes[:color] == :red
    @test layers[1].positional == arguments((:x, :y))
    @test layers[1].named == namedarguments((color=:c,))
    @test layers[1].data == df
end

@testset "process_mappings" begin
    df = (x=rand(1000), y=rand(1000), z=rand(1000), c=rand(["a", "b", "c"], 1000))
    d = mapping(:x => exp, [:y, :z], color=:c, marker = dims(1) => renamer(["a", "b"]))
    layer = data(df) * d
    entry = AlgebraOfGraphics.process_mappings(layer)
    @test entry.positional[1] == fill(map(exp, df.x))
    @test entry.positional[2] == [df.y, df.z]
    @test entry.primary[:color] == fill(df.c)
    @test entry.primary[:marker] == [fill(Sorted(1, "a")), fill(Sorted(2, "b"))]
    @test entry.named == namedarguments((;))
    @test entry.labels[1] == fill("x")
    @test entry.labels[2] ==  ["y", "z"]
    @test entry.labels[:color] == fill("c")
    @test entry.labels[:marker] == ""
end

@testset "grouping" begin
    df = (x=rand(1000), y=rand(1000), z=rand(1000), w=rand(1000), c=rand(["a", "b", "c"], 1000))
    df.c[1:3] .= ["a", "b", "c"] # ensure all three values exist
    d = mapping(:x => exp, [:y, :z], color=:c, marker=dims(1) => t -> ["1", "2"][t], markersize=:w)
    layer = data(df) * d
    e = AlgebraOfGraphics.to_entry(layer)
    entries = map(CartesianIndices(AlgebraOfGraphics.shape(e))) do c
        primary, positional, named = map((e.primary, e.positional, e.named)) do tup
            return map(v -> v[c], tup)
        end
        labels = copy(e.labels)
        map!(l -> AlgebraOfGraphics.getnewindex(l, c), values(labels))
        return Entry(e; primary, positional, named, labels)
    end
    @test length(entries) == 6
    for i in 1: 6
        @test entries[i].plottype === Any
        @test isempty(entries[i].attributes)
        @test entries[i].labels[1] == "x"
        @test entries[i].labels[2] == (i ≤ 3 ? "y" : "z")
        @test entries[i].labels[:color] == "c"
        @test entries[i].labels[:marker] == ""
        @test entries[i].labels[:markersize] == "w"
    end

    @test entries[1].primary[:color] == "a"
    @test entries[1].primary[:marker] == "1"
    @test entries[1].positional[1] == exp.(df.x[df.c .== "a"])
    @test entries[1].positional[2] == df.y[df.c .== "a"]
    @test entries[1].named[:markersize] == df.w[df.c .== "a"]
    
    @test entries[2].primary[:color] == "b"
    @test entries[2].primary[:marker] == "1"
    @test entries[2].positional[1] == exp.(df.x[df.c .== "b"])
    @test entries[2].positional[2] == df.y[df.c .== "b"]
    @test entries[2].named[:markersize] == df.w[df.c .== "b"]
    
    @test entries[3].primary[:color] == "c"
    @test entries[3].primary[:marker] == "1"
    @test entries[3].positional[1] == exp.(df.x[df.c .== "c"])
    @test entries[3].positional[2] == df.y[df.c .== "c"]
    @test entries[3].named[:markersize] == df.w[df.c .== "c"]

    @test entries[4].primary[:color] == "a"
    @test entries[4].primary[:marker] == "2"
    @test entries[4].positional[1] == exp.(df.x[df.c .== "a"])
    @test entries[4].positional[2] == df.z[df.c .== "a"]
    @test entries[4].named[:markersize] == df.w[df.c .== "a"]

    @test entries[5].primary[:color] == "b"
    @test entries[5].primary[:marker] == "2"
    @test entries[5].positional[1] == exp.(df.x[df.c .== "b"])
    @test entries[5].positional[2] == df.z[df.c .== "b"]
    @test entries[5].named[:markersize] == df.w[df.c .== "b"]

    @test entries[6].primary[:color] == "c"
    @test entries[6].primary[:marker] == "2"
    @test entries[6].positional[1] == exp.(df.x[df.c .== "c"])
    @test entries[6].positional[2] == df.z[df.c .== "c"]
    @test entries[6].named[:markersize] == df.w[df.c .== "c"]
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