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
