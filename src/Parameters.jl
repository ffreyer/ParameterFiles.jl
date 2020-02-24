# TODO
# do transformations
# e.g. :T => something  -->  :Ts => [something]

abstract type AbstractParameter end

"""
    Parameter(value[, dim=0, type_tag=typeof(value)])

Generates a Parameter with some `value` acting on some `dim`.

When parameter sets are generated Parameters are varied based on their
dimension.

- If `dim = -1` the `Parameter` is assumed to have one value for each parameter
set.
- If `dim = 0` the `Parameter` is viewed as constant.
- If `dim > 0` the `Parameter` is viewed as a collection of values that varies
in one dimension but is repeated in other dimensions.

For example:

```
param = Dict(
    :A => Parameter(1.0, 0),
    :B => Parameter([1.0, 2.0], 1),
    :C => Parameter([0.1, 0.2, 0.3], 2),
    :D => Parameter(1:6, -1),
)
for parameter_set in ParameterContainer(param)
    println(parameter_set)
end
```

Results in the parameter sets

```
[(:A, Float64, 1.0), (:B, Float64, 1.0), (:C, Float64, 0.1), (:D, Int64, 1)]
[(:A, Float64, 1.0), (:B, Float64, 2.0), (:C, Float64, 0.1), (:D, Int64, 2)]
[(:A, Float64, 1.0), (:B, Float64, 1.0), (:C, Float64, 0.2), (:D, Int64, 3)]
[(:A, Float64, 1.0), (:B, Float64, 2.0), (:C, Float64, 0.2), (:D, Int64, 4)]
[(:A, Float64, 1.0), (:B, Float64, 1.0), (:C, Float64, 0.3), (:D, Int64, 5)]
[(:A, Float64, 1.0), (:B, Float64, 2.0), (:C, Float64, 0.3), (:D, Int64, 6)]
```
"""
struct Parameter{T} <: AbstractParameter
    value::T
    dim::Int64
    type_tag::DataType
end
function Parameter(value, dim=0)
    Parameter(value, dim, dim == 0 ? typeof(value) : eltype(value))
end


"""
    DerivedParameter(inputs..., function)

A DerivedParameter is parameter that is derived from other Parameters in the
dictionary.

For example:

```
param = Dict(
    :B => Parameter([1.0, 2.0], 1),
    :C => Parameter([0.1, 0.2, 0.3], 2),
    :E => DerivedParameter(:B, x -> -x)
)
for parameter_set in ParameterContainer(param)
    println(parameter_set)
end
```

Results in the parameter sets

```
[(:B, Float64, 1.0), (:C, Float64, 0.1), (:E, Float64, -1.0)]
[(:B, Float64, 2.0), (:C, Float64, 0.1), (:E, Float64, -2.0)]
[(:B, Float64, 1.0), (:C, Float64, 0.2), (:E, Float64, -1.0)]
[(:B, Float64, 2.0), (:C, Float64, 0.2), (:E, Float64, -2.0)]
[(:B, Float64, 1.0), (:C, Float64, 0.3), (:E, Float64, -1.0)]
[(:B, Float64, 2.0), (:C, Float64, 0.3), (:E, Float64, -2.0)]
```
"""
struct DerivedParameter{N, FT <: Function} <: AbstractParameter
    keys::NTuple{N, Symbol}
    func::FT
end
DerivedParameter(args...) = DerivedParameter(args[1:end-1], args[end])
# DerivedParameter(key::Symbol, func::Function) = DerivedParameter((key,), func)


"""
    promote!(parameters::Dict)

Promotes any `Pair(key, value)` in `parameters`, where `value` is not of type
`Parameter` to a `Pair(key, Parameter(value))`.
"""
function promote!(parameters::Dict{Symbol, <: Any}; aliases=Dict{Symbol, Symbol}())
    ks = keys(parameters)

    # Clean up dims
    dims = filter(
        dim -> dim > 0,
        map(values(parameters)) do v
            if v isa Parameter
                return max(0, v.dim)
            else
                return 0
            end
        end |> unique |> sort
    )

    dimmap = Dict{Int64, Int64}(
        -1 => -1, 0 => 0, (dim => i for (i, dim) in enumerate(dims))...
    )
    for k in ks
        if parameters[k] isa Parameter
            if dimmap[parameters[k].dim] != parameters[k].dim
                parameters[k] = Parameter(
                    parameters[k].value,
                    dimmap[parameters[k].dim],
                    parameters[k].type_tag
                )
            end
        end
    end

    # promote everything else to Parameters
    for k in ks
        if !(parameters[k] isa AbstractParameter)
            if k in keys(aliases)
                new_key = aliases[k]
                parameters[new_key] = Parameter(parameters[k])
                delete!(parameters, k)
            else
                parameters[k] = Parameter(parameters[k])
            end
        end
    end
    convert(Dict{Symbol, AbstractParameter}, parameters)
end


isconstant(p::DerivedParameter) = false
isconstant(p::Parameter) = (p.dim == 0) || (length(p.value) == 1)
