
@testset "layers" begin
    df = (x = rand(1000), y = rand(1000), c = rand(["a", "b", "c"], 1000))
    d = mapping(:x, :y, color=:c)
    s = visual(color=:red) + mapping(markersize=:c)
    layers = data(df) * d * s
    @test layers[1].transformation isa AlgebraOfGraphics.Visual
    @test layers[1].transformation.attributes[:color] == :red
    @test layers[1].positional == Any[:x, :y]
    @test layers[1].named == NamedArguments((color=:c,))
    @test layers[1].data == AlgebraOfGraphics.Columns(df)
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

    layer = mapping(1:3, ["a", "b", "c"] => uppercase, color = "X")
    processedlayer = AlgebraOfGraphics.process_mappings(layer)
    @test processedlayer.positional[1] == fill(1:3)
    @test processedlayer.positional[2] == fill(["A", "B", "C"])
    @test processedlayer.primary[:color] == fill(["X", "X", "X"])

    layer = mapping(1:3 => "label" => scale(:somescale), color = "X" => lowercase => "NAME" => scale(:otherscale))
    @test AlgebraOfGraphics.shape(layer) == (1:3,)
    processedlayer = AlgebraOfGraphics.process_mappings(layer)
    @test processedlayer.labels[1] == fill("label")
    @test processedlayer.labels[:color] == fill("NAME")
    @test processedlayer.scale_mapping[1] == :somescale
    @test processedlayer.primary[:color] == fill(["x", "x", "x"])
    @test processedlayer.scale_mapping[:color] == :otherscale

    layer = data(df) * mapping(:x, direct(1:1000) => "y")
    processedlayer = AlgebraOfGraphics.process_mappings(layer)
    @test processedlayer.positional[2] == fill(1:1000)
    @test processedlayer.labels[2] == fill("y")

    layer = data(df) * mapping(:x, direct(zeros(2, 1000)) => "y")
    @test_throws_message "not allowed to use arrays that are not one-dimensional" AlgebraOfGraphics.process_mappings(layer)
end

@testset "Invalid use of continuous for categorical hardcoded mapping" begin
    df = (x = 1:4, y = 1:4, page = [1, 1, 2, 2], color = ["A", "B", "C", "D"])
    spec = data(df) * mapping(:x, :y, color = :color, layout = :page) * visual(Scatter)
    @test_throws_message "The `layout` mapping was used with continuous data" draw(spec)
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

    layer = mapping(1, 2, color = "A")
    @test AlgebraOfGraphics.shape(layer) == ()
    processedlayer = AlgebraOfGraphics.process_mappings(layer)
    @test processedlayer.primary[:color] == fill(["A"])
    @test processedlayer.positional[1] == fill([1])
    @test processedlayer.positional[2] == fill([2])
end

@testset "grouping" begin
    df = (x=rand(1000), y=rand(1000), z=rand(1000), w=rand(1000), c=rand(["a", "b", "c"], 1000))
    df.c[1:3] .= ["a", "b", "c"] # ensure all three values exist
    d = mapping(:x => exp, [:y, :z], color=:c, marker=dims(1) => t -> ["1", "2"][t], markersize=:w)
    layer = data(df) * d * visual(Scatter)
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
        @test processedlayers[i].plottype === Scatter
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

@testset "printing" begin
    spec = data((; x = 1:10, y = 11:20)) * mapping(:x, :y, color = :y) * visual(BarPlot) + mapping(:x) * visual(HLines)
    # testing printing exactly is finicky across Julia versions, just make sure it's not completely broken
    printout = @test_nowarn repr(spec)
    @test occursin("Layers with 2 elements", printout)
    @test occursin("Layer 1", printout)
    @test occursin("Layer 2", printout)
    @test occursin("transformation:", printout)
    @test occursin("data:", printout)
    @test occursin("positional:", printout)
    @test occursin("named:", printout)
end

@testset "transformation resulting in multiple processedlayers" begin
    struct DuplicateShifted end

    function (::DuplicateShifted)(p::ProcessedLayer)
        p2 = map(p) do pos, named
            return [_p .+ 10 for _p in pos], named
        end
        p2 = ProcessedLayer(p2; plottype = BarPlot)
        return ProcessedLayers([p, p2])
    end

    duplicate_shifted() = AlgebraOfGraphics.transformation(DuplicateShifted())

    fg = data((; x = 1:3, y = 4:6)) * mapping(:x, :y) * duplicate_shifted() |> draw

    pls = fg.grid[].processedlayers
    @test length(pls) == 2
    @test pls[1].plottype == Scatter
    @test pls[2].plottype == BarPlot
    @test pls[1].positional == [[1, 2, 3], [4, 5, 6]]
    @test pls[2].positional == [[11, 12, 13], [14, 15, 16]]
end
