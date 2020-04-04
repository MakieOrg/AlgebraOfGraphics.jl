module AlgebraOfGraphics

using Tables: columns, getcolumn, columnnames, isdata
using PooledArrays: PooledArray, PooledVector, RefArray
using DataAPI: refarray, refvalue
using Observables: AbstractObservable, Observable, to_value
using OrderedCollections: OrderedDict, LittleDict
using NamedDims: NamedDimsArray, dimnames
using StructArrays: finduniquesorted, StructArray
import GLM, Loess
using Requires: @require

export group, style, data, spec, dims, draw

include("context.jl")
include("specs.jl")
include("utils.jl")
include("analysis/smooth.jl")

function draw end

function __init__()
    @require AbstractPlotting="537997a7-5e4e-5d89-9595-2241ea00577e" begin
        @require MakieLayout="5a521ce4-ebb9-4793-b5b7-b334dfe8393c" begin
            include("makielayout_integration.jl")
        end
    end
end

end # module
