"""
    AggregationOutput

Represents a single output from an aggregation, with an optional accessor function,
destination position/name, optional label, and optional scale id.
"""
struct AggregationOutput
    accessor::Union{Nothing, Base.Callable}  # Function to extract from aggregation result (nothing means use as-is)
    destination::Union{Int, Symbol}  # Where to place this output
    label::Any  # Optional label (can be String, RichText, etc.)
    scaleid::Union{Nothing, ScaleID}  # Optional scale id
end

"""
    ParsedAggregation

Internal struct to hold parsed aggregation specification.
Each aggregation of a target produces one or more outputs.
"""
struct ParsedAggregation
    target::Union{Int, Symbol}  # Source column to aggregate
    aggfunc::Base.Callable  # Aggregation function
    outputs::Vector{AggregationOutput}  # One or more outputs from this aggregation
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
# Parse a single output spec: destination or destination => label or destination => label => scale_id
function _parse_output_spec(dest::Union{Int, Symbol})
    return AggregationOutput(nothing, dest, nothing, nothing)
end

# Helper to parse the "rest" part after destination
_parse_label_and_scale(label) = (label, nothing)
_parse_label_and_scale(p::Pair{<:Any, ScaleID}) = (first(p), last(p))

# dest => something (dispatch on the something)
function _parse_output_spec(p::Pair)
    dest = first(p)
    rest = last(p)
    label, scaleid = _parse_label_and_scale(rest)
    return AggregationOutput(nothing, dest, label, scaleid)
end

# Parse split spec: accessor => output_spec
function _parse_split(p::Pair{<:Base.Callable, <:Union{Int, Symbol}})
    accessor = first(p)
    dest = last(p)
    return AggregationOutput(accessor, dest, nothing, nothing)
end

function _parse_split(p::Pair{<:Base.Callable, <:Pair})
    accessor = first(p)
    dest_spec = last(p)
    output = _parse_output_spec(dest_spec)
    return AggregationOutput(accessor, output.destination, output.label, output.scaleid)
end

# Helper to parse aggregation spec: just a function
_parse_agg_spec(target, f::Base.Callable) = 
    ParsedAggregation(target, f, [AggregationOutput(nothing, target, nothing, nothing)])

# Helper to parse the splits/label part of function => splits_or_label
_parse_outputs(target, aggfunc, splits::AbstractVector) = 
    ParsedAggregation(target, aggfunc, map(_parse_split, splits))

function _parse_outputs(target, aggfunc, label_and_or_scale)
    # Not a vector, so it's label and/or scale_id
    label, scaleid = _parse_label_and_scale(label_and_or_scale)
    return ParsedAggregation(target, aggfunc, [AggregationOutput(nothing, target, label, scaleid)])
end

# Helper to parse aggregation spec: function => something
function _parse_agg_spec(target, p::Pair{<:Base.Callable})
    aggfunc = first(p)
    outputs_spec = last(p)
    return _parse_outputs(target, aggfunc, outputs_spec)
end

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
    
    # Parse all aggregation specs once and compute labels for each output
    parsed_aggregations = map(a.aggregations) do (target, agg_spec)
        parsed = _parse_agg_spec(target, agg_spec)
        
        # Get original label for this target
        original_label = get(input.labels, target, "")
        
        # Generate labels for each output
        func_name = string(nameof(parsed.aggfunc))
        base_label = isempty(original_label) ? func_name : "$(func_name)($(original_label))"
        
        # Update outputs with generated labels where not provided
        outputs = map(parsed.outputs) do output
            if output.label !== nothing
                # User provided explicit label
                return output
            elseif output.accessor !== nothing
                # Generate label with accessor name
                accessor_name = string(nameof(output.accessor))
                generated_label = "$(accessor_name)($(base_label))"
                return AggregationOutput(output.accessor, output.destination, generated_label, output.scaleid)
            else
                # Use base label
                return AggregationOutput(output.accessor, output.destination, base_label, output.scaleid)
            end
        end
        
        return ParsedAggregation(target, parsed.aggfunc, outputs)
    end
    
    # Build output labels dictionary (Any to support RichText, String, etc.)
    # Wrap labels in fill() to make them broadcastable
    # Also build scale_mapping dictionary to map positions/names to custom scale ids
    output_labels = Dict{Union{Int, Symbol}, Any}()
    scale_mapping = Dictionary{KeyType, Symbol}()
    
    for parsed in parsed_aggregations
        for output in parsed.outputs
            output_labels[output.destination] = fill(output.label)
            if output.scaleid !== nothing
                insert!(scale_mapping, output.destination, output.scaleid.id)
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
            
            # Process each output from this aggregation
            for output in parsed.outputs
                destination = output.destination
                
                if haskey(outputs, destination)
                    throw(ArgumentError("output position $destination already assigned"))
                end
                
                # Apply accessor if present, otherwise use result as-is
                final_result = if output.accessor !== nothing
                    map(output.accessor, result)
                else
                    result
                end
                
                outputs[destination] = final_result
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
