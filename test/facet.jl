@testset "clean facet attributes" begin
    # consistent `x` and `y` labels
    df = (x=rand(100), y=rand(100), i=rand(["a", "b", "c"], 100), j=rand(["d", "e", "f"], 100))
    plt = data(df) * mapping(:x, :y, col=:i, row=:j)
    aes = compute_axes_grid(Figure(), plt)
    @test consistent_xlabels(aes)
    @test consistent_ylabels(aes)
    @test colwise_consistent_xlabels(aes)
    @test rowwise_consistent_ylabels(aes)
    @test clean_facet_attributes(aes, hidexdecorations=automatic) ==
        (linkxaxes=:all, linkyaxes=:all, hidexdecorations=true, hideydecorations=true)
    @test clean_facet_attributes(aes, hidexdecorations=automatic, linkxaxes=false) ==
        (linkxaxes=:none, linkyaxes=:all, hidexdecorations=false, hideydecorations=true)
    @test clean_facet_attributes(aes, hideydecorations=false, linkyaxes=:minimal) ==
        (linkxaxes=:all, linkyaxes=:rowwise, hidexdecorations=true, hideydecorations=false)

    @test @test_logs(
        (:warn, "Replaced invalid keyword linkxaxes = :rowwise by automatic. " *
            "Valid values are :all, :colwise, :minimal, :none, true, false, or automatic."),
        clean_facet_attributes(aes, hidexdecorations=automatic, linkxaxes=:rowwise)
    ) == (linkxaxes=:all, linkyaxes=:all, hidexdecorations=true, hideydecorations=true)
    @test @test_logs(
        (:warn, "Replaced invalid keyword hidexdecorations = nothing by automatic. " *
            "Valid values are true, false, or automatic."),
        clean_facet_attributes(aes, hidexdecorations=nothing, linkxaxes=:colwise)
    ) == (linkxaxes = :colwise, linkyaxes = :all, hidexdecorations = true, hideydecorations = true)

    # consistent `x` and directionally consistent `y` labels
    df = (x=rand(100), y1=rand(100), y2=rand(100), i=rand(["a", "b", "c"], 100))
    plt = data(df) * mapping(:x, [:y1, :y2], col=:i, row=dims(1))
    aes = compute_axes_grid(Figure(), plt)
    @test consistent_xlabels(aes)
    @test !consistent_ylabels(aes)
    @test colwise_consistent_xlabels(aes)
    @test rowwise_consistent_ylabels(aes)
    @test clean_facet_attributes(aes, hidexdecorations=automatic) ==
        (linkxaxes=:all, linkyaxes=:rowwise, hidexdecorations=true, hideydecorations=true)
    @test clean_facet_attributes(aes, hidexdecorations=automatic, linkxaxes=false) ==
        (linkxaxes=:none, linkyaxes=:rowwise, hidexdecorations=false, hideydecorations=true)
    @test clean_facet_attributes(aes, hideydecorations=false, linkxaxes=:minimal) ==
        (linkxaxes=:colwise, linkyaxes=:rowwise, hidexdecorations=true, hideydecorations=false)

    # facet wrap
    df = (x=rand(100), y=rand(100), i=rand(["a", "b", "c", "d"], 100))
    plt = data(df) * mapping(:x, :y, layout=:i)
    aes = compute_axes_grid(Figure(), plt)
    @test consistent_xlabels(aes)
    @test consistent_ylabels(aes)
    @test colwise_consistent_xlabels(aes)
    @test rowwise_consistent_ylabels(aes)
    @test clean_facet_attributes(aes, hidexdecorations=automatic) ==
        (linkxaxes=:all, linkyaxes=:all, hidexdecorations=true, hideydecorations=true)
    @test clean_facet_attributes(aes, hidexdecorations=automatic, linkxaxes=false) ==
        (linkxaxes=:none, linkyaxes=:all, hidexdecorations=false, hideydecorations=true)
    @test clean_facet_attributes(aes, hideydecorations=false, linkyaxes=:minimal) ==
        (linkxaxes=:all, linkyaxes=:rowwise, hidexdecorations=true, hideydecorations=false)
end

@testset "facet labels" begin
    df = (x=rand(100), y=rand(100), i=rand(["a", "b", "c"], 100), j=rand(["d", "e", "f"], 100))
    plt = data(df) * mapping(:x, :y, col=:i, row=:j)
    fig = Figure()
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
    fig = Figure()
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

@testset "spanned labels" begin
    df = (x=rand(100), y=rand(100), i=rand(["a", "b", "c"], 100), j=rand(["d", "e", "f"], 100))
    plt = data(df) * mapping(:x => "xlabel", :y => "ylabel", col=:i, row=:j)
    fig = Figure()
    aes = compute_axes_grid(fig, plt)
    ax = first(aes).axis

    label = span_xlabel!(fig, aes)
    @test label.rotation[] == 0.0
    @test label.color == ax.xlabelcolor
    @test label.font == ax.xlabelfont
    @test label.textsize == ax.xlabelsize
    @test label.text[] == "xlabel"
    @test label in contents(fig[3, :, Bottom()])

    label = span_ylabel!(fig, aes)
    @test label.rotation[] == π/2
    @test label.color == ax.ylabelcolor
    @test label.font == ax.ylabelfont
    @test label.textsize == ax.ylabelsize
    @test label.text[] == "ylabel"
    @test label in contents(fig[:, 1, Left()])
end

@testset "linking" begin
    df = (x=rand(100), y=rand(100), i=rand(["a", "b", "c"], 100), j=rand(["d", "e", "f"], 100))
    plt = data(df) * mapping(:x => "xlabel", :y => "ylabel", col=:i, row=:j)
    fg = draw(plt; facet=(linkxaxes=:all, linkyaxes=:rowwise))
    aes = fg.grid
    axs = [ae.axis for ae in aes]
    for c in CartesianIndices(axs)
        i, j = Tuple(c)
        ax = axs[i, j]
        @test ax.xaxislinks == setdiff(axs, [ax])
        @test ax.yaxislinks == setdiff(axs[i, :], [ax])
    end

    fg = draw(plt; facet=(linkxaxes=:colwise, linkyaxes=:all))
    aes = fg.grid
    axs = [ae.axis for ae in aes]
    for c in CartesianIndices(axs)
        i, j = Tuple(c)
        ax = axs[i, j]
        @test ax.xaxislinks == setdiff(axs[:, j], [ax])
        @test ax.yaxislinks == setdiff(axs, [ax])
    end

    fg = draw(plt; facet=(linkxaxes=false, linkyaxes=false))
    aes = fg.grid
    axs = [ae.axis for ae in aes]
    for c in CartesianIndices(axs)
        i, j = Tuple(c)
        ax = axs[i, j]
        @test ax.xaxislinks == Axis[]
        @test ax.yaxislinks == Axis[]
    end

    df = (x=rand(100), y=rand(100), i=rand(["a", "b", "c", "d"], 100))
    plt = data(df) * mapping(:x, :y, layout=:i)
    fg = draw(plt; facet=(linkxaxes=:all, linkyaxes=:rowwise))
    aes = fg.grid
    axs = [ae.axis for ae in aes]
    for c in CartesianIndices(axs)
        i, j = Tuple(c)
        ax = axs[i, j]
        @test ax.xaxislinks == setdiff(axs, [ax])
        @test ax.yaxislinks == setdiff(axs[i, :], [ax])
    end

    df = (x=rand(100), y=rand(100), i=rand(["a", "b", "c", "d", "e"], 100))
    plt = data(df) * mapping(:x, :y, layout=:i)
    fg = draw(plt; facet=(linkxaxes=:all, linkyaxes=:rowwise))
    aes = fg.grid
    axs = [ae.axis for ae in aes]
    for c in CartesianIndices(axs)
        i, j = Tuple(c)
        ax = axs[i, j]
        @test ax.xaxislinks == setdiff(axs, [ax])
        @test ax.yaxislinks == setdiff(axs[i, :], [ax])
    end
    @test isempty(contents(fg.figure[2, 3]))
end

@testset "hidedecorations" begin
    x = rand(500)
    y = rand(500)
    i = rand(["a", "b", "c"], 500)
    j = rand(["d", "e", "f"], 500)
    idxs = @. !((i == "b") & (j == "e")) & !((i == "c") & (j == "f"))
    df = (x=x[idxs], y=y[idxs], i=i[idxs], j=j[idxs])
    plt = data(df) * mapping(:x => "xlabel", :y => "ylabel", col=:i, row=:j)
    axis = (
        xticksvisible=true,
        xminorticksvisible=true,
        xgridvisible=true,
        xminorgridvisible=true,
        yticksvisible=true,
        yminorticksvisible=true,
        ygridvisible=true,
        yminorgridvisible=true,
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

    df = (x=rand(100), y=rand(100), i=rand(["a", "b", "c", "d", "e"], 100))
    plt = data(df) * mapping(:x, :y, layout=:i)
    fg = draw(plt; facet=(hideydecorations=false,), axis)
    aes = fg.grid
    axs = [ae.axis for ae in aes]
    for c in CartesianIndices(axs)
        ax = axs[c]
        i, j = Tuple(c)
        hidex = (i != 2) && !(i ==1 && j == 3) # above empty plot
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
    end
    @test isempty(contents(fg.figure[2, 3]))
end
