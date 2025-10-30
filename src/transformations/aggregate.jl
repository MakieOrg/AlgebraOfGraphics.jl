struct ParsedAggregation
    target::Union{Int, Symbol}
    aggfunc::Base.Callable
    splits::Any
    label::Any
    scaleid::Union{Nothing, ScaleID}
end

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
  - `aggfunc => [accessor => dest, ...]` to split aggregation results into multiple positions
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

# Split extrema into separate positions for range bars
data(...) * mapping(:x, :y) * 
    aggregate(:, extrema => [first => 2, last => 3]) *
    visual(Rangebars)
```
"""
# Helper to parse aggregation spec: just a function
_parse_agg_spec(target, f) = ParsedAggregation(target, f, nothing, nothing, nothing)

# Helper to parse aggregation spec: function => splits (for result splitting)
_parse_agg_spec(target, p::Pair{<:Function, <:AbstractVector}) = 
    ParsedAggregation(target, first(p), last(p), nothing, nothing)

# Helper to parse aggregation spec: function => label (accepts any label type like String, RichText, etc.)
_parse_agg_spec(target, p::Pair{<:Function}) = 
    ParsedAggregation(target, first(p), nothing, last(p), nothing)

# Helper to parse aggregation spec: (function => splits) => label
_parse_agg_spec(target, p::Pair{<:Pair{<:Function, <:AbstractVector}}) = 
    ParsedAggregation(target, first(first(p)), last(first(p)), last(p), nothing)

# Helper to parse aggregation spec: function => (label => scale_id)
_parse_agg_spec(target, p::Pair{<:Function, <:Pair{<:Any, ScaleID}}) = 
    ParsedAggregation(target, first(p), nothing, first(last(p)), last(last(p)))

# Helper to parse aggregation spec: (function => splits) => (label => scale_id)
_parse_agg_spec(target, p::Pair{<:Pair{<:Function, <:AbstractVector}, <:Pair{<:Any, ScaleID}}) = 
    ParsedAggregation(target, first(first(p)), last(first(p)), first(last(p)), last(last(p)))

function aggregate(args...; named_aggs...)
    # Parse positional arguments to separate groupby indices from aggregations
    groupby_indices = Int[]
    aggregations = Pair[]
    
    for (i, arg) in enumerate(args)
        if arg === (:)
            push!(groupby_indices, i)
        else
            # arg should be an aggregation specification
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
    
    # Parse all aggregation specs once and compute labels
    parsed_aggregations = map(a.aggregations) do (target, agg_spec)
        parsed = _parse_agg_spec(target, agg_spec)
        
        # Get original label for this target
        original_label = get(input.labels, target, "")
        
        # Generate label for aggregated output
        if parsed.label !== nothing
            generated_label = parsed.label
        else
            func_name = string(nameof(parsed.aggfunc))
            generated_label = isempty(original_label) ? func_name : "$(func_name)($(original_label))"
        end
        
        return ParsedAggregation(target, parsed.aggfunc, parsed.splits, generated_label, parsed.scaleid)
    end
    
    # Build output labels dictionary (Any to support RichText, String, etc.)
    # Wrap labels in fill() to make them broadcastable
    output_labels = Dict{Union{Int, Symbol}, Any}()
    # Build scale_mapping dictionary to map positions/names to custom scale ids
    scale_mapping = Dictionary{KeyType, Symbol}()
    
    for parsed in parsed_aggregations
        if parsed.splits === nothing
            output_labels[parsed.target] = fill(parsed.label)
            if parsed.scaleid !== nothing
                insert!(scale_mapping, parsed.target, parsed.scaleid.id)
            end
        else
            for split_pair in parsed.splits
                accessor, destination = split_pair
                accessor_name = string(nameof(accessor))
                output_labels[destination] = fill("$(accessor_name)($(parsed.label))")
                if parsed.scaleid !== nothing
                    insert!(scale_mapping, destination, parsed.scaleid.id)
                end
            end
        end
    end
    
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
        
        # Build output dictionary - will contain all results indexed by position or symbol
        outputs = Dict{Union{Int, Symbol}, Any}()
        
        # First, add grouping columns (they keep their positions with actual key values)
        for (i, group_idx) in enumerate(grouping_indices)
            outputs[group_idx] = [key[i] for key in actual_keys]
        end
        
        # Now process all aggregations
        for parsed in parsed_aggregations
            target = parsed.target
            aggfunc = parsed.aggfunc
            splits = parsed.splits
            
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
            
            # Flatten multidimensional results
            result = result isa AbstractArray && ndims(result) > 1 ? vec(result) : result
            
            # Handle result splitting or direct storage
            if splits === nothing
                # No splitting, store directly at target position
                if haskey(outputs, target)
                    throw(ArgumentError("output position $target already assigned"))
                end
                outputs[target] = result
            else
                # Split the result using accessors
                for split_pair in splits
                    accessor, destination = split_pair
                    if haskey(outputs, destination)
                        throw(ArgumentError("output position $destination already assigned"))
                    end
                    split_result = map(accessor, result)
                    outputs[destination] = split_result
                end
            end
        end
        
        # Separate positional and named results
        positional_keys = sort([k for k in keys(outputs) if k isa Integer])
        named_keys = [k for k in keys(outputs) if k isa Symbol]
        
        # Validate positional keys form a contiguous range from 1 to max
        if !isempty(positional_keys)
            max_pos = maximum(positional_keys)
            expected = 1:max_pos
            missing_positions = setdiff(expected, positional_keys)
            if !isempty(missing_positions)
                throw(ArgumentError("positional outputs must be contiguous, got $positional_keys missing $missing_positions"))
            end
        end
        
        # Build positional array from sorted keys
        positional = [outputs[k] for k in positional_keys]
        
        # Build named arguments from symbol-keyed results
        named_dict = Dictionary{Symbol, Any}()
        for k in named_keys
            insert!(named_dict, k, outputs[k])
        end
        
        named = merge(n, named_dict)
        
        return positional, named
    end
    
    # Set appropriate default plot type
    N_groups = length(grouping_indices)
    default_plottype = categoricalplottypes[N_groups]
    plottype = Makie.plottype(output.plottype, default_plottype)
    
    # Apply labels to the output
    labels = set(output.labels, (k => v for (k, v) in output_labels)...)
    
    # Merge scale_mapping with existing scale_mapping from output
    merged_scale_mapping = merge(output.scale_mapping, scale_mapping)
    
    return ProcessedLayer(output; plottype, labels, scale_mapping=merged_scale_mapping)
end
