# Templating
# do string interpolation at a later point - in a function call. This allows
# strings to be used as a templates.


# State Machine Time \o/
# Based on https://www.youtube.com/watch?v=WGT9_cEImAk
abstract type StringStateMachine end
abstract type StringState <: StringStateMachine end

struct NormalState <: StringState end
struct IgnoreState <: StringState end
struct InterpolationStartState <: StringState end
struct InterpolationDoneState <: StringState end
struct WordMatchState <: StringState end
mutable struct BracketMatchState <: StringState
    brackets_open::Int64
end

step(state::NormalState, ::Val{C}) where {C} = state
step(::NormalState, ::Val{'\\'}) = IgnoreState()
step(::NormalState, ::Val{'$'}) = InterpolationStartState()

step(::IgnoreState, ::Any) = NormalState()

step(::InterpolationStartState, ::Val{'('}) = BracketMatchState(1)
function step(state::InterpolationStartState, ::Val{C}) where {C}
    isletter(C) && return WordMatchState()
    error("Invalid character '$C' following InterpolationStartState.")
end

step(state::BracketMatchState, ::Val{C}) where {C} = state
step(state::BracketMatchState, ::Val{'('}) = state.brackets_open += 1
function step(state::BracketMatchState, ::Val{')'})
    state.brackets_open -= 1
    state.brackets_open == 0 && return InterpolationDoneState()
    state
end

function step(state::WordMatchState, ::Val{C}) where {C}
    (isnumeric(C) || isletter(C) || (C in "_!")) && return state
    InterpolationDoneState()
end

step(::InterpolationDoneState, ::Any) = NormalState()


"""
    rpad(string, N)

Pads a `string` with ' ' to the right, such that it reaches a length `N`. If the
`string` is already that long or longer, returns the string.
"""
rpad(s, N) = length(s) < N ? s * " "^(N - length(s)) : s


"""
    resolve(string[, debug=false; kwargs...])

Interpolates values (and calculations) after `\$` in a given string, much like
usual string interpolation. Any key-value pair passed through `kwargs` is made
available in the local scope of the `interpolate` and is therefore available
for string interpolation.

The idea is to prepare a string and interpolate values later using this
function. For example:

```julia
str = \"\"\"
#!/bin/bash
#
#SBATCH --job-name=\\\$(name)
#SBATCH --output=\\\$(filename)
#
#SBATCH --ntasks=\\\$(N)
#SBATCH --time=\\\$(time)
#SBATCH --mem-per-cpu=100

srun main
\"\"\"
resolve(str, name = "test", filename = "testfile.txt", N = 1, time = "10:00")
```
would finish the string interpolation and return the resulting string.
"""
function resolve(str, debug=false; kwargs...)
    # Make kwargs locally available
    debug && @info "kwargs = $kwargs"
    for (k, v) in kwargs
        debug && @info k, v
        eval(:($k = $v))
    end

    state = NormalState()
    blocks = String[]
    buffer = Char[]
    for (i, c) in enumerate(str)
        debug && print(rpad(string(typeof(state)), 40) * " --($c)--> ")
        state = step(state, Val(c))
        debug && println(typeof(state))
        if state isa InterpolationStartState
            push!(blocks, join(buffer))
            empty!(buffer)
        elseif state isa InterpolationDoneState
            was_bracket_state = buffer[1] == '('
            was_bracket_state && push!(buffer, ')')

            debug && @info buffer
            command = Meta.parse(join(buffer))
            debug && @info command
            value = eval(command)
            push!(blocks, string(value))

            empty!(buffer)
            !was_bracket_state && push!(buffer, ' ')
        elseif state isa IgnoreState
        else # Normal, WordMatch, BracketMatch
            push!(buffer, c)
        end
        debug && println(buffer)
    end
    push!(blocks, join(buffer))
    join(blocks)
end


"""
    generate_file(filename, template[; path="", overwrite=false, kwargs...])

Generates a textfile under `joinpath(path, filename)` from a given `template`.
Note that kwargs should include all the variables necessary for the template.
"""
function generate_file(
        filename::String, template::String;
        path="", overwrite=false, kwargs...
    )

    isdir(path) || mkdir(path)
    isfile(joinpath(path, filename)) && !overwrite && error(
        "File $(joinpath(path, filename)) already exists. Set overwrite = " *
        "true to overwrite it."
    )
    output = resolve(template, kwargs...)
    open(joinpath(path, filename), "w") do file
        write(file, output)
    end
    nothing
end
