# Conservative 7-color palette
# Wong, Bang. "Points of view: Color blindness." (2011): 441.
# https://www.nature.com/articles/nmeth.1618?WT.ec_id=NMETH-201106

function wongcolors()
    return [
        RGB(0/255, 114/255, 178/255), # blue
        RGB(230/255, 159/255, 0/255), # orange
        RGB(0/255, 158/255, 115/255), # green
        RGB(204/255, 121/255, 167/255), # reddish purple
        RGB(86/255, 180/255, 233/255), # sky blue
        RGB(213/255, 94/255, 0/255), # vermillion
        RGB(240/255, 228/255, 66/255), # yellow
    ]
end

const font_folder = joinpath(dirname(@__DIR__), "assets", "fonts")

firasans(weight) = joinpath(font_folder, "FiraSans-$(weight).ttf")
opensans(weight) = joinpath(font_folder, "OpenSans-$(weight).ttf")

# Batlow colormap
# Crameri, Fabio, Grace E. Shephard, and Philip J. Heron. "The misuse of colour in science communication." Nature communications 11.1 (2020): 1-10.
# https://www.nature.com/articles/s41467-020-19160-7

function aog_theme(; fonts=[firasans("Medium"), firasans("Light")])
    mediumfont = first(fonts)
    lightfont = last(fonts)

    marker = :circle

    colormap = :batlow
    linecolor = :gray25
    markercolor = :gray25
    patchcolor = :gray25

    palette = (
        color=wongcolors(),
        patchcolor=wongcolors(),
        marker=[:circle, :utriangle, :cross, :rect, :diamond, :dtriangle, :pentagon, :xcross],
        linestyle=[:solid, :dash, :dot, :dashdot, :dashdotdot],
        side=[:left, :right],
    )

    # setting marker here is a temporary hack
    # it should either respect `marker = :circle` globally
    # or `:circle` and `Circle` should have the same size
    BoxPlot = (mediancolor=:white, marker=:circle)
    Scatter = (marker=:circle,)
    Violin = (mediancolor=:white,)

    Axis = (
        xgridvisible=false,
        ygridvisible=false,
        topspinevisible=false,
        rightspinevisible=false,
        bottomspinecolor=:darkgray,
        leftspinecolor=:darkgray,
        xtickcolor=:darkgray,
        ytickcolor=:darkgray,
        xticklabelfont=lightfont,
        yticklabelfont=lightfont,
        xlabelfont=mediumfont,
        ylabelfont=mediumfont,
        titlefont=mediumfont,
    )
    Axis3 = (
        protrusions=55, # to include label on z axis, should be fixed in Makie
        xgridvisible=false,
        ygridvisible=false,
        zgridvisible=false,
        xspinecolor=:darkgray,
        yspinecolor=:darkgray,
        zspinecolor=:darkgray,
        xtickcolor=:darkgray,
        ytickcolor=:darkgray,
        ztickcolor=:darkgray,
        xticklabelfont=lightfont,
        yticklabelfont=lightfont,
        zticklabelfont=lightfont,
        xlabelfont=mediumfont,
        ylabelfont=mediumfont,
        zlabelfont=mediumfont,
        titlefont=mediumfont,
    )
    Legend = (
        framevisible=false,
        gridshalign=:left,
        padding=(0f0, 0f0, 0f0, 0f0),
        labelfont=lightfont,
        titlefont=mediumfont,
    )
    Colorbar = (
        flip_vertical_label=true,
        spinewidth=0,
        ticklabelfont=lightfont,
        labelfont=mediumfont,
    )

    return (;
        marker,
        colormap,
        linecolor,
        markercolor,
        patchcolor,
        palette,
        BoxPlot,
        Scatter,
        Violin,
        Axis,
        Axis3,
        Legend,
        Colorbar,
    )
end

function set_aog_theme!(; kwargs...)
    theme = aog_theme(; kwargs...)
    return set_theme!(; theme...)
end
