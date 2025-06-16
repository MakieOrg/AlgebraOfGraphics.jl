# Example GUI to look at a dataset (outdated)

using AbstractPlotting
using AbstractPlotting.MakieLayout
using GLMakie
using GridLayoutBase
using Observables

using AlgebraOfGraphics
using AlgebraOfGraphics: linear, smooth, density, AlgebraicList, layoutplot!

function clean!(g::GridLayout)
    foreach(delete!, Any, g)
    return foreach(GridLayoutBase.remove_from_gridlayout!, g.content)
end

function gui!(scene, layout, df)
    table = data(df)

    plot_options = [("none", nothing), ("scatter", Scatter), ("lines", Lines), ("barplot", BarPlot)]
    plot_menu = LMenu(scene, options = plot_options, textsize = 30, width = 500)

    layout[1, 1] = Label(scene, "plot type", fontsize = 30)
    layout[1, 2] = plot_menu

    analysis_options = [
        ("none", nothing), ("linear", linear), ("smooth", smooth),
        ("density", density),
    ]

    analysis_menu = LMenu(scene, options = analysis_options, textsize = 30, width = 500)

    layout[2, 1] = Label(scene, "analysis", fontsize = 30)
    layout[2, 2] = analysis_menu

    axis_options = vcat([("None", nothing)], [(s, Symbol(s)) for s in propertynames(table.data)])

    mappings = ["x", "y", "color", "marker", "markersize", "linestyle", "layout_x", "layout_y"]
    mapping_menus = [LMenu(scene, options = axis_options, textsize = 30, width = 500) for mapping in mappings]
    N = length(mappings)

    for i in 1:N
        layout[2 + i, 1] = Label(scene, mappings[i], fontsize = 30)
        layout[2 + i, 2] = mapping_menus[i]
    end

    plot_button = Button(scene, label = "Plot", textsize = 30)
    add_and_plot_button = Button(scene, label = "Add and Plot", buttoncolor = "powderblue", textsize = 30)

    layout[1, 3] = plot_button
    layout[1, 4] = add_and_plot_button

    axs = layout[1:(2 + N), 5] = GridLayout(1, 2) # for plot and legend
    colsize!(axs, 2, Relative(1 / 5)) # make legend a fourth of the plot's width

    state = AlgebraicList()

    function add_and_plot()
        acc = table
        T = plot_menu.selection[]
        isnothing(T) || (acc *= visual(T))
        an = analysis_menu.selection[]
        isnothing(an) || (acc *= an)
        for (st, st_menu) in zip(mappings, mapping_menus)
            sym = st === "x" ? Symbol("1") : st === "y" ? Symbol("2") : Symbol(st)
            val = st_menu.selection[]
            isnothing(val) || (acc *= mapping(; sym => val))
        end
        clean!(axs)
        state += acc
        return layoutplot!(scene, axs, state)
    end

    on(plot_button.clicks) do _
        state = AlgebraicList()
        add_and_plot()
    end
    on(_ -> add_and_plot(), add_and_plot_button.clicks)

    return scene
end

function gui(df; kwargs...)
    scene, layout = MakieLayout.layoutscene(; kwargs...)
    return gui!(scene, layout, df)
end

# Try it on iris dataset

using RDatasets: dataset

iris = dataset("datasets", "iris")

display(gui(iris))
