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
    distribute(parametercontainer, runtime_estimation, N_blocks; kwargs...)

Distribute the parameter sets in `parametercontainer` into `N_blocks`, where
each block takes approximately the same time to run. The `runtime_estimation`
function is used to estimate the run time of each parameter set. It should be
be able to take each parameter as a keyword argument.

#### Keyword Arguments:
- `order = :fast_first`: Ordering of the parameter queue. (:fast_first or :slow_first)


#### Example:

```
julia> pc = ParameterContainer(Dict(:iterations => Parameter(1:10, 1)))
julia> chunks, times = distribute(pc, (; iterations, kwargs...) -> iterations, 3)
([[[10, 5, 3], [9, 6, 4], [8, 7, 2, 1]]], [18.0, 19.0, 18.0])
```
"""
function distribute(
        p::ParameterContainer,
        runtime_estimation::Function,
        N_blocks::Int;
        order=:fast_first
    )

    times = map(p) do parameters
        d = Dict((k => p for (k, _, p) in parameters))
        runtime_estimation(; d...)
    end
    idxs = reverse(sortperm(times))

    @label retry_label
    jobs = [IndexTimePair([i], times[i]) for i in idxs[1:N_blocks]]
    heapify!(jobs)

    # Itertate: long jobs .. short jobs
    for idx in idxs[N_blocks+1:end]
        # get fastest job
        job = heappop!(jobs)
        # add time
        job.time += times[idx]
        push!(job.idxs, idx)
        heappush!(jobs, job)
    end

    if order == :slow_first
        return [[job.idxs for job in jobs]], [[job.time for job in jobs]]
    else
        order != :fast_first && @warn "Assuming order = :fast_first"
        return [[reverse(job.idxs) for job in jobs]], [[job.time for job in jobs]]
    end
end



"""
    distribute(
        p::ParameterContainer,
        runtime_estimation::Function,
        target_runtime,
        N_blocks;
        kwargs...
    )

Distributes parameter sets into `K * N_blocks` such that every block
takes less time than the `target_runtime`. To estimate the time used per
parameter set, the function `runtime_estimation` is queried with parameters as
keywords. If any parameter set exceeds the target_runtime a warning will be
displayed and the parameter set will get its own group.

#### Keyword Arguments:
- `order = :fast_first`: Ordering of the parameter queue. (:fast_first or :slow_first)

#### Example:

julia> pc = ParameterContainer(Dict(:iterations => Parameter(1:10, 1)))
julia> chunks, times = distribute(
    pc,
    (; iterations, kwargs...) -> iterations,
    12,
    3
)
([[[7, 2], [6, 3], [5, 4]], [[10], [9], [8, 1]]], [9.0, 9.0, 9.0, 10.0, 9.0, 9.0])
"""
function distribute(
        p::ParameterContainer,
        runtime_estimation::Function,
        target_runtime::Real,
        chunk_size::Int;
        order = :fast_first
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
    n_chunks = max(1, floor(Int64, total_time / (chunk_size * target_runtime)))
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


    if order == :slow_first
        return (
            [[job.idxs for job in jobs[(i-1)*chunk_size+1 : i*chunk_size]] for i in 1:n_chunks],
            [[job.time for job in jobs[(i-1)*chunk_size+1 : i*chunk_size]] for i in 1:n_chunks],
        )
    else
        order != :fast_first && @warn "Assuming order = :fast_first"
        return [[reverse(job.idxs) for job in jobs]], [[job.time for job in jobs]]
        return (
            [[reverse(job.idxs) for job in jobs[(i-1)*chunk_size+1 : i*chunk_size]] for i in 1:n_chunks],
            [[job.time for job in jobs[(i-1)*chunk_size+1 : i*chunk_size]] for i in 1:n_chunks],
        )
    end

end
