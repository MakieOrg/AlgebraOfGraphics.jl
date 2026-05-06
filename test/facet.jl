@testset "clean facet attributes" begin
    # consistent `x` and `y` labels
    df = (x = rand(100), y = rand(100), i = rand(["a", "b", "c"], 100), j = rand(["d", "e", "f"], 100))
    plt = data(df) * mapping(:x, :y, col = :i, row = :j)
    aes = compute_axes_grid(Figure(), plt)
    @test consistent_xlabels(aes)
    @test consistent_ylabels(aes)
    @test colwise_consistent_xlabels(aes)
    @test rowwise_consistent_ylabels(aes)
    @test clean_facet_attributes(aes, hidexdecorations = automatic) ==
        (linkxaxes = :all, linkyaxes = :all, hidexdecorations = true, hideydecorations = true, singlexlabel = true, singleylabel = true)
    @test clean_facet_attributes(aes, hidexdecorations = automatic, linkxaxes = false) ==
        (linkxaxes = :none, linkyaxes = :all, hidexdecorations = false, hideydecorations = true, singlexlabel = true, singleylabel = true)
    @test clean_facet_attributes(aes, hideydecorations = false, linkyaxes = :minimal) ==
        (linkxaxes = :all, linkyaxes = :rowwise, hidexdecorations = true, hideydecorations = false, singlexlabel = true, singleylabel = true)

    @test @test_logs(
        (
            :warn, "Replaced invalid keyword linkxaxes = :rowwise by automatic. " *
                "Valid values are :all, :colwise, :minimal, :none, true, false, or automatic.",
        ),
        clean_facet_attributes(aes, hidexdecorations = automatic, linkxaxes = :rowwise)
    ) == (linkxaxes = :all, linkyaxes = :all, hidexdecorations = true, hideydecorations = true, singlexlabel = true, singleylabel = true)
    @test @test_logs(
        (
            :warn, "Replaced invalid keyword hidexdecorations = nothing by automatic. " *
                "Valid values are true, false, or automatic.",
        ),
        clean_facet_attributes(aes, hidexdecorations = nothing, linkxaxes = :colwise)
    ) == (linkxaxes = :colwise, linkyaxes = :all, hidexdecorations = true, hideydecorations = true, singlexlabel = true, singleylabel = true)

    # consistent `x` and directionally consistent `y` labels
    df = (x = rand(100), y1 = rand(100), y2 = rand(100), i = rand(["a", "b", "c"], 100))
    plt = data(df) * mapping(:x, [:y1, :y2], col = :i, row = dims(1)) * visual(Scatter)
    aes = compute_axes_grid(Figure(), plt)
    @test consistent_xlabels(aes)
    @test !consistent_ylabels(aes)
    @test colwise_consistent_xlabels(aes)
    @test rowwise_consistent_ylabels(aes)
    @test clean_facet_attributes(aes, hidexdecorations = automatic) ==
        (linkxaxes = :all, linkyaxes = :rowwise, hidexdecorations = true, hideydecorations = true, singlexlabel = true, singleylabel = false)
    @test clean_facet_attributes(aes, hidexdecorations = automatic, linkxaxes = false) ==
        (linkxaxes = :none, linkyaxes = :rowwise, hidexdecorations = false, hideydecorations = true, singlexlabel = true, singleylabel = false)
    @test clean_facet_attributes(aes, hideydecorations = false, linkxaxes = :minimal) ==
        (linkxaxes = :colwise, linkyaxes = :rowwise, hidexdecorations = true, hideydecorations = false, singlexlabel = true, singleylabel = false)

    # facet wrap
    df = (x = rand(100), y = rand(100), i = rand(["a", "b", "c", "d"], 100))
    plt = data(df) * mapping(:x, :y, layout = :i)
    aes = compute_axes_grid(Figure(), plt)
    @test consistent_xlabels(aes)
    @test consistent_ylabels(aes)
    @test colwise_consistent_xlabels(aes)
    @test rowwise_consistent_ylabels(aes)
    @test clean_facet_attributes(aes, hidexdecorations = automatic) ==
        (linkxaxes = :all, linkyaxes = :all, hidexdecorations = true, hideydecorations = true, singlexlabel = true, singleylabel = true)
    @test clean_facet_attributes(aes, hidexdecorations = automatic, linkxaxes = false) ==
        (linkxaxes = :none, linkyaxes = :all, hidexdecorations = false, hideydecorations = true, singlexlabel = true, singleylabel = true)
    @test clean_facet_attributes(aes, hideydecorations = false, linkyaxes = :minimal) ==
        (linkxaxes = :all, linkyaxes = :rowwise, hidexdecorations = true, hideydecorations = false, singlexlabel = true, singleylabel = true)
end

@testset "facet labels" begin
    df = (x = rand(100), y = rand(100), i = rand(["a", "b", "c"], 100), j = rand(["d", "e", "f"], 100))
    plt = data(df) * mapping(:x, :y, col = :i, row = :j)
    fig = Figure()
    aes = compute_axes_grid(fig, plt)
    scales = first(aes).categoricalscales
    ax = first(aes).axis

    labels = col_labels!(fig, aes, scales[AlgebraOfGraphics.AesCol][nothing])
    @test labels[1].text[] == "a"
    @test labels[2].text[] == "b"
    @test labels[3].text[] == "c"
    for (i, label) in enumerate(labels)
        @test label in contents(fig[1, i, Top()])
        @test label.rotation[] == 0
        @test label.padding[] == (0, 0, ax.titlegap[], 0)
        @test label.color[] == ax.titlecolor[]
        @test label.font[] == ax.titlefont[]
        @test label.fontsize[] == ax.titlesize[]
        @test label.visible[] == ax.titlevisible[]
    end

    labels = row_labels!(fig, aes, scales[AlgebraOfGraphics.AesRow][nothing])
    @test labels[1].text[] == "d"
    @test labels[2].text[] == "e"
    @test labels[3].text[] == "f"
    for (i, label) in enumerate(labels)
        @test label in contents(fig[i, 3, Right()])
        @test label.rotation[] ≈ -π / 2
        @test label.padding[] == (ax.titlegap[], 0, 0, 0)
        @test label.color[] == ax.titlecolor[]
        @test label.font[] == ax.titlefont[]
        @test label.fontsize[] == ax.titlesize[]
        @test label.visible[] == ax.titlevisible[]
    end

    df = (x = rand(100), y = rand(100), i = rand(["a", "b", "c", "d"], 100))
    plt = data(df) * mapping(:x, :y, layout = :i)
    fig = Figure()
    aes = compute_axes_grid(fig, plt)
    scales = first(aes).categoricalscales
    ax = first(aes).axis

    labels = panel_labels!(fig, aes, scales[AlgebraOfGraphics.AesLayout][nothing])
    @test labels[1].text[] == "a"
    @test labels[2].text[] == "b"
    @test labels[3].text[] == "c"
    @test labels[4].text[] == "d"
    for (I, label) in enumerate(labels)
        i, j = fldmod1(I, 2)
        @test label in contents(fig[i, j, Top()])
        @test label.rotation[] == 0
        @test label.padding[] == (0, 0, ax.titlegap[], 0)
        @test label.color[] == ax.titlecolor[]
        @test label.font[] == ax.titlefont[]
        @test label.fontsize[] == ax.titlesize[]
        @test label.visible[] == ax.titlevisible[]
    end
end

@testset "spanned labels" begin
    df = (x = rand(100), y = rand(100), i = rand(["a", "b", "c"], 100), j = rand(["d", "e", "f"], 100))
    plt = data(df) * mapping(:x => "xlabel", :y => "ylabel", col = :i, row = :j)
    fig = Figure()
    aes = compute_axes_grid(fig, plt)
    ax = first(aes).axis

    label = span_xlabel!(fig, aes)
    @test label.rotation[] == 0
    @test label.color[] == ax.xlabelcolor[]
    @test label.font[] == ax.xlabelfont[]
    @test label.fontsize[] == ax.xlabelsize[]
    @test label.text[] == "xlabel"
    @test label in contents(fig[3, :, Bottom()])

    label = span_ylabel!(fig, aes)
    @test label.rotation[] ≈ π / 2
    @test label.color[] == ax.ylabelcolor[]
    @test label.font[] == ax.ylabelfont[]
    @test label.fontsize[] == ax.ylabelsize[]
    @test label.text[] == "ylabel"
    @test label in contents(fig[:, 1, Left()])
end

@testset "linking" begin
    df = (x = rand(100), y = rand(100), i = rand(["a", "b", "c"], 100), j = rand(["d", "e", "f"], 100))
    plt = data(df) * mapping(:x => "xlabel", :y => "ylabel", col = :i, row = :j)
    fg = draw(plt; facet = (linkxaxes = :all, linkyaxes = :rowwise))
    aes = fg.grid
    axs = [ae.axis for ae in aes]
    for c in CartesianIndices(axs)
        i, j = Tuple(c)
        ax = axs[i, j]
        @test issetequal(ax.xaxislinks, setdiff(axs, [ax]))
        @test issetequal(ax.yaxislinks, setdiff(axs[i, :], [ax]))
    end

    fg = draw(plt; facet = (linkxaxes = :colwise, linkyaxes = :all))
    aes = fg.grid
    axs = [ae.axis for ae in aes]
    for c in CartesianIndices(axs)
        i, j = Tuple(c)
        ax = axs[i, j]
        @test issetequal(ax.xaxislinks, setdiff(axs[:, j], [ax]))
        @test issetequal(ax.yaxislinks, setdiff(axs, [ax]))
    end

    fg = draw(plt; facet = (linkxaxes = false, linkyaxes = false))
    aes = fg.grid
    axs = [ae.axis for ae in aes]
    for c in CartesianIndices(axs)
        i, j = Tuple(c)
        ax = axs[i, j]
        @test ax.xaxislinks == Axis[]
        @test ax.yaxislinks == Axis[]
    end

    df = (x = rand(100), y = rand(100), i = rand(["a", "b", "c", "d"], 100))
    plt = data(df) * mapping(:x, :y, layout = :i)
    fg = draw(plt; facet = (linkxaxes = :all, linkyaxes = :rowwise))
    aes = fg.grid
    axs = [ae.axis for ae in aes]
    for c in CartesianIndices(axs)
        i, j = Tuple(c)
        ax = axs[i, j]
        @test issetequal(ax.xaxislinks, setdiff(axs, [ax]))
        @test issetequal(ax.yaxislinks, setdiff(axs[i, :], [ax]))
    end

    df = (x = rand(100), y = rand(100), i = rand(["a", "b", "c", "d", "e"], 100))
    plt = data(df) * mapping(:x, :y, layout = :i)
    fg = draw(plt; facet = (linkxaxes = :all, linkyaxes = :rowwise))
    aes = fg.grid
    axs = [ae.axis for ae in aes]
    for c in CartesianIndices(axs)
        i, j = Tuple(c)
        ax = axs[i, j]
        @test issetequal(ax.xaxislinks, setdiff(axs, [ax]))
        @test issetequal(ax.yaxislinks, setdiff(axs[i, :], [ax]))
    end
    @test isempty(contents(fg.figure[2, 3]))
end

@testset "hidedecorations" begin
    x = rand(500)
    y = rand(500)
    i = rand(["a", "b", "c"], 500)
    j = rand(["d", "e", "f"], 500)
    idxs = @. !((i == "b") & (j == "e")) & !((i == "c") & (j == "f"))
    df = (x = x[idxs], y = y[idxs], i = i[idxs], j = j[idxs])
    plt = data(df) * mapping(:x => "xlabel", :y => "ylabel", col = :i, row = :j)
    axis = (
        xticksvisible = true,
        xminorticksvisible = true,
        xgridvisible = true,
        xminorgridvisible = true,
        yticksvisible = true,
        yminorticksvisible = true,
        ygridvisible = true,
        yminorgridvisible = true,
    )
    fg = draw(plt; axis)
    for i in 1:3, j in 1:3
        ax = content(fg.figure[i, j])
        hidex = i != 3
        hidey = j != 1
        @test ax.xticklabelsvisible[] == !hidex
        @test ax.xticksvisible[] == !hidex
        @test ax.xminorticksvisible[] == !hidex
        @test ax.xgridvisible[] == true
        @test ax.xminorgridvisible[] == true

        @test ax.yticklabelsvisible[] == !hidey
        @test ax.yticksvisible[] == !hidey
        @test ax.yminorticksvisible[] == !hidey
        @test ax.ygridvisible[] == true
        @test ax.yminorgridvisible[] == true
    end

    df = (x = rand(100), y = rand(100), i = rand(["a", "b", "c", "d", "e"], 100))
    plt = data(df) * mapping(:x, :y, layout = :i)
    fg = draw(plt; facet = (hideydecorations = false,), axis)
    aes = fg.grid
    axs = [ae.axis for ae in aes]
    for c in CartesianIndices(axs)
        ax = axs[c]
        i, j = Tuple(c)
        aboveempty = i == 1 && j == 3 # subplot above an empty subplot
        hidex = (i != 2) && !aboveempty
        hidey = false
        @test ax.xticklabelsvisible[] == !hidex
        @test ax.xticksvisible[] == !hidex
        @test ax.xminorticksvisible[] == !hidex
        @test ax.xgridvisible[] == true
        @test ax.xminorgridvisible[] == true

        @test ax.yticklabelsvisible[] == !hidey
        @test ax.yticksvisible[] == !hidey
        @test ax.yminorticksvisible[] == !hidey
        @test ax.ygridvisible[] == true
        @test ax.yminorgridvisible[] == true

        alignmode = aboveempty ? Mixed(bottom = Protrusion(0)) : Inside()
        @test ax.alignmode[] == alignmode
    end
    @test isempty(contents(fg.figure[2, 3]))
end


@testset "facet_size" begin
    df = (; x = repeat(1:5, 10), y = rand(50), g = repeat(string.(1:10), inner = 5))
    plt = data(df) * mapping(:x, :y, layout = :g) * visual(Lines)

    # FacetSize with no axis overrides: width/height derived from aspect + height function
    fs = AlgebraOfGraphics.FacetSize(2.0, (nr, nc) -> 100)
    fg = draw(plt; facet = (; size = fs))
    ax = first(fg.grid).axis
    @test ax.height[] == 100
    @test ax.width[] == 200  # 100 * aspect = 200
    # Wide aspect → fewer columns (5 rows × 2 cols for n=10, aspect 2)
    @test size(fg.grid) == (5, 2)

    # User overrides height only: width derived from aspect
    fg = draw(plt; facet = (; size = fs), axis = (; height = 80))
    ax = first(fg.grid).axis
    @test ax.height[] == 80
    @test ax.width[] == 160

    # User overrides width only: height derived from aspect
    fg = draw(plt; facet = (; size = fs), axis = (; width = 300))
    ax = first(fg.grid).axis
    @test ax.width[] == 300
    @test ax.height[] == 150  # 300 / aspect = 150

    # User overrides both: aspect/height callback ignored, layout uses user's aspect
    fg = draw(plt; facet = (; size = fs), axis = (; width = 100, height = 200))
    ax = first(fg.grid).axis
    @test ax.width[] == 100
    @test ax.height[] == 200
    # User aspect 0.5 (tall) → more columns (2 rows × 5 cols)
    @test size(fg.grid) == (2, 5)

    # The `height` function is given the resolved grid dimensions, so the same callback can yield
    # different sizes depending on grid size — useful for tier-based sizing.
    fs_dynamic = AlgebraOfGraphics.FacetSize(1.0, (nr, nc) -> max(nr, nc) <= 2 ? 200 : 80)

    df_small = (; x = repeat(1:5, 4), y = rand(20), g = repeat(["a", "b", "c", "d"], inner = 5))
    plt_small = data(df_small) * mapping(:x, :y, layout = :g) * visual(Lines)
    fg_small = draw(plt_small; facet = (; size = fs_dynamic))
    @test size(fg_small.grid) == (2, 2)
    @test first(fg_small.grid).axis.height[] == 200

    df_large = (; x = repeat(1:5, 9), y = rand(45), g = repeat(string.(1:9), inner = 5))
    plt_large = data(df_large) * mapping(:x, :y, layout = :g) * visual(Lines)
    fg_large = draw(plt_large; facet = (; size = fs_dynamic))
    @test maximum(size(fg_large.grid)) >= 3
    @test first(fg_large.grid).axis.height[] == 80

    # Pagination: all pages (including the trailing one with fewer facets) get the same axis
    # size because the `height` callback is given the max grid across all pages.
    df_pag = (; x = repeat(1:5, 9), y = rand(45), g = repeat(string.(1:9), inner = 5))
    plt_pag = data(df_pag) * mapping(:x, :y, layout = :g) * visual(Lines)
    # Policy crosses tier at 1×1 vs larger: would give trailing 1×1 page a different size
    # if AoG sized per-page instead of using the max grid.
    crossing_policy = AlgebraOfGraphics.FacetSize(1.0, (nr, nc) -> max(nr, nc) == 1 ? 200 : 80)
    pag = paginate(plt_pag, layout = 4)
    pages = draw(pag; facet = (; size = crossing_policy))
    @test length(pages) == 3
    @test size(pages[1].grid) == (2, 2)
    @test size(pages[3].grid) == (1, 1)  # trailing page
    # All pages get the size for the max grid (2×2 → 80), not their own grid
    for fg in pages
        @test first(fg.grid).axis.height[] == 80
    end
    # Single-page draws use the same max-grid policy
    @test first(draw(pag, 3; facet = (; size = crossing_policy)).grid).axis.height[] == 80
end
