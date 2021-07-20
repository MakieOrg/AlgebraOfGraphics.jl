from_default_theme(attr) = Makie.current_default_theme()[attr]

function legend_elements(::Type{Scatter};
                         marker=from_default_theme(:marker),
                         markerpoints=[Point2f(0.5, 0.5)],
                         color=from_default_theme(:markercolor),
                         kwargs...)
    return [MarkerElement(; marker, markerpoints, markercolor=color, kwargs...)]
end

function legend_elements(::Type{Lines};
                         color=from_default_theme(:linecolor), kwargs...)
    return [LineElement(; linecolor=color, kwargs...)]
end

function legend_elements(::Type{Contour};
                         color=from_default_theme(:linecolor), kwargs...)
    return [LineElement(; linecolor=color, kwargs...)]
end

function legend_elements(::Type{LinesFill};
                         color=from_default_theme(:linecolor), fillalpha=0.15, kwargs...)
	polycolor = to_color((color, fillalpha))
	return [PolyElement(; polycolor, kwargs...), LineElement(; linecolor=color, kwargs...)]
end

function legend_elements(::Any;
                         color=from_default_theme(:patchcolor), kwargs...)
    return [PolyElement(; polycolor=color, kwargs...)]
end
