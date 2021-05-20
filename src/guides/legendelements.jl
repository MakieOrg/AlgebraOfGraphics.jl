function from_default_theme(attr)
    theme = default_styles()
    return get(theme, attr) do
        Makie.current_default_theme()[attr]
    end
end

line_element(;
             color=from_default_theme(:color),
             linestyle=from_default_theme(:linestyle),
             linewidth=from_default_theme(:linewidth),
             kwargs...) = 
    LineElement(; color, linestyle, linewidth, kwargs...)

marker_element(;
               color=from_default_theme(:color),
               marker=from_default_theme(:marker),
               strokecolor=from_default_theme(:strokecolor),
               markerpoints=[Point2f0(0.5, 0.5)],
               kwargs...) =
    MarkerElement( ; color, marker, strokecolor, markerpoints, kwargs...)

poly_element(;
             color=from_default_theme(:color),
             strokecolor=:transparent,
             kwargs...) = 
    PolyElement(; color, strokecolor, kwargs...)

legend_elements(::Type{Scatter}; kwargs...) = [marker_element(; kwargs...)]
legend_elements(::Type{Lines}; kwargs...) = [line_element(; kwargs...)]
legend_elements(::Type{Contour}; kwargs...) = [line_element(; kwargs...)]

function legend_elements(::Type{LinesFill}; color=from_default_theme(:color), fillalpha=0.15, kwargs...)
	meshcolor = to_color((color, fillalpha))
	return [poly_element(; color=meshcolor, kwargs...), line_element(; color, kwargs...)]
end

legend_elements(::Any; linewidth=0, strokecolor=:transparent, kwargs...) =
	[poly_element(; linewidth, kwargs...)]
