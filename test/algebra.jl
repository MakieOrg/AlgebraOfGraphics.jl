@testset "layers" begin
    df = (x = rand(1000), y = rand(1000), c = rand(["a", "b", "c"], 1000))
    d = mapping(:x, :y, color = :c)
    s = visual(color = :red) + mapping(markersize = :c)
    layers = data(df) * d * s
    @test layers[1].transformation isa AlgebraOfGraphics.Visual
    @test layers[1].transformation.attributes[:color] == :red
    @test layers[1].positional == Any[:x, :y]
    @test layers[1].named == NamedArguments((color = :c,))
    @test layers[1].data == AlgebraOfGraphics.Columns(df)
end

@testset "process_mappings" begin
    df = (x = rand(1000), y = rand(1000), z = rand(1000), c = rand(["a", "b", "c"], 1000))
    d = mapping(:x => exp, [:y, :z], color = :c, marker = dims(1) => renamer(["a", "b"]))
    layer = data(df) * d
    processedlayer = AlgebraOfGraphics.process_mappings(layer)
    @test processedlayer.positional[1] == fill(map(exp, df.x))
    @test processedlayer.positional[2] == [df.y, df.z]
    @test processedlayer.primary[:color] == fill(df.c)
    @test processedlayer.primary[:marker] == [fill(Sorted(1, "a")), fill(Sorted(2, "b"))]
    @test processedlayer.named == NamedArguments((;))
    @test processedlayer.labels[1] == fill("x")
    @test processedlayer.labels[2] == ["y", "z"]
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

    layer = data(df) * mapping(:x => sqrt => "sqrt(X)" => scale(:X2))
    processedlayer = AlgebraOfGraphics.process_mappings(layer)
    @test processedlayer.positional[1] == fill(sqrt.(df.x))
    @test processedlayer.labels[1] == fill("sqrt(X)")
    @test processedlayer.scale_mapping[1] == :X2

    layer = data(df) * mapping(:x, direct(1:1000) => "y")
    processedlayer = AlgebraOfGraphics.process_mappings(layer)
    @test processedlayer.positional[2] == fill(1:1000)
    @test processedlayer.labels[2] == fill("y")

    layer = data(df) * mapping(:x, direct(zeros(2, 1000)) => "y")
    @test_throws_message "not allowed to use arrays that are not one-dimensional" AlgebraOfGraphics.process_mappings(layer)
end

@testset "column labels processing" begin
    df = DataFrames.DataFrame(
        t = 1:10,
        v = sin.(1:10),
        c = sqrt.(1:10),
    )

    layer = data(df) * mapping(:t, :v, color = :c) * visual(Scatter)

    processedlayer = AlgebraOfGraphics.process_mappings(layer)
    @test processedlayer.labels[1] == fill("t")
    @test processedlayer.labels[2] == fill("v")
    @test processedlayer.labels[:color] == fill("c")

    DataFrames.colmetadata!(df, :t, "label", "Time")
    DataFrames.colmetadata!(df, :v, "label", "Volume")
    DataFrames.colmetadata!(df, :c, "label", "Concentration")

    processedlayer = AlgebraOfGraphics.process_mappings(layer)
    @test processedlayer.labels[1] == fill("Time")
    @test processedlayer.labels[2] == fill("Volume")
    @test processedlayer.labels[:color] == fill("Concentration")

    layer = data(df) * mapping(:t => "T", :v => "V", color = :c => "C") * visual(Scatter)

    processedlayer = AlgebraOfGraphics.process_mappings(layer)
    @test processedlayer.labels[1] == fill("T")
    @test processedlayer.labels[2] == fill("V")
    @test processedlayer.labels[:color] == fill("C")
end

@testset "plain `mapping`" begin
    layer = mapping(1:3, 4:6, text = fill("hello", 3) => verbatim)
    processedlayer = AlgebraOfGraphics.process_mappings(layer)
    @test processedlayer.positional[1] == fill(1:3)
    @test processedlayer.positional[2] == fill(4:6)
    @test processedlayer.named[:text] == fill(verbatim.(fill("hello", 3)))

    layer = mapping(1:3, 4:6 => -, text = "hello" => verbatim)
    processedlayer = AlgebraOfGraphics.process_mappings(layer)
    @test processedlayer.positional[1] == fill(1:3)
    @test processedlayer.positional[2] == fill(.-(4:6))
    @test processedlayer.named[:text] == fill(verbatim.(fill("hello", 3)))
end

@testset "shape" begin
    df = (x = rand(1000), y = rand(1000), z = rand(1000), c = rand(["a", "b", "c"], 1000))
    d = mapping(:x => exp, [:y, :z], color = :c, marker = dims(1) => renamer(["a", "b"]))
    layer = data(df) * d
    @test AlgebraOfGraphics.shape(layer) == (Base.OneTo(2),)
    processedlayer = AlgebraOfGraphics.process_mappings(layer)
    @test AlgebraOfGraphics.shape(processedlayer) == (Base.OneTo(2),)

    d = mapping(:x => exp, (:y, :z) => +, color = :c)
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
    df = (x = rand(1000), y = rand(1000), z = rand(1000), w = rand(1000), c = rand(["a", "b", "c"], 1000))
    df.c[1:3] .= ["a", "b", "c"] # ensure all three values exist
    d = mapping(:x => exp, [:y, :z], color = :c, marker = dims(1) => t -> ["1", "2"][t.index], markersize = :w)
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
    for i in 1:6
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

@testset "verbatim works without scales" begin
    colors = RGBf.(range(0, 1, length = 10), 0.5, 0.5)
    fontsizes = range(20, 40, length = 10)
    aligns = tuple.(range(0, 1, length = 10), range(0, 1, length = 10))
    layer = mapping(
        1:10,
        1:10,
        text = "hi" => verbatim,
        color = colors => verbatim,
        fontsize = fontsizes => verbatim,
        align = aligns => verbatim,
    ) * visual(Makie.Text)

    ag = AlgebraOfGraphics.compute_axes_grid(layer, scales())
    e = only(ag[1].entries)
    @test e.named[:fontsize] == fontsizes
    @test e.named[:align] == aligns
    @test e.named[:color] == colors

    @test_nowarn draw(layer)

    layer2 = mapping(
        1:10,
        1:10,
        layout = repeat(["A", "B"], inner = 5),
        text = "hi" => verbatim,
        color = colors => verbatim,
        fontsize = fontsizes => verbatim,
        align = aligns => verbatim,
    ) * visual(Makie.Text)

    ag = AlgebraOfGraphics.compute_axes_grid(layer2, scales())
    e = only(ag[1].entries)
    @test e.named[:fontsize] == fontsizes[1:5]
    @test e.named[:align] == aligns[1:5]
    @test e.named[:color] == colors[1:5]
    e2 = only(ag[2].entries)
    @test e2.named[:fontsize] == fontsizes[6:10]
    @test e2.named[:align] == aligns[6:10]
    @test e2.named[:color] == colors[6:10]
end

@testset "hardcoded categoricals work with continuous data" begin

    hardcodeds = [:layout, :col, :row, :group]

    for hardcoded in hardcodeds
        aes = AlgebraOfGraphics.hardcoded_mapping(hardcoded)
        @test aes !== nothing
        fg = draw(mapping(1:3, 1:3; (; hardcoded => [3, 1, 2])...))
        sc = fg.grid[1].categoricalscales[aes][nothing]
        @test AlgebraOfGraphics.datavalues(sc) == [1, 2, 3]
        expected_palette = hardcoded === :layout ? [(1, 1), (1, 2), (2, 1)] : 1:3
        @test AlgebraOfGraphics.plotvalues(sc) == expected_palette
    end
end
@testset "tuples of columns can be passed without transform func" begin
    spec = data((; x = 1:4, y = 1:4, a = [2, 1, 1, 2], b = [4, 4, 3, 3])) *
        mapping(:x, :y, row = (:a, :b))
    fg = draw(spec)
    sc = fg.grid[1].categoricalscales[AlgebraOfGraphics.AesRow][nothing]
    @test AlgebraOfGraphics.datavalues(sc) == [(1, 3), (1, 4), (2, 3), (2, 4)]
    @test AlgebraOfGraphics.plotvalues(sc) == 1:4
end

@testset "dims labels" begin
    # Basic dims(1) with column labels
    wide_data = (; x = [1, 2], y1 = [3, 4], y2 = [5, 6])
    fg = draw(data(wide_data) * mapping(:x, [:y1, :y2], color = dims(1)) * visual(Scatter))
    color_scale = fg.grid[1].categoricalscales[AlgebraOfGraphics.AesColor][nothing]
    labels = AlgebraOfGraphics.datalabels(color_scale)
    @test labels == ["y1", "y2"]
    
    # Two sets of one-dimensional labels (both match dimension 1)
    wide_data2 = (; x1 = [1, 2], x2 = [1.5, 2.5], y1 = [3, 4], y2 = [5, 6])
    fg = draw(data(wide_data2) * mapping([:x1, :x2], [:y1, :y2], color = dims(1)) * visual(Scatter))
    color_scale = fg.grid[1].categoricalscales[AlgebraOfGraphics.AesColor][nothing]
    labels = AlgebraOfGraphics.datalabels(color_scale)
    @test labels == ["x1, y1", "x2, y2"]
    
    # Single-element array
    fg = draw(data(wide_data2) * mapping(:x1, [:y1], color = dims(1)) * visual(Scatter))
    color_scale = fg.grid[1].categoricalscales[AlgebraOfGraphics.AesColor][nothing]
    labels = AlgebraOfGraphics.datalabels(color_scale)
    @test labels == ["y1"]
    
    # Two vectors with single elements each
    fg = draw(data(wide_data2) * mapping([:x1], [:y1], color = dims(1)) * visual(Scatter))
    color_scale = fg.grid[1].categoricalscales[AlgebraOfGraphics.AesColor][nothing]
    labels = AlgebraOfGraphics.datalabels(color_scale)
    @test labels == ["x1, y1"]
    
    # Multidimensional case - dims(2) with row vector
    fg = draw(data(wide_data2) * mapping([:x1, :x2], [:y1 :y2], color = dims(2)) * visual(Scatter))
    color_scale = fg.grid[1].categoricalscales[AlgebraOfGraphics.AesColor][nothing]
    labels = AlgebraOfGraphics.datalabels(color_scale)
    @test labels == ["y1", "y2"]
    
    # Multidimensional case - dims(1) with column and row vectors
    fg = draw(data(wide_data2) * mapping([:x1, :x2], [:y1 :y2], color = dims(1)) * visual(Scatter))
    color_scale = fg.grid[1].categoricalscales[AlgebraOfGraphics.AesColor][nothing]
    labels = AlgebraOfGraphics.datalabels(color_scale)
    @test labels == ["x1", "x2"]
    
    # Multidimensional case with multiple dims
    fg = draw(data(wide_data2) * mapping([:x1, :x2], [:y1 :y2], color = dims(1, 2)) * visual(Scatter))
    color_scale = fg.grid[1].categoricalscales[AlgebraOfGraphics.AesColor][nothing]
    labels = AlgebraOfGraphics.datalabels(color_scale)
    @test labels == ["x1, y1", "x1, y2", "x2, y1", "x2, y2"]

    # flip to dims(2, 1)
    fg = draw(data(wide_data2) * mapping([:x1, :x2], [:y1 :y2], color = dims(2, 1)) * visual(Scatter))
    color_scale = fg.grid[1].categoricalscales[AlgebraOfGraphics.AesColor][nothing]
    labels = AlgebraOfGraphics.datalabels(color_scale)
    @test labels == ["y1, x1", "y2, x1", "y1, x2", "y2, x2"]
    
    # dims with renamer should still work
    times = [[1, 2, 3], [1, 2, 3, 4], [1, 2, 3]]
    measurements = [randn(3), randn(4), randn(3)]
    fg = draw(pregrouped(
        times => "Time",
        measurements => "Measurement",
        color = dims(1) => renamer(["Subject 1", "Subject 2", "Subject 3"]),
    ) * visual(Lines))
    color_scale = fg.grid[1].categoricalscales[AlgebraOfGraphics.AesColor][nothing]
    labels = AlgebraOfGraphics.datalabels(color_scale)
    @test labels == ["Subject 1", "Subject 2", "Subject 3"]
end
