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
