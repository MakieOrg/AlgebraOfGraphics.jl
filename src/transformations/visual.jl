struct Visual
    plottype::PlotType
    attributes::NamedArguments
end
Visual(plottype::PlotType=Plot{plot}; kwargs...) = Visual(plottype, NamedArguments(kwargs))

function (v::Visual)(input::ProcessedLayer)
    plottype = Makie.plottype(v.plottype, input.plottype)
    default_attrs = mandatory_attributes(plottype)
    attributes = merge(default_attrs, input.attributes, v.attributes)

    return ProcessedLayer(input; plottype, attributes)
end

# In the future, consider switching from `visual(Plot{T})` to `visual(T)`.
visual(plottype::PlotType=Plot{plot}; kwargs...) = transformation(Visual(plottype; kwargs...))

# For backward compatibility, still allow `visual(Any)`.
@deprecate visual(::Type{Any}; kwargs...) visual(; kwargs...)

# Whenever a plot type's `aesthetic_mapping` depends on the value of some attribute,
# it has to be ensured that this value is present. We could also grab it from the theme
# but it seems very weird that someone would want a theme where all barplots switch from
# vertical to horizontal mode. So it is more straightforward to simply fix any attributes
# which are required to some known value, unless overridden by the user. Usually, that should
# be the same value that the plot type also sets in its default theme.
mandatory_attributes(T) = NamedArguments()
mandatory_attributes(::Type{BarPlot}) = dictionary([:direction => :y])
mandatory_attributes(::Type{Violin}) = dictionary([:orientation => :vertical])

# this function needs to be defined for any plot type that should work with AoG, because it tells
# AoG how its positional arguments can be understood in terms of the dimensions of the plot for
# which AoG computes scales
# The default assumption of x, y, [z] does not hold for many plot objects
function aesthetic_mapping end

aesthetic_mapping(p::ProcessedLayer) = aesthetic_mapping(p.plottype, p.attributes)

aesthetic_mapping(plottype, attributes)::AestheticMapping = _aesthetic_mapping(plottype, attributes)

_aesthetic_mapping(::Type{Lines}, attributes) = dictionary([1 => AesX, 2 => AesY, :color => AesColor])

function _aesthetic_mapping(::Type{BarPlot}, attributes)
    dir = attributes[:direction]
    dir in (:x, :y) || throw(ArgumentError("Invalid direction $dir for BarPlot"))
    dictionary([
        1 => dir == :y ? AesX : AesY,
        2 => dir == :y ? AesY : AesX,
        :color => AesColor,
    ])
end

function _aesthetic_mapping(::Type{Violin}, attributes)
    dir = attributes[:orientation]
    dir in (:horizontal, :vertical) || throw(ArgumentError("Invalid direction $dir for Violin"))
    dictionary([
        1 => dir == :horizontal ? AesX : AesY,
        2 => dir == :horizontal ? AesY : AesX,
        :color => AesColor,
    ])
end

function _aesthetic_mapping(::Type{Scatter}, attributes)
    dictionary([
        1 => AesX,
        2 => AesY,
        :color => AesColor,
        :strokecolor => AesColor,
        :marker => AesMarker,
    ])
end

function _aesthetic_mapping(::Type{HLines}, attributes)
    dictionary([
        1 => AesY,
        :color => AesColor,
    ])
end

function _aesthetic_mapping(::Type{VLines}, attributes)
    dictionary([
        1 => AesX,
        :color => AesColor,
    ])
end
