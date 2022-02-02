@testset "clean facet attributes" begin
    collection = (a=11, b=automatic, c=:test)
    value = get_with_options(collection, :a, options=(11, 12))
    @test value == 11
    value = get_with_options(collection, :d, options=(11, 12))
    @test value == automatic
    @test @test_logs(
        (:warn, "Replaced invalid keyword a = 11 by automatic. Valid values are :c, :d, or automatic."),
        get_with_options(collection, :a, options=(:c, :d))
    ) == automatic

    # consistent `x` and `y` labels
    df = (x=rand(100), y=rand(100), i=rand(["a", "b", "c"], 100), j=rand(["d", "e", "f"], 100))
    plt = data(df) * mapping(:x, :y, col=:i, row=:j)
    aes = compute_axes_grid(Figure(), plt)
    @test consistent_xlabels(aes)
    @test consistent_ylabels(aes)
    @test colwise_consistent_xlabels(aes)
    @test rowwise_consistent_ylabels(aes)
    @test clean_facet_attributes(aes, (hidexdecorations=automatic,)) ==
        (linkxaxes=:all, linkyaxes=:all, hidexdecorations=true, hideydecorations=true)
    @test clean_facet_attributes(aes, (hidexdecorations=automatic, linkxaxes=false)) ==
        (linkxaxes=:none, linkyaxes=:all, hidexdecorations=false, hideydecorations=true)
    @test clean_facet_attributes(aes, (hideydecorations=false, linkyaxes=:minimal)) ==
        (linkxaxes=:all, linkyaxes=:rowwise, hidexdecorations=true, hideydecorations=false)

    # consistent `x` and directionally consistent `y` labels
    df = (x=rand(100), y1=rand(100), y2=rand(100), i=rand(["a", "b", "c"], 100))
    plt = data(df) * mapping(:x, [:y1, :y2], col=:i, row=dims(1))
    aes = compute_axes_grid(Figure(), plt)
    @test consistent_xlabels(aes)
    @test !consistent_ylabels(aes)
    @test colwise_consistent_xlabels(aes)
    @test rowwise_consistent_ylabels(aes)
    @test clean_facet_attributes(aes, (hidexdecorations=automatic,)) ==
        (linkxaxes=:all, linkyaxes=:rowwise, hidexdecorations=true, hideydecorations=true)
    @test clean_facet_attributes(aes, (hidexdecorations=automatic, linkxaxes=false)) ==
        (linkxaxes=:none, linkyaxes=:rowwise, hidexdecorations=false, hideydecorations=true)
    @test clean_facet_attributes(aes, (hideydecorations=false, linkxaxes=:minimal)) ==
        (linkxaxes=:colwise, linkyaxes=:rowwise, hidexdecorations=true, hideydecorations=false)

    # facet wrap
    df = (x=rand(100), y=rand(100), i=rand(["a", "b", "c", "d"], 100))
    plt = data(df) * mapping(:x, :y, layout=:i)
    aes = compute_axes_grid(Figure(), plt)
    @test consistent_xlabels(aes)
    @test consistent_ylabels(aes)
    @test colwise_consistent_xlabels(aes)
    @test rowwise_consistent_ylabels(aes)
    @test clean_facet_attributes(aes, (hidexdecorations=automatic,)) ==
        (linkxaxes=:all, linkyaxes=:all, hidexdecorations=true, hideydecorations=true)
    @test clean_facet_attributes(aes, (hidexdecorations=automatic, linkxaxes=false)) ==
        (linkxaxes=:none, linkyaxes=:all, hidexdecorations=false, hideydecorations=true)
    @test clean_facet_attributes(aes, (hideydecorations=false, linkyaxes=:minimal)) ==
        (linkxaxes=:all, linkyaxes=:rowwise, hidexdecorations=true, hideydecorations=false)
end

@testset "facet labels" begin
    df = (x=rand(100), y=rand(100), i=rand(["a", "b", "c"], 100), j=rand(["d", "e", "f"], 100))
    plt = data(df) * mapping(:x, :y, col=:i, row=:j)
    fig = Figure();
    aes = compute_axes_grid(fig, plt)
    scales = first(aes).categoricalscales
    ax = first(aes).axis

    labels = col_labels!(fig, aes, scales[:col])
    @test labels[1].text[] == "a"
    @test labels[2].text[] == "b"
    @test labels[3].text[] == "c"
    for (i, label) in enumerate(labels)
        @test label in contents(fig[1, i, Top()])
        @test label.rotation[] == 0
        @test label.padding[] == (0, 0, ax.titlegap[], 0)
        @test label.color == ax.titlecolor
        @test label.font == ax.titlefont
        @test label.textsize == ax.titlesize
    end

    labels = row_labels!(fig, aes, scales[:row])
    @test labels[1].text[] == "d"
    @test labels[2].text[] == "e"
    @test labels[3].text[] == "f"
    for (i, label) in enumerate(labels)
        @test label in contents(fig[i, 3, Right()])
        @test label.rotation[] == -π/2
        @test label.padding[] == (ax.titlegap[], 0, 0, 0)
        @test label.color == ax.titlecolor
        @test label.font == ax.titlefont
        @test label.textsize == ax.titlesize
    end

    df = (x=rand(100), y=rand(100), i=rand(["a", "b", "c", "d"], 100))
    plt = data(df) * mapping(:x, :y, layout=:i)
    fig = Figure();
    aes = compute_axes_grid(fig, plt)
    scales = first(aes).categoricalscales
    ax = first(aes).axis

    labels = panel_labels!(fig, aes, scales[:layout])
    @test labels[1].text[] == "a"
    @test labels[2].text[] == "b"
    @test labels[3].text[] == "c"
    @test labels[4].text[] == "d"
    for (I, label) in enumerate(labels)
        i, j = fldmod1(I, 2)
        @test label in contents(fig[i, j, Top()])
        @test label.rotation[] == 0
        @test label.padding[] == (0, 0, ax.titlegap[], 0)
        @test label.color == ax.titlecolor
        @test label.font == ax.titlefont
        @test label.textsize == ax.titlesize
    end
end