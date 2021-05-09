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

# @testset "product" begin
#     s = dims() * mapping(1:2, ["a", "b"], color = dims(1))
#     ps = pairs(s)
#     @test ps[1] == Pair((color = 1,), mapping(1, "a"))
#     @test ps[2] == Pair((color = 2,), mapping(2, "b"))
# end

# @testset "contexts" begin
#     mpg = dataset("ggplot2", "mpg")
#     d = mapping(:Cyl, :Hwy, color = :Year => categorical)
#     s = visual(color = :red, font = 10) + mapping(markersize = :Year)
#     res = data(mpg) * d * s
#     @test res[1].options == (color = :red, font = 10)

#     idx1 = mpg.Year .== 1999
#     idx2 = mpg.Year .== 2008

#     mappings = pairs.(getproperty.(res, :mapping))
#     @test last(mappings[1][1]).value == mapping(mpg[idx1, :Cyl], mpg[idx1, :Hwy]).value
#     @test last(mappings[1][2]).value == mapping(mpg[idx2, :Cyl], mpg[idx2, :Hwy]).value
#     @test last(mappings[2][1]).value == mapping(mpg[idx1, :Cyl], mpg[idx1, :Hwy], markersize = mpg[idx1, :Year]).value
#     @test last(mappings[2][2]).value == mapping(mpg[idx2, :Cyl], mpg[idx2, :Hwy], markersize = mpg[idx2, :Year]).value

#     @test first(mappings[1][1]).color isa NamedDimsArray
#     @test only(first(mappings[1][1]).color) == 1999
#     @test dimnames(first(mappings[1][1]).color) == (:Year,)

#     @test first(mappings[1][2]).color isa NamedDimsArray
#     @test only(first(mappings[1][2]).color) == 2008
#     @test dimnames(first(mappings[1][2]).color) == (:Year,)

#     @test first(mappings[2][1]).color isa NamedDimsArray
#     @test only(first(mappings[2][1]).color) == 1999
#     @test dimnames(first(mappings[2][1]).color) == (:Year,)

#     @test first(mappings[2][2]).color isa NamedDimsArray
#     @test only(first(mappings[2][2]).color) == 2008
#     @test dimnames(first(mappings[2][2]).color) == (:Year,)

#     @test_throws ArgumentError data(mpg) * mapping(:Cyll)

#     x = rand(5, 3, 2)
#     y = rand(5, 3)
#     s = dims(1) * mapping(x, y, color = dims(2)) 

#     res = pairs(s)
#     for (i, r) in enumerate(res)
#         group, st = r
#         @test group == (; color = mod1(i, 3))
#         xsl = x[:, mod1(i, 3), (i > 3) + 1]
#         ysl = y[:, mod1(i, 3)]
#         @test st.value == mapping(xsl, ysl).value
#     end
# end

# @testset "compute specs" begin
#     wong = default_palettes[:color][]
#     t = (x = [1, 2], y = [10, 20], z = [3, 4], c = ["a", "b"])
#     d = mapping(:x, :y, color = :c)
#     s = visual(:log) * visual(font = 10) + mapping(size = :z)
#     ds = data(t) * d
#     sl = ds * s
#     @test length(sl) == 2

#     res = run_pipeline(sl)

#     @test res[1].options.color == wong[1]
#     @test res[2].options.color == wong[2]
#     @test dimnames(res[1].pkeys.color) == (:c,)
#     @test dimnames(res[2].pkeys.color) == (:c,)
#     @test res[1].mapping.value == mapping([1], [10]).value
#     @test res[2].mapping.value == mapping([2], [20]).value

#     @test res[3].options.color == wong[1]
#     @test res[4].options.color == wong[2]
#     @test dimnames(res[3].pkeys.color) == (:c,)
#     @test dimnames(res[4].pkeys.color) == (:c,)
#     @test res[3].mapping.value == mapping([1], [10], size = [3]).value
#     @test res[4].mapping.value == mapping([2], [20], size = [4]).value
# end
