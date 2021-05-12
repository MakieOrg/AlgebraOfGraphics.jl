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

df = (x = rand(1000), y = rand(1000), z = rand(1000), c = rand(["a", "b", "c"], 1000))
d = mapping(:x => exp, [:y, :z], color = :c, marker = dims(1) => t -> ["a", "b"][t])
layer = data(df) * d
le = AlgebraOfGraphics.process_data(layer)
entries = AlgebraOfGraphics.splitapply(le)
entries[1]

f = identity
positional, named = map(getvalue, le.positional), map(getvalue, le.named)

axs = Broadcast.combine_axes(positional..., named...)

list = Entry[]
for c in CartesianIndices(axs)
    p, n = nested_map((positional, named)) do v
        I = Broadcast.newindex(v, c)
        return v[I]
    end
    grouping_cols = Tuple(m for (_, m) in named if m isa AbstractVector && !iscontinuous(m))
    foreach(indices_iterator(grouping_cols)) do idxs
            submappings = map(labels, mappings) do label, v
                I = ntuple(ndims(v)) do n
                    i = n == 1 ? idxs : c[n-1]
                    return adjust_index(axs[n], axes(v, n), i)
                end
                return Labeled(label, view(v, I...))
            end
            discrete, continuous = separate!(submappings)
            new_entries = maybewrap(f(Entry(le.plottype, continuous, le.attributes)))
            for new_entry in maybewrap(new_entries)
                push!(list, recombine!(discrete, new_entry))
            end
        end
    end
return list
    
    1 == AlgebraOfGraphics.Labeled("x", df.x)
    AlgebraOfGraphics.process_transformations(layers)
    @test layers[1].transformations[1] isa AlgebraOfGraphics.Visual
    @test layers[1].transformations[1].attributes[:color] == :red
    @test layers[1].positional == (:x, :y)
    @test layers[1].named == (color=:c,)
    @test layers[1].data == df
# end


    AlgebraOfGraphics.process_transformations(layers)
1
# mappings = pairs.(getproperty.(res, :mapping))
# @test last(mappings[1][1]).value == mapping(df[idx1, :x], df[idx1, :y]).value
# @test last(mappings[1][2]).value == mapping(df[idx2, :x], df[idx2, :y]).value
# @test last(mappings[2][1]).value == mapping(df[idx1, :x], df[idx1, :y], markersize = df[idx1, :c]).value
# @test last(mappings[2][2]).value == mapping(df[idx2, :x], df[idx2, :y], markersize = df[idx2, :c]).value

# @test first(mappings[1][1]).color isa NamedDimsArray
# @test only(first(mappings[1][1]).color) == 1999
# @test dimnames(first(mappings[1][1]).color) == (:c,)

# @test first(mappings[1][2]).color isa NamedDimsArray
# @test only(first(mappings[1][2]).color) == 2008
# @test dimnames(first(mappings[1][2]).color) == (:c,)

# @test first(mappings[2][1]).color isa NamedDimsArray
# @test only(first(mappings[2][1]).color) == 1999
# @test dimnames(first(mappings[2][1]).color) == (:c,)

# @test first(mappings[2][2]).color isa NamedDimsArray
# @test only(first(mappings[2][2]).color) == 2008
# @test dimnames(first(mappings[2][2]).color) == (:c,)

# @test_throws ArgumentError data(df) * mapping(:Cyll)

# x = rand(5, 3, 2)
# y = rand(5, 3)
# s = dims(1) * mapping(x, y, color = dims(2)) 

# res = pairs(s)
# for (i, r) in enumerate(res)
#     group, st = r
#     @test group == (; color = mod1(i, 3))
#     xsl = x[:, mod1(i, 3), (i > 3) + 1]
#     ysl = y[:, mod1(i, 3)]
#     @test st.value == mapping(xsl, ysl).value
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

# @testset "product" begin
#     s = dims() * mapping(1:2, ["a", "b"], color = dims(1))
#     ps = pairs(s)
#     @test ps[1] == Pair((color = 1,), mapping(1, "a"))
#     @test ps[2] == Pair((color = 2,), mapping(2, "b"))
# end
