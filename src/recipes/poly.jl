# A poly recipe that takes data in long format, used for the filled_contours analysis

@recipe(LongPoly) do scene
    default_theme(scene, Poly)
end

Makie.convert_arguments(::Type{<:LongPoly}, args...) = args

function Makie.plot!(p::LongPoly{<:Tuple{<:AbstractVector{<:AbstractFloat},<:AbstractVector{<:AbstractFloat},<:AbstractVector{<:Integer},<:AbstractVector{<:Integer}}})
    x, y, id, subid = p[1:4]

    P = Makie.Point2{Float64}
    POLY = typeof(Makie.GeometryBasics.Polygon(P[]))

    polygons = Observable{Vector{POLY}}([])

    color = Observable{Any}(:red)

    onany(x, y, id, subid; update = true) do x, y, id, subid
        polys = POLY[]

        if isempty(id)
            return polys
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
                push!(rings, ring_start:i-1)
                push!(all_rings, rings)
                prev_subid = nothing
                ring_start = i
                rings = UnitRange{Int}[]
            else
                if prev_subid !== nothing && _subid != prev_subid
                    push!(rings, ring_start:i-1)
                    ring_start = i
                end
            end
            prev_id = _id
            prev_subid = _subid
        end
        push!(rings, ring_start:length(x))
        push!(all_rings, rings)

        color.val = slice_rings(p.color[], all_rings)

        polygons[] = map(all_rings) do rings
            exterior::Vector{P} = @views P.(x[rings[1]], y[rings[1]])
            interiors::Vector{Vector{P}} = @views [P.(x[ring], y[ring]) for ring in rings[2:end]]
            pol = Makie.GeometryBasics.Polygon(exterior, interiors)
            return pol
        end
    end

    poly!(p, polygons; color)
end

function slice_rings(x::AbstractVector, all_rings::Vector{Vector{UnitRange{Int}}})
    map(all_rings) do ring
        start = ring[1].start
        stop = ring[end].stop
        values = @view x[start:stop]
        if !allequal(values)
            error("Encountered more than one value for long-format polygon at ring $ring: $(unique(values))")
        end
        first(values)
    end
end

slice_rings(x, all_rings) = x