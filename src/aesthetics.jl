# Whenever a plot type's `aesthetic_mapping` depends on the value of some attribute,
# it has to be ensured that this value is present. We could also grab it from the theme
# but it seems very weird that someone would want a theme where all barplots switch from
# vertical to horizontal mode. So it is more straightforward to simply fix any attributes
# which are required to some known value, unless overridden by the user. Usually, that should
# be the same value that the plot type also sets in its default theme.
mandatory_attributes(T) = NamedArguments()
mandatory_attributes(::Type{<:Union{BarPlot,Rangebars,Errorbars,Hist}}) = dictionary([:direction => :y])
mandatory_attributes(::Type{Density}) = dictionary([:direction => :x])
mandatory_attributes(::Type{<:Union{Violin,RainClouds,BoxPlot,CrossBar}}) = dictionary([:orientation => :vertical])

# this function needs to be defined for any plot type that should work with AoG, because it tells
# AoG how its positional arguments can be understood in terms of the dimensions of the plot for
# which AoG computes scales
# The default assumption of x, y, [z] does not hold for many plot objects
function aesthetic_mapping end

function positional_scientific_types(p::ProcessedLayer)::Vector{ScientificType}
    map(p.positional) do pos
        # TODO: what about cases where the elements are actually vectors? Somehow this must be determined better
        if pos isa AbstractArray{<:AbstractArray}
            return scientific_type(eltype(eltype(pos)))
        else
            return scientific_eltype(pos)
        end
    end
end

aesthetic_mapping(p::ProcessedLayer) = aesthetic_mapping(p.plottype, p.attributes, positional_scientific_types(p))

function aesthetic_mapping(plottype, attributes, scitypes::Vector{ScientificType})::AestheticMapping
    mapping = aesthetic_mapping(plottype, scitypes...)
    for (key, value) in pairs(mapping)
        if value isa Pair
            attrkey, dict = value
            if !haskey(attributes, attrkey)
                error("Aesthetic mapping lookup for $plottype failed with key $(repr(key)), could not find $(repr(attrkey)) in plot attributes. Consider adding `mandatory_attributes(::$plottype)` to define a default for $(repr(attrkey)).")
            end
            attrvalue = attributes[attrkey]
            if !haskey(dict, attrvalue)
                error("Aesthetic mapping lookup for $plottype failed with key $(repr(key)), no entry for attribute $(repr(attrkey)) with value $(repr(attrvalue)). Existing variants are $(dict)")
            end
            aes = dict[attrvalue]
            mapping[key] = aes
        end
    end
    return mapping
end

function aesthetic_mapping(T::Type{<:Plot}, scitypes::ScientificType...)
    error("No aesthetic mapping defined yet for plot type $T with scientific eltypes $scitypes. AlgebraOfGraphics can only use plot types if it is told which attributes and input arguments map to which aesthetics like color, markersize or linewidth for example.")
end

aesthetic_mapping(::Type{Lines}, ::Normal) = aesthetic_mapping(Lines, 1)
aesthetic_mapping(::Type{Lines}, ::Normal, ::Normal) = aesthetic_mapping(Lines, 2)
aesthetic_mapping(::Type{Lines}, ::Normal, ::Normal, ::Normal) = aesthetic_mapping(Lines, 3)

function pointlike_positionals(N::Int)
    @assert 1 <= N <= 3
    if N == 1
        [1 => AesY]
    elseif N == 2
        [1 => AesX, 2 => AesY]
    else
        [1 => AesX, 2 => AesY, 3 => AesZ]
    end
end

function aesthetic_mapping(::Type{Lines}, N::Int)
    dictionary([
        pointlike_positionals(N)...,
        :color => AesColor,
        :linestyle => AesLineStyle,
    ])
end

aesthetic_mapping(::Type{BarPlot}, ::Normal) = aesthetic_mapping(BarPlot, 1)
aesthetic_mapping(::Type{BarPlot}, ::Normal, ::Normal) = aesthetic_mapping(BarPlot, 2)

function aesthetic_mapping(::Type{BarPlot}, N::Int)
    @assert 1 <= N <= 2
    positionals = if N == 1
        [
            1 => :direction => dictionary([
            :y => AesY,
            :x => AesX,
            ])
        ]
    else
        [
            1 => :direction => dictionary([
                :y => AesX,
                :x => AesY,
            ]),
            2 => :direction => dictionary([
                :y => AesY,
                :x => AesX,
            ]),
        ]
    end
    dictionary([
        positionals...,
        :color => AesColor,
        :width => :direction => dictionary([
            :y => AesDeltaX,
            :x => AesDeltaY,
        ]),
        :dodge => AesDodge,
        :stack => AesStack,
    ])
end

function aesthetic_mapping(::Type{Violin}, ::Normal, ::Normal)
    dictionary([
        1 => :orientation => dictionary([
            :horizontal => AesY,
            :vertical => AesX,
        ]),
        2 => :orientation => dictionary([
            :horizontal => AesX,
            :vertical => AesY,
        ]),
        :color => AesColor,
        :side => AesViolinSide,
        :dodge => AesDodge,
    ])
end

aesthetic_mapping(::Type{Scatter}, ::Normal) = aesthetic_mapping(Scatter, 1)
aesthetic_mapping(::Type{Scatter}, ::Normal, ::Normal) = aesthetic_mapping(Scatter, 2)
aesthetic_mapping(::Type{Scatter}, ::Normal, ::Normal, ::Normal) = aesthetic_mapping(Scatter, 3)

function aesthetic_mapping(::Type{Scatter}, N::Int)
    dictionary([
        pointlike_positionals(N)...,
        :color => AesColor,
        :strokecolor => AesColor,
        :marker => AesMarker,
        :markersize => AesMarkerSize,
    ])
end

aesthetic_mapping(::Type{ScatterLines}, ::Normal) = aesthetic_mapping(ScatterLines, 1)
aesthetic_mapping(::Type{ScatterLines}, ::Normal, ::Normal) = aesthetic_mapping(ScatterLines, 2)
aesthetic_mapping(::Type{ScatterLines}, ::Normal, ::Normal, ::Normal) = aesthetic_mapping(ScatterLines, 3)

function aesthetic_mapping(::Type{ScatterLines}, N::Int)
    dictionary([
        pointlike_positionals(N)...,
        :color => AesColor,
        :strokecolor => AesColor,
        :marker => AesMarker,
        :markersize => AesMarkerSize,
        :linestyle => AesLineStyle,
    ])
end

function aesthetic_mapping(::Type{HLines}, ::Normal)
    dictionary([
        1 => AesY,
        :color => AesColor,
    ])
end

function aesthetic_mapping(::Type{VLines}, ::Normal)
    dictionary([
        1 => AesX,
        :color => AesColor,
    ])
end

function aesthetic_mapping(::Type{HSpan}, ::Normal, ::Normal)
    dictionary([
        1 => AesY,
        2 => AesY,
        :color => AesColor,
    ])
end

function aesthetic_mapping(::Type{VSpan}, ::Normal, ::Normal)
    dictionary([
        1 => AesX,
        2 => AesX,
        :color => AesColor,
    ])
end

function aesthetic_mapping(::Type{RainClouds}, ::Normal, ::Normal)
    dictionary([
        1 => :orientation => dictionary([
            :horizontal => AesY,
            :vertical => AesX,
        ]),
        2 => :orientation => dictionary([
            :horizontal => AesX,
            :vertical => AesY,
        ]),
        :color => AesColor,
    ])
end

function aesthetic_mapping(::Type{Heatmap}, ::Normal, ::Normal, ::Normal)
    dictionary([
        1 => AesX,
        2 => AesY,
        3 => AesColor,
    ])
end

function aesthetic_mapping(::Type{LinesFill}, ::Normal, ::Normal)
    dictionary([
        1 => AesX,
        2 => AesY,
        :lower => AesY,
        :upper => AesY,
        :color => AesColor,
    ])
end

function aesthetic_mapping(::Type{Rangebars}, ::Normal, ::Normal, ::Normal)
    dictionary([
        1 => :direction => dictionary([
            :x => AesY,
            :y => AesX,
        ]),
        2 => :direction => dictionary([
            :x => AesX,
            :y => AesY,
        ]),
        3 => :direction => dictionary([
            :x => AesX,
            :y => AesY,
        ]),
        :color => AesColor,
    ])
end

aesthetic_mapping(::Type{Errorbars}, ::Normal, ::Normal, ::Normal) = aesthetic_mapping(Errorbars, 3)
aesthetic_mapping(::Type{Errorbars}, ::Normal, ::Normal, ::Normal, ::Normal) = aesthetic_mapping(Errorbars, 4)

function aesthetic_mapping(::Type{Errorbars}, i::Int)
    @assert i in (3, 4)
    fourtharg = i == 3 ? [] : [
        4 => :direction => dictionary([
            :x => AesDeltaX,
            :y => AesDeltaY,
        ])
    ]
    dictionary([
        1 => :direction => dictionary([
            :x => AesY,
            :y => AesX,
        ]),
        2 => :direction => dictionary([
            :x => AesX,
            :y => AesY,
        ]),
        3 => :direction => dictionary([
            :x => AesDeltaX,
            :y => AesDeltaY,
        ]),
        fourtharg...,
        :color => AesColor,
    ])
end


function aesthetic_mapping(::Type{Makie.Text}, ::Normal, ::Normal)
    dictionary([
        1 => AesX,
        2 => AesY,
        :text => AesText,
        :color => AesColor,
    ])
end

function aesthetic_mapping(::Type{BoxPlot}, ::Normal, ::Normal)
    dictionary([
        1 => :orientation => dictionary([
            :horizontal => AesY,
            :vertical => AesX,
        ]),
        2 => :orientation => dictionary([
            :horizontal => AesX,
            :vertical => AesY,
        ]),
        :color => AesColor,
        :dodge => AesDodge,
    ])
end

function aesthetic_mapping(::Type{CrossBar}, ::Normal, ::Normal, ::Normal, ::Normal)
    dictionary([
        1 => :orientation => dictionary([
            :horizontal => AesY,
            :vertical => AesX,
        ]),
        2 => :orientation => dictionary([
            :horizontal => AesX,
            :vertical => AesY,
        ]),
        3 => :orientation => dictionary([
            :horizontal => AesX,
            :vertical => AesY,
        ]),
        4 => :orientation => dictionary([
            :horizontal => AesX,
            :vertical => AesY,
        ]),
        :color => AesColor,
        :dodge => AesDodge,
    ])
end

function aesthetic_mapping(::Type{Contour}, ::Normal, ::Normal, ::Normal)
    dictionary([
        1 => AesX,
        2 => AesY,
        3 => AesContourColor,
        :color => AesColor, # only categorical, for continuous one would have to use 3
        :linestyle => AesLineStyle, # only categorical, for continuous one would have to use 3
    ])
end

# if this wasn't set, a contour plot would be colored with a colormap according to positional arg 3, but we currently cannot handle that in the right way
mandatory_attributes(::Type{Contour}) = dictionary([:colormap => [Makie.current_default_theme()[:linecolor][]]])

function aesthetic_mapping(::Type{QQPlot}, ::Normal, ::Normal)
    dictionary([
        1 => AesX,
        2 => AesY,
        :color => AesColor,
        :linestyle => AesLineStyle,
    ])
end

function aesthetic_mapping(::Type{QQNorm}, ::Normal)
    dictionary([
        1 => AesY,
        :color => AesColor,
        :linestyle => AesLineStyle,
    ])
end

function aesthetic_mapping(::Type{Arrows}, ::Normal, ::Normal, ::Normal, ::Normal)
    dictionary([
        1 => AesX,
        2 => AesY,
        3 => AesDeltaX,
        4 => AesDeltaY,
        :color => AesColor,
        :arrowhead => AesMarker,
    ])
end

function aesthetic_mapping(::Type{Choropleth}, ::Geometrical)
    dictionary([
        1 => AesPlaceholder,
        :color => AesColor,
    ])
end

function aesthetic_mapping(::Type{Poly}, ::Geometrical)
    dictionary([
        1 => AesPlaceholder,
        :color => AesColor,
    ])
end

function aesthetic_mapping(::Type{LongPoly}, ::Normal, ::Normal, ::Union{Normal,Geometrical}, ::Union{Normal,Geometrical})
    dictionary([
        1 => AesX,
        2 => AesY,
        3 => AesPlaceholder, # poly id
        4 => AesPlaceholder, # subgroup id
        :color => AesColor,
    ])
end

function aesthetic_mapping(::Type{Surface}, ::Normal, ::Normal, ::Normal)
    dictionary([
        1 => AesX,
        2 => AesY,
        3 => AesZ,
    ])
end

function aesthetic_mapping(::Type{Wireframe}, ::Normal, ::Normal, ::Normal)
    dictionary([
        1 => AesX,
        2 => AesY,
        3 => AesZ,
        :color => AesColor,
    ])
end

function aesthetic_mapping(::Type{Band}, ::Normal, ::Normal, ::Normal)
    dictionary([
        1 => AesX,
        2 => AesY,
        3 => AesY,
        :color => AesColor,
    ])
end

function aesthetic_mapping(::Type{ABLines}, ::Normal, ::Normal)
    dictionary([
        1 => AesABIntercept,
        2 => AesABSlope,
        :color => AesColor,
        :linestyle => AesLineStyle,
    ])
end

function aesthetic_mapping(::Type{Density}, ::Normal)
    dictionary([
        1 => :direction => dictionary([
            :x => AesX,
            :y => AesY,
        ]),
        :color => AesColor,
    ])
end

function aesthetic_mapping(::Type{ECDFPlot}, ::Normal)
    dictionary([
        1 => AesX,
        :color => AesColor,
        :linestyle => AesLineStyle,
    ])
end

function aesthetic_mapping(::Type{Hist}, ::Normal)
    dictionary([
        1 => :direction => dictionary([
            :y => AesX,
            :x => AesY,
        ]),
        :color => AesColor,
        :strokecolor => AesColor,
    ])
end
