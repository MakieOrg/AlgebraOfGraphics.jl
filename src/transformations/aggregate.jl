# Generic aggregation transformation for flexible data aggregation

"""
    AggregateAnalysis

Analysis that performs flexible aggregation of data.

Fields:
- `aggregations`: Pairs of target => aggregation function
- `groupby`: Tuple of integers specifying grouping dimensions
"""
struct AggregateAnalysis{A, G}
    aggregations::A
    groupby::G
end

"""
    aggregate(args...; named_args...)

Perform flexible aggregation of data. Use `:` to mark grouping dimensions and 
aggregation functions for dimensions to aggregate.

# Arguments
- Positional arguments can be:
  - `:` to mark this position for grouping
  - An aggregation function (e.g., `mean`, `median`, `std`) to aggregate this position
- Named arguments are aggregation functions for named mappings (e.g., `color = mean`)

# Examples

```julia
# Aggregate y values (position 2), group by x (position 1)
data(...) * mapping(:time, :value) * 
    aggregate(:, median)

# Aggregate x values (position 1), group by y (position 2)
data(...) * mapping(:value, :time) * 
    aggregate(mean, :)

# Multiple aggregations with named argument
data(...) * mapping(:time, :value, color=:group) * 
    aggregate(:, mean, color = length)

# Group by multiple dimensions
data(...) * mapping(:x, :y, :z) * 
    aggregate(:, :, mean)
```
"""
function aggregate(args...; named_aggs...)
    # Parse positional arguments to separate groupby indices from aggregations
    groupby_indices = Int[]
    aggregations = Pair[]
    
    for (i, arg) in enumerate(args)
        if arg === (:)
            push!(groupby_indices, i)
        else
            # arg should be an aggregation function
            push!(aggregations, i => arg)
        end
    end
    
    # Add named aggregations
    for (name, aggfunc) in pairs(named_aggs)
        push!(aggregations, name => aggfunc)
    end
    
    # Convert groupby to tuple or single value
    groupby = length(groupby_indices) == 1 ? groupby_indices[1] : Tuple(groupby_indices)
    
    return transformation(AggregateAnalysis(Tuple(aggregations), groupby))
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
        # Extract grouping keys once (same for all aggregations)
        grouping_key_columns = Tuple(p[idx] for idx in grouping_indices)
        sa = StructArray(map(fast_hashed, grouping_key_columns))
        perm = sortperm(sa)
        group_perm = GroupPerm(sa, perm)
        
        # Extract actual keys that exist in the data (unhashed)
        actual_keys = map(group_perm) do idxs
            idx = perm[first(idxs)]
            # Extract the unhashed key values for this group
            return map(k -> k[idx], grouping_key_columns)
        end
        
        # For this cell, perform all aggregations using the same grouping
        cell_results = Dict{Any, Any}()
        
        for (target, aggfunc) in a.aggregations
            # Validate target and extract target values
            if target isa Integer
                if target < 1 || target > N
                    throw(ArgumentError("aggregation target $target out of bounds for $N positional arguments"))
                end
                if target in grouping_indices
                    throw(ArgumentError("cannot aggregate column $target which is used for grouping"))
                end
                target_values = p[target]
            elseif target isa Symbol
                if !haskey(n, target)
                    throw(ArgumentError("aggregation target :$target not found in named arguments"))
                end
                target_values = n[target]
            else
                throw(ArgumentError("aggregation target must be an Integer or Symbol, got $(typeof(target))"))
            end
            
            # Apply aggregation using the precomputed GroupPerm
            result = map(group_perm) do idxs
                group_indices = perm[idxs]
                group_values = view(target_values, group_indices)
                return aggfunc(group_values)
            end
            
            cell_results[target] = result
        end
        
        # Separate positional and named results
        positional_keys = sort([k for k in keys(cell_results) if k isa Integer])
        named_keys = [k for k in keys(cell_results) if k isa Symbol]
        
        # Build positional array preserving original positions
        positional = Vector{Any}(undef, N)
        
        # Extract each grouping dimension component from actual_keys
        # actual_keys is a vector of tuples, each containing unhashed key values
        for (i, group_idx) in enumerate(grouping_indices)
            positional[group_idx] = [key[i] for key in actual_keys]
        end
        
        # Fill in aggregated values for their original positions (flatten if multidimensional)
        for k in positional_keys
            result = cell_results[k]
            # Flatten multidimensional aggregation results to vector
            positional[k] = result isa AbstractArray && ndims(result) > 1 ? vec(result) : result
        end
        
        # Build named arguments from symbol-keyed results
        named_dict = Dictionary{Symbol, Any}()
        for k in named_keys
            insert!(named_dict, k, cell_results[k])
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
