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

@testset "Presorted" begin
    p = [
        Presorted("a", 0x0000),
        Presorted("b", 0x0001),
        Presorted("c", 0x0002),
        Presorted("a", 0x0003),
        Presorted("b", 0x0004),
    ]
    @test unique(p) == p[1:3]
    @test hash(Presorted("a", 0x0000)) == hash(Presorted("a", 0x0001))

    p1 = [Presorted("b", 0x0000), Presorted("c", 0x0001)]
    p2 = [Presorted("a", 0x0000), Presorted("b", 0x0001)]
    @test AlgebraOfGraphics.possibly_mergesorted(p1, p2) == [Presorted("b", 0x0000), Presorted("c", 0x0001), Presorted("a", 0x0000)]

    p = [
        Presorted("a", 0x0002),
        Presorted("b", 0x0000),
        Presorted("c", 0x0001),
    ]
    @test sort(p) == [
        Presorted("b", 0x0000),
        Presorted("c", 0x0001),
        Presorted("a", 0x0002),
    ]
end
