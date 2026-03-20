# A poly recipe that takes data in long format, used for the filled_contours analysis

@recipe LongPoly (x, y, id, subid) begin
    color = @inherit patchcolor
    strokecolor = @inherit patchstrokecolor
    strokewidth = @inherit patchstrokewidth
end

Makie.convert_arguments(::Type{<:LongPoly}, args...) = args

function Makie.plot!(p::LongPoly)
    P = Makie.Point2{Float64}
    POLY = typeof(Makie.GeometryBasics.Polygon(P[]))

    map!(p, [:x, :y, :id, :subid, :color], [:polygons, :computed_color]) do x, y, id, subid, color
        if isempty(id)
            return (POLY[], color)
        end

        prev_id = id[begin]
        prev_subid = nothing

        ring_start = 1
        all_rings = Vector{UnitRange{Int}}[]
        rings = UnitRange{Int}[]
        for i in eachindex(x, y, id, subid)
            _id = id[i]
            _subid = subid[i]
            if _id !== prev_id
                push!(rings, ring_start:(i - 1))
                push!(all_rings, rings)
                prev_subid = nothing
                ring_start = i
                rings = UnitRange{Int}[]
            else
                if prev_subid !== nothing && _subid != prev_subid
                    push!(rings, ring_start:(i - 1))
                    ring_start = i
                end
            end
            prev_id = _id
            prev_subid = _subid
        end
        push!(rings, ring_start:length(x))
        push!(all_rings, rings)

        computed_color = slice_rings(color, all_rings)

        polygons = map(all_rings) do rings
            exterior::Vector{P} = @views P.(x[rings[1]], y[rings[1]])
            interiors::Vector{Vector{P}} = @views [P.(x[ring], y[ring]) for ring in rings[2:end]]
            return Makie.GeometryBasics.Polygon(exterior, interiors)
        end

        return (polygons, computed_color)
    end

    return poly!(
        p, p.polygons;
        color = p.computed_color,
        strokecolor = p.strokecolor,
        strokewidth = p.strokewidth,
    )
end

function slice_rings(x::AbstractVector, all_rings::Vector{Vector{UnitRange{Int}}})
    return map(all_rings) do ring
        start = ring[1].start
        stop = ring[end].stop
        values = @view x[start:stop]
        firstval = first(values)
        if !all(x -> isequal(x, firstval), @view(values[(begin + 1):end]))
            error("Encountered more than one value for long-format polygon at ring $ring: $(unique(values))")
        end
        firstval
    end
end

slice_rings(x, all_rings) = x
