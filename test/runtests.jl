using AlgebraOfGraphics, Test

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

@testset "layers" begin
    df = (x = rand(1000), y = rand(1000), c = rand(["a", "b", "c"], 1000))
    d = mapping(:x, :y, color = :c)
    s = visual(color = :red) + mapping(markersize = :c)
    layers = data(df) * d * s
    @test layers[1].transformations[1] isa AlgebraOfGraphics.Visual
    @test layers[1].transformations[1].attributes[:color] == :red
    @test layers[1].positional == (:x, :y)
    @test layers[1].named == (color=:c,)
    @test layers[1].data == df
end

@testset "process_data" begin
    df = (x = rand(1000), y = rand(1000), z = rand(1000), c = rand(["a", "b", "c"], 1000))
    d = mapping(:x => exp, [:y, :z], color = :c, marker = dims(1) => t -> ["a", "b"][t])
    layer = data(df) * d
    entry = AlgebraOfGraphics.process_data(layer)
    @test entry.positional[1].label == fill("x")
    @test entry.positional[1].value == map(exp, df.x)
    @test entry.positional[2].label == ["y", "z"]
    @test entry.positional[2].value == [df.y df.z]
    @test entry.named[:color].label == fill("c")
    @test entry.named[:color].value == df.c
    @test entry.named[:marker].label == fill("")
    @test entry.named[:marker].value == ["a" "b"]
end

@testset "splitapply" begin
    df = (x = rand(1000), y = rand(1000), z = rand(1000), c = rand(["a", "b", "c"], 1000))
    df.c[1:3] .= ["a", "b", "c"] # ensure all three values exist
    d = mapping(:x => exp, [:y, :z], color = :c, marker = dims(1) => t -> ["1", "2"][t])
    layer = data(df) * d
    le = AlgebraOfGraphics.process_data(layer)
    entries = AlgebraOfGraphics.splitapply(le)
    @test length(entries) == 6
    for i in 1: 6
        @test entries[i].plottype === Any
        @test isempty(entries[i].attributes)
    end

    @test entries[1].positional[1].label == "x"
    @test entries[1].positional[1].value == exp.(df.x[df.c .== "a"])
    @test entries[1].positional[2].label == "y"
    @test entries[1].positional[2].value == df.y[df.c .== "a"]
    @test entries[1].named[:color].label == "c"
    @test entries[1].named[:color].value == fill("a")
    @test entries[1].named[:marker].label == ""
    @test entries[1].named[:marker].value == fill("1")

    @test entries[2].positional[1].label == "x"
    @test entries[2].positional[1].value == exp.(df.x[df.c .== "a"])
    @test entries[2].positional[2].label == "z"
    @test entries[2].positional[2].value == df.z[df.c .== "a"]
    @test entries[2].named[:color].label == "c"
    @test entries[2].named[:color].value == fill("a")
    @test entries[2].named[:marker].label == ""
    @test entries[2].named[:marker].value == fill("2")

    @test entries[3].positional[1].label == "x"
    @test entries[3].positional[1].value == exp.(df.x[df.c .== "b"])
    @test entries[3].positional[2].label == "y"
    @test entries[3].positional[2].value == df.y[df.c .== "b"]
    @test entries[3].named[:color].label == "c"
    @test entries[3].named[:color].value == fill("b")
    @test entries[3].named[:marker].label == ""
    @test entries[3].named[:marker].value == fill("1")

    @test entries[4].positional[1].label == "x"
    @test entries[4].positional[1].value == exp.(df.x[df.c .== "b"])
    @test entries[4].positional[2].label == "z"
    @test entries[4].positional[2].value == df.z[df.c .== "b"]
    @test entries[4].named[:color].label == "c"
    @test entries[4].named[:color].value == fill("b")
    @test entries[4].named[:marker].label == ""
    @test entries[4].named[:marker].value == fill("2")

    @test entries[5].positional[1].label == "x"
    @test entries[5].positional[1].value == exp.(df.x[df.c .== "c"])
    @test entries[5].positional[2].label == "y"
    @test entries[5].positional[2].value == df.y[df.c .== "c"]
    @test entries[5].named[:color].label == "c"
    @test entries[5].named[:color].value == fill("c")
    @test entries[5].named[:marker].label == ""
    @test entries[5].named[:marker].value == fill("1")

    @test entries[6].positional[1].label == "x"
    @test entries[6].positional[1].value == exp.(df.x[df.c .== "c"])
    @test entries[6].positional[2].label == "z"
    @test entries[6].positional[2].value == df.z[df.c .== "c"]
    @test entries[6].named[:color].label == "c"
    @test entries[6].named[:color].value == fill("c")
    @test entries[6].named[:marker].label == ""
    @test entries[6].named[:marker].value == fill("2")
end

