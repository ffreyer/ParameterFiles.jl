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
