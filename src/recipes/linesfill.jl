"""
    linesfill(xs, ys, lower, upper; kwargs...)

Line plot with a shaded area between `lower` and `upper`. If `lower` and `upper`
are not given, shaded area is between `0` and `ys`.
## Attributes
$(ATTRIBUTES)
"""
@recipe(LinesFill) do scene
    l_theme = default_theme(scene, Lines)
    Attributes(
        color = l_theme.color,
        colormap = l_theme.colormap,
        colorrange = get(l_theme.attributes, :colorrange, automatic),
        linestyle = l_theme.linestyle,
        linewidth = l_theme.linewidth,
        fillalpha = 0.15,
    )
end

function AbstractPlotting.plot!(p::LinesFill)
    lines!(p, p[1:2]...;
        color = p.color,
        linestyle = p.linestyle,
        linewidth = p.linewidth,
        colormap = p.colormap,
        colorrange = p.colorrange,
    )
    if length(p) == 2
        lower, upper = lift(zero, p[2]), p[2]
    else
        lower, upper = p[3], p[4]
    end
    meshcolor = lift(to_color∘tuple, p.color, p.fillalpha)
    band!(p, p[1], lower, upper; color = meshcolor)
end
