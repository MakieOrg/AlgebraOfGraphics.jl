struct AggregationOutput
    accessor::Union{Nothing, Base.Callable}  # Function to extract from aggregation result (nothing means use as-is)
    destination::Union{Int, Symbol}  # Where to place this output
    label::Any  # Optional label (can be String, RichText, etc.)
    scaleid::Union{Nothing, ScaleID}  # Optional scale id
end

struct ParsedAggregation
    target::Union{Int, Symbol}  # Source column to aggregate
    aggfunc::Base.Callable  # Aggregation function
    outputs::Vector{AggregationOutput}  # One or more outputs from this aggregation
end

struct AggregateAnalysis{A, G}
    aggregations::A
    groupby::G
end

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

# Fallback for when the array element type is inferred as Pair{Function, Any}
# This delegates to internal dispatch methods
function _parse_split(p::Pair{<:Union{Function, Type}})
    accessor = first(p)
    dest_spec = last(p)
    return _parse_split_internal(accessor, dest_spec)
end

# Internal dispatch for split parsing
_parse_split_internal(accessor, dest::Union{Int, Symbol}) =
    AggregationOutput(accessor, dest, nothing, nothing)

function _parse_split_internal(accessor, dest_spec::Pair)
    output = _parse_output_spec(dest_spec)
    return AggregationOutput(accessor, output.destination, output.label, output.scaleid)
end

# Helper to parse aggregation spec: just a function
_parse_agg_spec(target, f::Base.Callable) =
    ParsedAggregation(target, f, [AggregationOutput(nothing, target, nothing, nothing)])

# Helper to parse the splits/label part of function => splits_or_label
_parse_outputs(target, aggfunc, splits::AbstractVector) =
    ParsedAggregation(target, aggfunc, map(_parse_split, splits))

# When the third element is an Int or Symbol, treat it as a destination
function _parse_outputs(target, aggfunc, dest::Union{Int, Symbol})
    return ParsedAggregation(target, aggfunc, [AggregationOutput(nothing, dest, nothing, nothing)])
end

# Otherwise it's a label and/or scale_id
function _parse_outputs(target, aggfunc, label_and_or_scale)
    label, scaleid = _parse_label_and_scale(label_and_or_scale)
    return ParsedAggregation(target, aggfunc, [AggregationOutput(nothing, target, label, scaleid)])
end

# Helper to parse aggregation spec: function => something
function _parse_agg_spec(target, p::Pair{<:Base.Callable})
    aggfunc = first(p)
    outputs_spec = last(p)
    return _parse_outputs(target, aggfunc, outputs_spec)
end

"""
    aggregate(aggregations...; named_aggregations...)

Perform flexible aggregation of data. Specify which columns to aggregate explicitly;
all other mapped columns are automatically used for grouping.

# Arguments
- Positional arguments are aggregation specifications in the form:
  - `target => aggfunc` where target is an Int (positional) or Symbol (named)
  - `target => aggfunc => dest` to place output at a different position
  - `target => aggfunc => [accessor => dest, ...]` to split aggregation results
- Named arguments are aggregation functions for named mappings (e.g., `color = mean`)

# Labeling and Custom Scales
You can customize labels and assign outputs to custom scales:
- `target => aggfunc => label` - Set a custom label (if label is not an Int/Symbol)
- `target => aggfunc => label => scale(:scaleid)` - Set label and assign to a custom scale
- For split outputs: `accessor => dest => label` or `accessor => dest => label => scale(:scaleid)`

# Examples

```julia
# Aggregate y values (position 2), group by x (position 1)
data(...) * mapping(:time, :value) * 
    aggregate(2 => median)

# Aggregate and place in different position
data(...) * mapping(:time, :value) *
    aggregate(2 => mean, 2 => std => 3) *
    visual(Errorbars)

# Aggregate x values (position 1), group by y (position 2)
data(...) * mapping(:value, :time) * 
    aggregate(1 => mean)

# Multiple aggregations with named argument
data(...) * mapping(:time, :value, color=:group) * 
    aggregate(2 => mean, color = length)

# Group by multiple dimensions (x and y), aggregate z
data(...) * mapping(:x, :y, :z) * 
    aggregate(3 => mean)

# Split extrema into separate positions for range bars
data(...) * mapping(:x, :y) * 
    aggregate(2 => extrema => [first => 2, last => 3]) *
    visual(Rangebars)

# Aggregate multiple columns
data(...) * mapping(:x, :y1, :y2) *
    aggregate(2 => mean, 3 => median)

# Custom labels
data(...) * mapping(:x, :y) *
    aggregate(2 => mean => "Average Y")

# Custom labels with LaTeX
data(...) * mapping(:x, :y) *
    aggregate(2 => mean => L"\\bar{y}")

# Split outputs with custom labels and scale
data(...) * mapping(:x, :y) *
    aggregate(
        2 => extrema => [
            first => 2 => "Minimum",
            last => :color => "Maximum" => scale(:color2)
        ]
    ) *
    visual(Scatter) |>
    draw(scales(color2 = (; colormap = :thermal)))

# Custom scale for aggregated output
data(...) * mapping(:x, :y, :z) *
    aggregate(3 => sum => "Total" => scale(:mycolor)) *
    visual(Heatmap) |>
    draw(scales(mycolor = (; colormap = :viridis)))
```
"""
function aggregate(args...; named_aggs...)
    # All arguments should be aggregation specifications (target => aggfunc)
    aggregations = Pair[]

    for arg in args
        # arg should be a Pair with target => aggfunc
        if !(arg isa Pair)
            throw(ArgumentError("Each positional argument to aggregate must be a Pair like `target => aggfunc`, got $(typeof(arg))"))
        end
        push!(aggregations, arg)
    end

    # Add named aggregations
    for (name, aggfunc) in pairs(named_aggs)
        push!(aggregations, name => aggfunc)
    end

    # No explicit groupby needed - it will be inferred from what's not aggregated
    return transformation(AggregateAnalysis(Tuple(aggregations), nothing))
end

function (a::AggregateAnalysis)(input::ProcessedLayer)
    N = length(input.positional)

    # Collect all targets being aggregated
    aggregated_targets = Set{Union{Int, Symbol}}()
    for (target, _) in a.aggregations
        push!(aggregated_targets, target)
    end

    # Infer grouping columns: all positional indices not being aggregated
    grouping_indices = Int[]
    for i in 1:N
        if !(i in aggregated_targets)
            push!(grouping_indices, i)
        end
    end

    # Also auto-group by named arguments that aren't being aggregated
    grouping_names = Symbol[]
    for key in keys(input.named)
        if !(key in aggregated_targets)
            push!(grouping_names, key)
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
        # Include both positional and named grouping columns
        positional_keys = Tuple(p[idx] for idx in grouping_indices)
        named_keys = Tuple(n[name] for name in grouping_names)
        grouping_key_columns = (positional_keys..., named_keys...)

        # Handle case where there are no grouping columns (single group)
        perm, group_perm, actual_keys = if isempty(grouping_key_columns)
            # No grouping - treat all data as a single group
            # Get number of rows from first positional column
            n_rows = length(first(p))
            # Create identity permutation and a single group containing all indices
            perm = 1:n_rows
            # GroupPerm expects a vector of index ranges for each group
            # For a single group with all rows, that's just [1:n_rows]
            group_ranges = [1:n_rows]
            actual_keys = [()]  # Single empty key tuple
            (perm, group_ranges, actual_keys)
        else
            sa = StructArray(map(fast_hashed, grouping_key_columns))
            perm = sortperm(sa)
            group_perm = GroupPerm(sa, perm)

            # Extract actual keys that exist in the data (unhashed)
            actual_keys = map(group_perm) do idxs
                idx = perm[first(idxs)]
                # Extract the unhashed key values for this group
                return map(k -> k[idx], grouping_key_columns)
            end
            (perm, group_perm, actual_keys)
        end

        # Build output dictionary - will contain all results indexed by position or symbol
        outputs = Dict{Union{Int, Symbol}, Any}()

        # Process all aggregations first to determine if we need to expand groups
        aggregation_results = Dict{Union{Int, Symbol}, Any}()
        targets = Dict{Union{Int, Symbol}, Union{Int, Symbol}}()

        for parsed in parsed_aggregations
            target = parsed.target
            aggfunc = parsed.aggfunc

            # Validate target and extract target values
            if target isa Integer
                if target < 1 || target > N
                    throw(ArgumentError("aggregation target $target out of bounds for $N positional arguments"))
                end
                if target in grouping_indices
                    throw(ArgumentError("cannot aggregate positional argument $target which is used for grouping"))
                end
                target_values = p[target]
            elseif target isa Symbol
                if !haskey(n, target)
                    throw(ArgumentError("aggregation target :$target not found in named arguments"))
                end
                if target in grouping_names
                    throw(ArgumentError("cannot aggregate named argument :$target which is used for grouping"))
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

                if haskey(aggregation_results, destination)
                    throw(ArgumentError("output position $destination already assigned"))
                end

                # Apply accessor if present, otherwise use result as-is
                final_result = if output.accessor !== nothing
                    map(output.accessor, result)
                else
                    result
                end

                aggregation_results[destination] = final_result
                targets[destination] = target
            end
        end

        # Detect which results are vector-valued and determine group lengths
        # Check the element type of the result vectors
        vector_valued_results = Dict{Union{Int, Symbol}, Bool}()
        for (destination, result) in aggregation_results
            # Check if the element type is a subtype of AbstractVector
            element_type = eltype(result)
            if element_type <: AbstractArray && !(element_type <: AbstractVector)
                target = targets[destination]
                dims = size(first(result))

                # Build descriptive error message with column description
                target_desc = if target isa Integer
                    "positional argument $target"
                else
                    "argument :$target"
                end

                throw(ArgumentError("Aggregation of $target_desc returned $(length(dims))-dimensional arrays with size $dims. Only scalars or 1-dimensional vectors are supported."))
            end
            vector_valued_results[destination] = element_type <: AbstractVector
        end

        # Check if we have any vector results
        has_vector_results = any(values(vector_valued_results))

        if has_vector_results
            # Vector-valued aggregation: determine lengths and validate consistency
            # Compute the length of each group's result vector from vector-valued results
            group_lengths = map(enumerate(actual_keys)) do (group_idx, key)
                lengths_this_group = Int[]
                for (destination, result) in aggregation_results
                    if vector_valued_results[destination] && !isempty(result)
                        push!(lengths_this_group, length(result[group_idx]))
                    end
                end

                # Validate that all vector results for this group have the same length
                if !isempty(lengths_this_group) && !allequal(lengths_this_group)
                    vector_dests_lengths = [
                        (d, length(aggregation_results[d][group_idx]))
                            for (d, is_vec) in vector_valued_results
                            if is_vec
                    ]
                    throw(ArgumentError("Inconsistent vector lengths for group at index $group_idx (key=$(key)): $vector_dests_lengths. All vector-valued aggregations must return the same length for each group."))
                end

                return isempty(lengths_this_group) ? 0 : first(lengths_this_group)
            end

            # Expand grouping columns by repeating keys according to their result lengths
            # Handle positional grouping columns
            for (i, group_idx) in enumerate(grouping_indices)
                expanded = mapreduce(vcat, enumerate(actual_keys)) do (gi, key)
                    fill(key[i], group_lengths[gi])
                end
                outputs[group_idx] = expanded
            end

            # Handle named grouping columns
            num_positional_groups = length(grouping_indices)
            for (i, group_name) in enumerate(grouping_names)
                key_idx = num_positional_groups + i
                expanded = mapreduce(vcat, enumerate(actual_keys)) do (gi, key)
                    fill(key[key_idx], group_lengths[gi])
                end
                outputs[group_name] = expanded
            end

            # Process all aggregation results: concatenate vectors, expand scalars
            for (destination, result) in aggregation_results
                if vector_valued_results[destination]
                    # Vector result: concatenate
                    concatenated = mapreduce(vcat, result) do val
                        val
                    end
                    outputs[destination] = concatenated
                else
                    # Scalar result: expand to match group lengths
                    total_length = sum(group_lengths)
                    expanded = similar(result, total_length)
                    offset = 1
                    for (gi, val) in enumerate(result)
                        len = group_lengths[gi]
                        fill!(view(expanded, offset:(offset + len - 1)), val)
                        offset += len
                    end
                    outputs[destination] = expanded
                end
            end
        else
            # Scalar aggregation: use keys directly
            # Handle positional grouping columns
            for (i, group_idx) in enumerate(grouping_indices)
                outputs[group_idx] = [key[i] for key in actual_keys]
            end

            # Handle named grouping columns
            num_positional_groups = length(grouping_indices)
            for (i, group_name) in enumerate(grouping_names)
                key_idx = num_positional_groups + i
                outputs[group_name] = [key[key_idx] for key in actual_keys]
            end

            # Use aggregation results as-is
            for (destination, result) in aggregation_results
                outputs[destination] = result
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

    # Apply labels to the output
    labels = set(output.labels, (k => v for (k, v) in output_labels)...)

    # Merge scale_mapping with existing scale_mapping from output
    merged_scale_mapping = merge(output.scale_mapping, scale_mapping)

    return ProcessedLayer(output; labels, scale_mapping = merged_scale_mapping)
end
