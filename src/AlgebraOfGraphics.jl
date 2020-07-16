module AlgebraOfGraphics

using Tables: columns, getcolumn, columnnames, AbstractColumns, Tables
using CategoricalArrays: categorical, cut, levelcode, refs, levels, CategoricalArray
using Observables: AbstractObservable, Observable, to_value
using NamedDims: NamedDimsArray, dimnames
using StructArrays: GroupPerm, refine_perm!, StructArray
using KernelDensity: kde
import GLM, Loess

using AbstractPlotting: Point2f0,
                        Attributes,
                        AbstractPlot,
                        Node,
                        lift,
                        @lift,
                        RGBAf0,
                        AbstractPlotting

using AbstractPlotting.MakieLayout: LAxis,
                                    LText,
                                    LRect,
                                    GridLayout,
                                    linkxaxes!,
                                    linkyaxes!,
                                    hidexdecorations!,
                                    hideydecorations!,
                                    Top,
                                    Bottom,
                                    Left,
                                    Right,
                                    MakieLayout

export data, dims, draw, spec, style
export categorical, cut

include("algebraic_list.jl")
include("utils.jl")
include("context.jl")
include("specs.jl")
include("scales.jl")
include("analysis/analysis.jl")
include("analysis/smooth.jl")
include("analysis/density.jl")
include("draw.jl")

end # module
