# Conservative 7-color palette
# Wong, Bang. "Points of view: Color blindness." (2011): 441.
# https://www.nature.com/articles/nmeth.1618?WT.ec_id=NMETH-201106

function default_palettes()
    return (
        color=[
            RGB(0/255, 114/255, 178/255), # blue
            RGB(230/255, 159/255, 0/255), # orange
            RGB(0/255, 158/255, 115/255), # green
            RGB(204/255, 121/255, 167/255), # reddish purple
            RGB(86/255, 180/255, 233/255), # sky blue
            RGB(213/255, 94/255, 0/255), # vermillion
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
# https://www.nature.com/articles/s41467-020-19160-7

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

firasans(weight) = joinpath(font_folder, "FiraSans-$(weight).ttf")
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
        xticklabelfont=firasans("Light"),
        yticklabelfont=firasans("Light"),
        xlabelfont=firasans("Medium"),
        ylabelfont=firasans("Medium"),
        titlefont=firasans("Medium"),
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
        xticklabelfont=firasans("Light"),
        yticklabelfont=firasans("Light"),
        zticklabelfont=firasans("Light"),
        xlabelfont=firasans("Medium"),
        ylabelfont=firasans("Medium"),
        zlabelfont=firasans("Medium"),
        titlefont=firasans("Medium"),
    )
    Legend = (
        framevisible=false,
        gridshalign=:left,
        padding=(0f0, 0f0, 0f0, 0f0),
        labelfont=firasans("Light"),
        titlefont=firasans("Medium"),
    )
    Colorbar = (
        colormap=:batlow,
        flip_vertical_label=true,
        spinewidth=0,
        ticklabelfont=firasans("Light"),
        labelfont=firasans("Medium"),
    )
    return (; Axis, Axis3, Legend, Colorbar)
end

function set_aog_theme!()
    theme = aog_theme()
    return set_theme!(; theme...)
end
