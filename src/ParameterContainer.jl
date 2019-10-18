mutable struct ParameterContainer
    param::Dict{Symbol, Parameter}
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
function ParameterContainer(param::Dict{Symbol, Any})
    ParameterContainer(promote!(param))
end
function ParameterContainer(param::Dict{Symbol, Parameter})
    dim_lengths = Dict{Int64, Int64}()
    dim_vars = Dict{Int64, Vector{Symbol}}()

    for (key, value) in param
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
        cdl = [1]; N = 1
    else
        cdl = [reduce(*, dim_lengths[1:i-1], init=1) for i in 1:Ndims]
        N = reduce(*, dim_lengths, init=1)
    end
    println("Making $N parameter files")

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
    get_value_index(p::ParameterContainer, linear_index::Int, p.param[k].dim)
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
    for ks in p.dimvars
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
