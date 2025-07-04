"""
    linesfill(xs, ys; lower, upper, attributes...)

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
        lower = automatic,
        upper = automatic,
        direction = :x,
    )
end

function Makie.plot!(p::LinesFill)
    lineargs = lift(p[1], p[2], p.direction) do x, y, direction
        direction in (:x, :y) || error("Invalid direction $(repr(direction)), only :x and :y are allowed.")
        direction === :x ? Makie.Point.(x, y) : Makie.Point.(y, x)
    end
    lines!(
        p, lineargs;
        color = p.color,
        linestyle = p.linestyle,
        linewidth = p.linewidth,
        colormap = p.colormap,
        colorrange = p.colorrange,
    )
    lower = lift(p[:lower], p[2]) do lower, y
        return lower === automatic ? zero(y) : lower
    end
    upper = lift(p[:upper], p[2]) do upper, y
        return upper === automatic ? y : upper
    end
    meshcolor = lift(to_color ∘ tuple, p.color, p.fillalpha)
    return band!(p, p[1], lower, upper; color = meshcolor, p.direction)
end
