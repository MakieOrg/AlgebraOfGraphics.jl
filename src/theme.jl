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

const font_folder = RelocatableFolders.@path joinpath(dirname(@__DIR__), "assets", "fonts")

firasans(weight) = joinpath(font_folder, "FiraSans-$(weight).ttf")
opensans(weight) = joinpath(font_folder, "OpenSans-$(weight).ttf")

# Batlow colormap
# Crameri, Fabio, Grace E. Shephard, and Philip J. Heron. "The misuse of colour in science communication." Nature communications 11.1 (2020): 1-10.
# https://www.nature.com/articles/s41467-020-19160-7

"""
    aog_theme(; fonts=[firasans("Medium"), firasans("Light")])

Return a `NamedTuple` of theme settings. Intended for internal use.
The provided functionality is exposed to the user by the function [`set_aog_theme!`](@ref).
"""
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
        xspinecolor_1=:darkgray,
        yspinecolor_1=:darkgray,
        zspinecolor_1=:darkgray,
        xspinecolor_2=:transparent,
        yspinecolor_2=:transparent,
        zspinecolor_2=:transparent,
        xspinecolor_3=:transparent,
        yspinecolor_3=:transparent,
        zspinecolor_3=:transparent,
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

"""
    set_aog_theme!(; kwargs...)

Set the current theme to a predefined and opinionated theme,
as defined by the unexported internal function [`AlgebraOfGraphics.aog_theme`](@ref).

To tweak the predefined theme, use the function `Makie.update_theme!`.
See the example below on how to change, e.g., default fontsize, title, and markersize.

For more information about setting themes, see the `Theming`
section of the `Makie.jl` docs.

# Examples
```jldoctest
julia> using GLMakie

julia> using AlgebraOfGraphics

julia> set_aog_theme!()                # Sets a prefedined theme

julia> update_theme!(                  # Tweaks the current theme
           fontsize=30,                
           markersize=40,
           Axis=(title="MyDefaultTitle",)
       )
```
"""
function set_aog_theme!(; kwargs...)
    theme = aog_theme(; kwargs...)
    return set_theme!(; theme...)
end
