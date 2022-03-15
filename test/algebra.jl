
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
    processedlayer = AlgebraOfGraphics.process_mappings(layer)
    @test processedlayer.positional[1] == fill(map(exp, df.x))
    @test processedlayer.positional[2] == [df.y, df.z]
    @test processedlayer.primary[:color] == fill(df.c)
    @test processedlayer.primary[:marker] == [fill(Sorted(1, "a")), fill(Sorted(2, "b"))]
    @test processedlayer.named == NamedArguments((;))
    @test processedlayer.labels[1] == fill("x")
    @test processedlayer.labels[2] ==  ["y", "z"]
    @test processedlayer.labels[:color] == fill("c")
    @test processedlayer.labels[:marker] == ""
end

@testset "shape" begin
    df = (x=rand(1000), y=rand(1000), z=rand(1000), c=rand(["a", "b", "c"], 1000))
    d = mapping(:x => exp, [:y, :z], color=:c, marker = dims(1) => renamer(["a", "b"]))
    layer = data(df) * d
    @test AlgebraOfGraphics.shape(layer) == (Base.OneTo(2),)
    processedlayer = AlgebraOfGraphics.process_mappings(layer)
    @test AlgebraOfGraphics.shape(processedlayer) == (Base.OneTo(2),)

    d = mapping(:x => exp, (:y, :z) => +, color=:c)
    layer = data(df) * d
    @test AlgebraOfGraphics.shape(layer) == ()
    processedlayer = AlgebraOfGraphics.process_mappings(layer)
    @test AlgebraOfGraphics.shape(processedlayer) == ()
end

@testset "grouping" begin
    df = (x=rand(1000), y=rand(1000), z=rand(1000), w=rand(1000), c=rand(["a", "b", "c"], 1000))
    df.c[1:3] .= ["a", "b", "c"] # ensure all three values exist
    d = mapping(:x => exp, [:y, :z], color=:c, marker=dims(1) => t -> ["1", "2"][t], markersize=:w)
    layer = data(df) * d
    processedlayer = AlgebraOfGraphics.ProcessedLayer(layer)
    processedlayers = map(CartesianIndices(AlgebraOfGraphics.shape(processedlayer))) do c
        primary, positional, named = map((processedlayer.primary, processedlayer.positional, processedlayer.named)) do tup
            return map(v -> v[c], tup)
        end
        labels = map(l -> AlgebraOfGraphics.getnewindex(l, c), processedlayer.labels)
        return ProcessedLayer(processedlayer; primary, positional, named, labels)
    end
    @test length(processedlayers) == 6
    for i in 1: 6
        @test processedlayers[i].plottype === Any
        @test isempty(processedlayers[i].attributes)
        @test processedlayers[i].labels[1] == "x"
        @test processedlayers[i].labels[2] == (i ≤ 3 ? "y" : "z")
        @test processedlayers[i].labels[:color] == "c"
        @test processedlayers[i].labels[:marker] == ""
        @test processedlayers[i].labels[:markersize] == "w"
    end

    @test processedlayers[1].primary[:color] == "a"
    @test processedlayers[1].primary[:marker] == "1"
    @test processedlayers[1].positional[1] == exp.(df.x[df.c .== "a"])
    @test processedlayers[1].positional[2] == df.y[df.c .== "a"]
    @test processedlayers[1].named[:markersize] == df.w[df.c .== "a"]
    
    @test processedlayers[2].primary[:color] == "b"
    @test processedlayers[2].primary[:marker] == "1"
    @test processedlayers[2].positional[1] == exp.(df.x[df.c .== "b"])
    @test processedlayers[2].positional[2] == df.y[df.c .== "b"]
    @test processedlayers[2].named[:markersize] == df.w[df.c .== "b"]
    
    @test processedlayers[3].primary[:color] == "c"
    @test processedlayers[3].primary[:marker] == "1"
    @test processedlayers[3].positional[1] == exp.(df.x[df.c .== "c"])
    @test processedlayers[3].positional[2] == df.y[df.c .== "c"]
    @test processedlayers[3].named[:markersize] == df.w[df.c .== "c"]

    @test processedlayers[4].primary[:color] == "a"
    @test processedlayers[4].primary[:marker] == "2"
    @test processedlayers[4].positional[1] == exp.(df.x[df.c .== "a"])
    @test processedlayers[4].positional[2] == df.z[df.c .== "a"]
    @test processedlayers[4].named[:markersize] == df.w[df.c .== "a"]

    @test processedlayers[5].primary[:color] == "b"
    @test processedlayers[5].primary[:marker] == "2"
    @test processedlayers[5].positional[1] == exp.(df.x[df.c .== "b"])
    @test processedlayers[5].positional[2] == df.z[df.c .== "b"]
    @test processedlayers[5].named[:markersize] == df.w[df.c .== "b"]

    @test processedlayers[6].primary[:color] == "c"
    @test processedlayers[6].primary[:marker] == "2"
    @test processedlayers[6].positional[1] == exp.(df.x[df.c .== "c"])
    @test processedlayers[6].positional[2] == df.z[df.c .== "c"]
    @test processedlayers[6].named[:markersize] == df.w[df.c .== "c"]
end