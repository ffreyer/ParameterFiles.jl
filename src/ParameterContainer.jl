mutable struct ParameterContainer
    param::Dict{Symbol, AbstractParameter}
    Ndims::Int
    N::Int
    dim_length::Vector{Int}
    dim_vars::Vector{Vector{Symbol}}
    cdl::Vector{Int}
end


"""
    ParameterContainer(parameters)

Returns the total (cummulative) number of parameters `N` and a function that
provides a mapping from a linear index `n` (1 ≤ n ≤ N) and a given `dim` to
the correct index of `parameter.value`.
"""
function ParameterContainer(param::Dict{Symbol, <:Any})
    ParameterContainer(promote!(param))
end
function ParameterContainer(param::Dict{Symbol, AbstractParameter})
    dim_lengths = Dict{Int64, Int64}()
    dim_vars = Dict{Int64, Vector{Symbol}}()
    min_N = 0

    for (key, value) in param
        if value isa DerivedParameter
            # DerivedParameter's are not handled here
        elseif value.dim == 0
            (min_N == 0) && (min_N = 1)
        elseif value.dim == -1
            if (min_N == 0) || (min_N ==1)
                min_N = length(value.value)
            else
                small, large = minmax(min_N, length(value.value))
                @assert(
                    (large/small ≈ div(large, small)),
                    "The size of `dim = -1` Parameters does not match " *
                    "($small, $large)"
                )
                min_N = large
            end
        else
            if !haskey(dim_lengths, value.dim) && (value.dim != 0)
                # Generate new entry if a new (nonezero) dim is found
                push!(dim_lengths, value.dim => length(value.value))
                push!(dim_vars, value.dim => [key])
            elseif haskey(dim_lengths, value.dim)
                # Add a new key if dim already exists
                @assert(
                    dim_lengths[value.dim] == length(value.value),
                    "Length mismatch on dim $(value.dim) for $key"
                )
                push!(dim_vars[value.dim], key)
            end
        end
    end

    # Check stuff
    Ndims = length(dim_lengths)
    @assert(
        Ndims == 0 || any(i -> haskey(dim_lengths, i), 1:Ndims),
        "Some dim is skipped. Check Parameter(..., dim) for jumps!"
    )
    @assert(
        Ndims == 0 || any(p -> p[1] <= Ndims, dim_lengths),
        "Empty dims not allowed"
    )

    # Recast to arrays
    dim_lengths = [dim_lengths[i] for i in 1:Ndims]
    dim_vars = [dim_vars[i] for i in 1:Ndims]

    # cummulative dim lengths
    if Ndims == 0
        cdl = Int64[min_N]; N = min_N
    else
        cdl = [reduce(*, dim_lengths[1:i-1], init=1) for i in 1:Ndims]
        N = reduce(*, dim_lengths, init=1)
    end

    ParameterContainer(
        param,
        Ndims,
        N,
        dim_lengths,
        dim_vars,
        cdl
    )
end



"""
    get_value_index(p::ParameterContainer, linear_index, dim)

- `linear_index` is the flattened index for a parameter file, i.e.
`1 ≤ linear_index ≤ p.N` where `N` is the number of parameter sets that are
generated.
- `dim` is the `dim ≠ 0` of the current `Parameter` of interest
- The output is the index that should be used on `parameter.values` to generate
the correct parameter set.
"""
function get_value_index(p::ParameterContainer, linear_index::Int, dim::Int)
    div(linear_index-1, p.cdl[dim]) % p.dim_length[dim] + 1
end
function get_value_index(p::ParameterContainer, linear_index::Int, key::Symbol)
    get_value_index(p::ParameterContainer, linear_index::Int, p.param[key].dim)
end


################################################################################
### Iterator Interface
################################################################################

isconstant(pc::ParameterContainer, key::Symbol) = isconstant(pc.param[key])
Base.isempty(p::ParameterContainer) = p.N == 0


function _get_parameter_tuple(
        pc::ParameterContainer, key::Symbol, p::Parameter, idx::Int
    )
    if p.dim == -1
        return (key, p.type_tag, p.value[idx])
    elseif p.dim == 0
        return (key, p.type_tag, p.value)
    elseif p.dim > 0
        return (key, p.type_tag, p.value[get_value_index(pc, idx, p.dim)])
    else
        throw(ErrorException("Dimension $(p.dim) for key $key cannot be parsed."))
    end
end
function _get_parameter_tuple(
        pc::ParameterContainer, key::Symbol, p::Parameter, idxs::AbstractArray
    )
    if p.dim == -1
        return (key, p.type_tag, p.value[idxs])
    elseif p.dim == 0
        return (key, p.type_tag, p.value)
    elseif p.dim > 0
        js = map(idx -> get_value_index(pc, idx, p.dim), idxs)
        return (key, p.type_tag, p.value[js])
    else
        throw(ErrorException("Dimension $(p.dim) for key $key cannot be parsed."))
    end
end

function _get_parameter_tuple(
        pc::ParameterContainer, key::Symbol, p::DerivedParameter, idx::Int
    )
    input_values = map(p.keys) do k
        last(_get_parameter_tuple(pc, k, pc.param[k], idx))
    end
    value = p.func(map(last, input_values)...)
    (key, typeof(value), value)
end
function _get_parameter_tuple(
        pc::ParameterContainer, key::Symbol, p::DerivedParameter,
        idxs::AbstractArray
    )
    input_values = map(p.keys) do k
        last(_get_parameter_tuple(pc, k, pc.param[k], idxs))
    end
    value = p.func.(input_values...)
    (key, eltype(value), value)
end

# Maybe a bit missnamed...
# This returns a parameter set for a given index idx, if idx is an Integer, i.e.
# (key, type, value) for each paramater at idx
# OR
# (key, type, value[idx[1]] ... value[idx[end]])
# if idx is an array of indices
function _get_parameter_set(p::ParameterContainer, idx)
    [_get_parameter_tuple(p, k, v, idx) for (k, v) in p.param]
end

function Base.iterate(p::ParameterContainer)
    isempty(p) && return nothing
    (_get_parameter_set(p, 1), 2)
end
function Base.iterate(p::ParameterContainer, idx::Int)
    if idx <= p.N
        return (_get_parameter_set(p, idx), idx+1)
    else
        return nothing
    end
end
Base.length(p::ParameterContainer) = p.N


"""
    generate_names!(p::ParameterContainer[; kwargs...])

Generates a (unique) filename for each parameter set and adds them to the
ParameterContainer. By default, filenames are pushed with key `:filename`.

Keyword Arguments:
- `key = :filename`: The key to use for the generated filenames.
- `skip_keys = Symbol[]`: A list of keys to skip when generating a filename.
- `key_maps = Dict{Symbol, Function}()`: This kwarg can be used to specify name
generating functions `f(key, parameter.value)` for specific Parameter `key`s.
- `max_length = 30`: Each parameter (that isn't skipped) generates a string that
will later be combined to give a filename. This is the maximum length of one
such string.
- `delim = "_"`: The seperator by which the generated strings are combined
"""
function generate_names!(p::ParameterContainer; key = :filename, kwargs...)
    @assert !haskey(p.param, key)
    push!(
        p.param,
        key => Parameter([generate_name(p, i; kwargs...) for i in 1:p.N], -1)
    )
end
function generate_names(p::ParameterContainer; kwargs...)
    [generate_name(p, i; kwargs...) for i in 1:p.N]
end



"""
    generate_name(p::ParameterContainer, linear_index)

Generates a name based on each parameter with `dim > 0` for the given
`linear_index`.

Keyword Arguments:
- `skip_keys = Symbol[]`: A list of keys to skip when generating a name-pieces.
- `key_maps = Dict{Symbol, Function}()`: This kwarg can be used to specify name
generating functions `f(key, parameter.value)` for specific `key`s.
- `max_length = 30`: The maximum length for each name-piece.
- `delim = "_"`: The seperator by which name-pieces are to be combined.
"""
function generate_name(
        p::ParameterContainer, index::Int64;
        skip_keys=Symbol[],
        key_maps=Dict{Symbol, Function}(),
        max_length = 30,
        delim = "_"
    )
    pieces = String[]
    for ks in p.dim_vars
        for k in ks
            k in skip_keys && continue
            idx = get_value_index(p, index, k)
            if haskey(key_maps, k)
                name = key_maps[k](k, p.param[k].value[idx])
            else
                name = default_name(k, p.param[k].value[idx])
            end
            length(name) > max_length && (name = name[1:30])
            push!(pieces, name)
        end
    end
    join(pieces, delim)
end

default_name(k, v) = "$(k)_$v"
_default_name(v::String) = string(v)
_default_name(v::Real) = @sprintf("%s_%0.3f", k, v)
_default_name(v::Complex) = @sprintf("%s_%0.3f+%0.3fi", k, real(v), imag(v))
_default_name(v::Function) = string(v)
_default_name(v::Array) = mapreduce(_default_name, (a, b) -> "$(a)_$b", v)
_default_name(v::Tuple) = mapreduce(_default_name, (a, b) -> "$(a)_$b", v)


################################################################################
### show
################################################################################

function Base.show(io::IO, ::MIME"text/plain", p::ParameterContainer)
    print(io,
        "ParameterContainer(", p.N, " Sets of ",
        length(p.param), " Parameters each)"
    )
end
function Base.show(io::IO, p::ParameterContainer)
    print(io,
        "ParameterContainer(", p.N, " Sets of ",
        length(p.param), " Parameters each)\n"
    )
    for (i, parameters) in enumerate(p)
        println(
            io, "\t", i, "\t [",
            join((":$k => $v" for (k, _, v) in parameters), ", "), "]"
        )
    end
end
