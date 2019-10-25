"""
    exp_range(start, stop, N[, power = 3.0])

Provides `N` values between `start` and `stop` which are distributed
exponentially. With increasing `power > 0` the values become increasingly dense
around `start`. Note that both `start < stop` and `start > stop` are valid.

Example:
```julia
julia> UnicodePlots.histogram(exp_range(0.3, 1.5, 1000))
   [0.3, 0.4) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 161
   [0.4, 0.5) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 132
   [0.5, 0.6) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 111
   [0.6, 0.7) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 96
   [0.7, 0.8) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 85
   [0.8, 0.9) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 76
   [0.9, 1.0) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 68
   [1.0, 1.1) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 63
   [1.1, 1.2) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇ 58
   [1.2, 1.3) ┤▇▇▇▇▇▇▇▇▇▇▇▇ 53
   [1.3, 1.4) ┤▇▇▇▇▇▇▇▇▇▇▇ 50
   [1.4, 1.5) ┤▇▇▇▇▇▇▇▇▇▇ 46
   [1.5, 1.6) ┤ 1
                              Frequency
```
"""
function exp_range(T0, T1, N, power=3.0)
    (T1-T0) * (
        exp.(range(0., stop=log(power + 1.), length=N)) .- 1.
    ) / power .+ T0
end


"""
    focused_exp_range(start, focus, stop, N[, power=3.0])

Merges two `exp_range`s such that points are most dense around `focus`.

Example:
```julia
julia> UnicodePlots.histogram(focused_exp_range(0.3, 0.6, 1.5, 1000))
   [0.3, 0.4) ┤▇▇▇▇▇▇▇▇▇▇▇▇ 52
   [0.4, 0.5) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 73
   [0.5, 0.6) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 125
   [0.6, 0.7) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 156
   [0.7, 0.8) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 120
   [0.8, 0.9) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 99
   [0.9, 1.0) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 83
   [1.0, 1.1) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 72
   [1.1, 1.2) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 64
   [1.2, 1.3) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇ 57
   [1.3, 1.4) ┤▇▇▇▇▇▇▇▇▇▇▇ 51
   [1.4, 1.5) ┤▇▇▇▇▇▇▇▇▇▇▇ 47
   [1.5, 1.6) ┤ 1
                              Frequency
```
"""
function focused_exp_range(T0, TC, T1, N, power=3.0)
    Nleft = round(Int64, (TC - T0) / (T1 - T0) * N)
    left = exp_range(TC, T0, Nleft + 1, power)
    right = exp_range(TC, T1, N - Nleft, power)
    [left[end:-1:2]..., right...]
end



mutable struct IndexTimePair
    idxs::Vector{Int}
    time::Float64
end
Base.isless(x::IndexTimePair, y::IndexTimePair) = x.time < y.time

"""
    bundle_parameters(
        p::ParameterContainer,
        runtime_estimation::Function,
        target_runtime,
        chunk_size
    )

Attempts to bundle sets of parameters in the given `ParameterContainer` such
that each process takes roughly the same time ≤ `target_runtime`.

For example, let's assume the `ParameterContainer` holds 30 parameters sets, of
which 20 take one unit of time and 10 take two units of time. Let's further
assume the cluster only allows us to use full nodes, each containing 10 CPU's,
and that we may only use them for at most 2.5 units of time.
Here we would use `bundle_parameters(p, estimator, 2.5, 10)` to bundle
parameters, where `estimator` is a function estimating the runtime of each
parameter set. This should return an array with 20 elements - the first 10
including indices for two short simulation, the latter 10 one index for each
long simulation.
"""
function bundle_parameters(
        p::ParameterContainer,
        runtime_estimation::Function,
        target_runtime::Real,
        chunk_size::Int
    )

    times = map(p) do parameters
        d = Dict((k => p for (k, _, p) in parameters))
        runtime_estimation(; d...)
    end
    maximum(times) > target_runtime && @warn(
        "The estimated runtime exceeds the target for atleast one parameter " *
        "set. ($(maximum(times)) > $target_runtime)"
    )
    total_time = sum(min.(target_runtime, times))
    n_chunks = ceil(Int64, total_time / (chunk_size * target_runtime))
    idxs = sortperm(times)

    @label retry_label
    jobs = map((length(times) - chunk_size * n_chunks + 1) : length(times)) do i
        IndexTimePair([idxs[i]], times[i])
    end
    heapify!(jobs)

    # Itertate: long jobs .. short jobs
    for idx in reverse(idxs[1 : end - chunk_size * n_chunks])
        # get fastest job
        job = heappop!(jobs)
        # try to add time
        if job.time + times[idx] < target_runtime
            job.time += times[idx]
            push!(job.idxs, idx)
            heappush!(jobs, job)
        else
            # try again with more chunks
            n_chunks += 1
            @goto retry_label
        end
    end

    return [job.idxs for job in jobs], [job.time for job in jobs]
end





################################################################################
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
