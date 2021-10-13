function guides_position(fig::Figure, position)
    position = Symbol(position)
    supported = [:top, :bottom, :left, :right]
    position ∉ supported && throw(ArgumentError("Legend position $position ∉ $supported"))
    
    if position == :bottom
        legs_pos = fig[end+1,:]
    elseif position == :top
        legs_pos = fig[0,:]
    elseif position == :right
        legs_pos = fig[:,end+1]
    elseif position == :left
        legs_pos = fig[:,0]
    end

    legs_pos
end

default_orientation(position) = position in [:top, :bottom] ? :horizontal : :vertical