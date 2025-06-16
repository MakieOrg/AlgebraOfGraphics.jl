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

    # issue 552
    v = ["1", "9", "10"]
    @test AlgebraOfGraphics.mergesorted(v, v) == v
end

@testset "arguments" begin
    s = Arguments([10, 20, 30])
    @test s == Any[10, 20, 30]
    t = map(keys(s), s) do k, v
        return "key $k and value $v"
    end
    @test t == ["key 1 and value 10", "key 2 and value 20", "key 3 and value 30"]

    s = NamedArguments([:a, :b, :c], [10, 20, 30])
    @test s == NamedArguments((a = 10, b = 20, c = 30))
    t = map(keys(s), s) do k, v
        return "key $k and value $v"
    end
    @test t == NamedArguments(
        [:a, :b, :c],
        ["key a and value 10", "key b and value 20", "key c and value 30"]
    )

    s = NamedArguments([:a, :b, :c], [1, 2, 3])
    odd, even = separate(isodd, s)
    @test odd == NamedArguments((a = 1, c = 3))
    @test even == NamedArguments((b = 2,))

    t = AlgebraOfGraphics.set(s, :d => 5, :a => 3)
    @test t == NamedArguments([:a, :b, :c, :d], [3, 2, 3, 5])

    s = NamedArguments([:a, :b, :c], [1, 2, 3])
    t = AlgebraOfGraphics.set(s)
    @test s == t
    @test keys(s) !== keys(t)

    s = NamedArguments([:a, :b, :c], [1, 2, 3])
    t = AlgebraOfGraphics.filterkeys(!in((:a, :b)), s)
    @test t == NamedArguments([:c], [3])
end

@testset "layout utils" begin
    fig = Figure()
    pos = fig[1, 1]
    subpos = pos[1, 2:3]
    ax = Axis(pos[2, 1])
    @test get_layout(fig) == get_layout(pos) == get_layout(subpos) == get_layout(ax) == fig.layout

    fig = Figure()
    pos = fig[1, 2] = GridLayout()
    @test get_layout(fig) != get_layout(pos)
    @test get_layout(pos) == pos
    @test get_layout(pos).parent == get_layout(fig)
end

@testset "shiftdims" begin
    @test AlgebraOfGraphics.shiftdims("a") == "a"
    @test AlgebraOfGraphics.shiftdims([1, 2]) == [1 2]
end
