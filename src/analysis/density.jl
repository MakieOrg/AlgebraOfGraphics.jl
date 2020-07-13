function _density(data; xlims = (-Inf, Inf), trim = false, kwargs...)
    k = kde(data; kwargs...)
    x, y = k.x, k.density
    xmin, xmax = xlims
    xmin = max(xmin, minimum(data))
    xmax = min(xmax, maximum(data))
    if trim
        for i in eachindex(x, y)
            xmin ≤ x[i] ≤ xmax || (y[i] = NaN)
        end
    end
    return spec(:Lines) * style(x, y)
end

function _density(datax, datay; xlims = (-Inf, Inf), ylims = (-Inf, Inf), trim = false, kwargs...)
    k = kde((datax, datay); kwargs...)
    x, y, z = k.x, k.y, k.density
    xmin, xmax = xlims
    xmin = max(xmin, minimum(datax))
    xmax = min(xmax, maximum(datax))
    ymin, ymax = ylims
    ymin = max(ymin, minimum(datay))
    ymax = min(ymax, maximum(datay))
    if trim
        for i in eachindex(x, y)
            xmin ≤ x[i] ≤ xmax && ymin ≤ y[i] ≤ ymax || (z[i] = NaN)
        end
    end
    return spec(:Heatmap) * style(x, y, z)
end

const density = Analysis(_density)
