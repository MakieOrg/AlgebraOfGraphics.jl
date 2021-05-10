# Conservative 7-color palette
# Wong, Bang. "Points of view: Color blindness." (2011): 441.
# https://www.nature.com/articles/nmeth.1618?WT.ec_id=NMETH-201106

function default_palettes()
    return arguments(
        color=[
            RGB(0/255, 114/255, 178/255), # dark blue
            RGB(230/255, 159/255, 0/255), # orange
            RGB(0/255, 158/255, 115/255), # green
            RGB(204/255, 121/255, 167/255), # pink
            RGB(213/255, 94/255, 0/255), # red
            RGB(86/255, 180/255, 233/255), # light blue
            RGB(240/255, 228/255, 66/255), # yellow
        ],
        marker=[:circle, :utriangle, :cross, :rect, :diamond, :dtriangle, :pentagon, :xcross],
        linestyle=[:solid, :dash, :dot, :dashdot, :dashdotdot],
        side=[:left, :right],
        layout=wrap,
    )
end

# Batlow colormap
# Crameri, Fabio, Grace E. Shephard, and Philip J. Heron. "The misuse of colour in science communication." Nature communications 11.1 (2020): 1-10.
# https://www.nature.com/articles/s41467-020-19160-7?source=techstories.org

function default_styles()
    return (
        color=:gray25,
        strokecolor=RGBA(0, 0, 0, 0),
        outlierstrokecolor=RGBA(0, 0, 0, 0),
        mediancolor=:white,
        marker=:circle,
        markersize=9,
        linewidth=1.5,
        medianlinewidth=1.5,
        colormap=:batlow,
    )
end

# axis defaults

const font_folder = joinpath(dirname(@__DIR__), "assets", "fonts")

opensans(weight) = joinpath(font_folder, "OpenSans-$(weight).ttf")

function aog_theme()
    Axis = (
        xgridvisible=false,
        ygridvisible=false,
        topspinevisible=false,
        rightspinevisible=false,
        bottomspinecolor=:darkgray,
        leftspinecolor=:darkgray,
        xtickcolor=:darkgray,
        ytickcolor=:darkgray,
        xticklabelfont=opensans("Light"),
        yticklabelfont=opensans("Light"),
        xlabelfont=opensans("SemiBold"),
        ylabelfont=opensans("SemiBold"),
        titlefont=opensans("SemiBold"),
    )
    Axis3 = (
        protrusions=55, # to include label on z axis, should be fixed in AbstractPlotting
        xgridvisible=false,
        ygridvisible=false,
        zgridvisible=false,
        xspinecolor=:darkgray,
        yspinecolor=:darkgray,
        zspinecolor=:darkgray,
        xtickcolor=:darkgray,
        ytickcolor=:darkgray,
        ztickcolor=:darkgray,
        xticklabelfont=opensans("Light"),
        yticklabelfont=opensans("Light"),
        zticklabelfont=opensans("Light"),
        xlabelfont=opensans("SemiBold"),
        ylabelfont=opensans("SemiBold"),
        zlabelfont=opensans("SemiBold"),
        titlefont=opensans("SemiBold"),
    )
    Legend= (
        framevisible=false,
        gridshalign=:left,
        padding=(0f0, 0f0, 0f0, 0f0),
        labelfont=opensans("Light"),
        titlefont=opensans("SemiBold"),
    )
    return (; Axis, Axis3, Legend)
end

function set_aog_theme!()
    theme = aog_theme()
    return set_theme!(; theme...)
end
