function compute_dodge(x, i, n; width, space = 0.2)
    unique_x = unique(sort(x))
    width === automatic && (width = minimum(diff(unique_x))*(1-space))
    w = width/n
    x′ = x .+ i*w .- w*(n+1)/2
    return x′, w
end