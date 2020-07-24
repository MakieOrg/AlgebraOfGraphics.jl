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

"""
    density(data...; trim = false, boundary, npoints, kernel, bandwidth)

Fit a kernel density estimation of `data`. Only 1D and 2D are supported so far.
The optional keyword arguments are
* `boundary`: the lower and upper limits of the kde as a tuple. Due to the
  fourier transforms used internally, there should be sufficient spacing to
  prevent wrap-around at the boundaries.
* `npoints`: the number of interpolation points to use. The function uses
  fast Fourier transforms (FFTs) internally, so for optimal efficiency this
  should be a power of 2 (default = 2048).
* `kernel`: the distributional family from
  [Distributions.jl](https://github.com/JuliaStats/Distributions.jl) to use as
  the kernel (default = `Normal`). To add your own kernel, extend the internal
  `kernel_dist` function.
* `bandwidth`: the bandwidth of the kernel. Default is to use Silverman's rule.
"""
const density = Analysis(_density)
