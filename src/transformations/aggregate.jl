# Generic aggregation transformation for flexible data aggregation

"""
    AggregateAnalysis

Analysis that performs flexible aggregation of data with optional output remapping.

Fields:
- `aggregations`: Pairs of target => aggregation function
- `groupby`: Tuple of integers and/or symbols specifying grouping dimensions
- `remap`: Vector of remapping specifications for output reorganization
"""
struct AggregateAnalysis{A, G, R}
    aggregations::A
    groupby::G
    remap::R
end

"""
    aggregate(target => aggfunc, ...; groupby, remap=nothing)

Perform flexible aggregation of data.

# Arguments
- Positional pairs of `target => aggfunc` where:
  - `target`: Integer (positional arg) or Symbol (named arg) to aggregate
  - `aggfunc`: Function to aggregate values (e.g., `mean`, `median`, `std`, `extrema`)
- `groupby`: Integer, Symbol, or Tuple specifying grouping dimensions
  - Integers refer to positional arguments (1 = first, 2 = second, etc.)
  - Symbols refer to named mappings (e.g., `:color`, `:group`)
  - Tuples combine multiple: `(1, :color)` groups by first position and color
- `remap`: Optional vector of remapping rules to reorganize outputs
  - Format: `source => destination` or `source => accessor => destination`
  - `source`: Integer or Symbol of aggregation result
  - `accessor`: Function to extract part of result (e.g., `first`, `last`, `x -> x[1]`)
  - `destination`: Integer or Symbol for final position
  - All outputs must be explicitly remapped if remap is provided

# Examples

```julia
# Basic: aggregate 2nd position grouped by 1st
data(...) * mapping(:time, :value) * 
    aggregate(2 => median, groupby=1)

# Multiple aggregations
data(...) * mapping(:time, :value, :score) * 
    aggregate(2 => mean, 3 => std, groupby=1)

# Split extrema output into separate positions
data(...) * mapping(:time, :value) * 
    aggregate(2 => extrema, groupby=1, remap=[
        2 => first => 2,   # lower bound to position 2
        2 => last => 3     # upper bound to position 3
    ])

# Complex remapping with multiple aggregations
data(...) * mapping(:x, :y, :z, color=:group) * 
    aggregate(
        2 => extrema,      # y bounds
        3 => mean,         # z mean
        :group => maximum, # max group
        groupby=1,
        remap=[
            2 => first => 2,   # y lower
            2 => last => 3,    # y upper
            3 => 4,            # z mean to position 4
            :group => :group   # keep group as is
        ]
    )

# Group by multiple dimensions
data(...) * mapping(:x, :y, :z) * 
    aggregate(3 => mean, groupby=(1, 2))
```
"""
function aggregate(aggregations::Pair...; groupby, remap=nothing)
    return transformation(AggregateAnalysis(aggregations, groupby, remap))
end

# Helper to create aggregator in the format _groupreduce expects
function make_aggregator(aggfunc)
    return (
        init = () -> Any[],
        op = (acc, val) -> begin
            push!(acc, val)
            return acc
        end,
        value = acc -> begin
            isempty(acc) ? missing : aggfunc(acc)
        end
    )
end

# Optimized aggregators for common cases
const MeanAgg = (
    init = () -> (0, 0.0),
    op = ((n, sum), val) -> (n + 1, sum + val),
    value = ((n, sum),) -> n == 0 ? missing : sum / n
)

const SumAgg = (
    init = () -> 0.0,
    op = (sum, val) -> sum + val,
    value = identity
)

const CountAgg = (
    init = () -> 0,
    op = (n, _) -> n + 1,
    value = identity
)

function optimize_aggregator(aggfunc)
    # Optimize common cases
    # if aggfunc === Statistics.mean
    #     return MeanAgg
    # elseif aggfunc === sum
    #     return SumAgg
    # elseif aggfunc === length
    #     return CountAgg
    # else
        return make_aggregator(aggfunc)
    # end
end

function (a::AggregateAnalysis)(input::ProcessedLayer)
    N = length(input.positional)
    
    # Normalize groupby to tuple
    groupby_tuple = a.groupby isa Tuple ? a.groupby : (a.groupby,)
    
    # Extract grouping indices (integers only for now)
    grouping_indices = Int[]
    for idx in groupby_tuple
        if idx isa Integer
            if idx < 1 || idx > N
                throw(ArgumentError("groupby index $idx out of bounds for $N positional arguments"))
            end
            push!(grouping_indices, idx)
        else
            # Symbol-based grouping - to be implemented later
            error("Symbol-based grouping in groupby not yet implemented")
        end
    end
    
    # Build summaries for unique values in grouping dimensions
    summaries = [
        mapreduce(collect ∘ uniquesorted, mergesorted, input.positional[idx])
        for idx in grouping_indices
    ]
    
    # Perform aggregations and build output in a single map over input
    output = map(input) do p, n
        # For this cell, perform all aggregations
        cell_results = Dict{Any, Any}()
        
        for (target, aggfunc) in a.aggregations
            if target isa Integer
                if target < 1 || target > N
                    throw(ArgumentError("aggregation target $target out of bounds for $N positional arguments"))
                end
                if target in grouping_indices
                    throw(ArgumentError("cannot aggregate column $target which is used for grouping"))
                end
                
                # Create aggregator
                agg = optimize_aggregator(aggfunc)
                
                # Extract grouping keys and target values for this cell
                keys = Tuple(p[idx] for idx in grouping_indices)
                target_values = p[target]
                values_tuple = (keys..., target_values)
                
                # Use _groupreduce to get aggregated array
                result = _groupreduce(agg, Tuple(summaries), values_tuple)
                
                cell_results[target] = result
                
            elseif target isa Symbol
                # Symbol-based aggregation for named arguments
                if !haskey(n, target)
                    throw(ArgumentError("aggregation target :$target not found in named arguments"))
                end
                
                # Create aggregator
                agg = optimize_aggregator(aggfunc)
                
                # Extract grouping keys and target values for this cell
                keys = Tuple(p[idx] for idx in grouping_indices)
                target_values = n[target]
                values_tuple = (keys..., target_values)
                
                # Use _groupreduce to get aggregated array
                result = _groupreduce(agg, Tuple(summaries), values_tuple)
                
                cell_results[target] = result
            else
                throw(ArgumentError("aggregation target must be an Integer or Symbol, got $(typeof(target))"))
            end
        end
        
        # Apply remapping and build final positional/named structure
        if a.remap !== nothing
            # Build remapped results for this cell
            remapped = Dict{Any, Any}()
            
            for remap_spec in a.remap
                if remap_spec isa Pair
                    source, dest_or_accessor = remap_spec
                    
                    if dest_or_accessor isa Pair
                        # Format: source => accessor => destination
                        accessor, destination = dest_or_accessor
                        
                        if !haskey(cell_results, source)
                            throw(ArgumentError("remap source $source not found in aggregation results"))
                        end
                        
                        # Apply accessor to extract part of the result
                        source_data = cell_results[source]
                        extracted = map(accessor, source_data)
                        
                        if haskey(remapped, destination)
                            throw(ArgumentError("remap destination $destination specified multiple times"))
                        end
                        
                        remapped[destination] = extracted
                    else
                        # Format: source => destination (no accessor)
                        destination = dest_or_accessor
                        
                        if !haskey(cell_results, source)
                            throw(ArgumentError("remap source $source not found in aggregation results"))
                        end
                        
                        if haskey(remapped, destination)
                            throw(ArgumentError("remap destination $destination specified multiple times"))
                        end
                        
                        remapped[destination] = cell_results[source]
                    end
                else
                    throw(ArgumentError("remap specification must be a Pair"))
                end
            end
            
            # Check that all aggregation results are remapped
            for key in keys(cell_results)
                found = false
                for remap_spec in a.remap
                    if remap_spec isa Pair && first(remap_spec) == key
                        found = true
                        break
                    end
                end
                if !found
                    throw(ArgumentError("aggregation result $key not remapped. All outputs must be explicitly specified in remap."))
                end
            end
            
            final_results = remapped
        else
            # No remapping, use results as-is
            final_results = cell_results
        end
        
        # Separate positional and named results
        positional_keys = sort([k for k in keys(final_results) if k isa Integer])
        named_keys = [k for k in keys(final_results) if k isa Symbol]
        
        # Build positional array preserving original positions
        # Grouping indices get their summaries, aggregated indices get their aggregated values
        positional = Vector{Any}(undef, N)
        
        # Fill in summaries for grouping positions
        for (i, group_idx) in enumerate(grouping_indices)
            positional[group_idx] = summaries[i]
        end
        
        # Fill in aggregated values for their original positions
        for k in positional_keys
            positional[k] = final_results[k]
        end
        
        # Build named arguments from symbol-keyed results
        named_dict = Dictionary{Symbol, Any}()
        for k in named_keys
            insert!(named_dict, k, final_results[k])
        end
        
        named = merge(n, named_dict)
        
        return positional, named
    end
    
    # Set appropriate default plot type
    N_groups = length(grouping_indices)
    default_plottype = categoricalplottypes[N_groups]
    plottype = Makie.plottype(output.plottype, default_plottype)
    
    return ProcessedLayer(output; plottype)
end
