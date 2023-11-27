module Simulation

using Random, ProgressMeter, Statistics

# Decision function f(z)
function decision_function(z::AbstractArray, p::Float64, q::Float64)::AbstractArray
    return (1 - p) .* q .+ p .* z
end

# alpha = 0.0
function simulate(T::Int, t0::Int, p::Float64, q::Float64, sample::Int)::Vector{Float64}
    # Array to store X values for each initial value of x1
    X_by_x1 = zeros(Int, T, sample, 2)

    decay_factor = exp(-1.0 / t0)

    progressBar = Progress((T - t0) * 2, 1)

    for x1 in 0:1
        # Initialize arrays
        X = fill(x1, T, sample)
        S = fill(float(x1), T, sample)
        D = ones(Float64, T, sample)
        Z = fill(float(x1), T, sample)
        next!(progressBar)

        for t in t0+1:T
            # X(t) based on the previous Z(t-1)
            decisions = decision_function(Z[t-1, :], p, q)
            X[t, :] .= rand(sample) .< decisions

            # Update S(t) and D(t) based on the decay rates
            S[t, :] = S[t-1, :] .* decay_factor + X[t, :]
            D[t, :] = D[t-1, :] .* decay_factor .+ 1.0
            Z[t, :] = S[t, :] ./ D[t, :]
            next!(progressBar)
        end

        X_by_x1[:, :, x1+1] = X
    end

    # Calculate Ct
    Ct = mean(X_by_x1[:, :, 2] - X_by_x1[:, :, 1], dims=2)[:, 1]

    return Ct
end

# alpha > 0.0
function simulate(T::Int, t0::Int, p::Float64, q::Float64, alpha::Float64, sample::Int)::Vector{Float64}
    # Array to store X values for each initial value of x1
    X_by_x1 = zeros(Int, T, sample, 2)

    # Calculate the decay factors for each time step
    max_decay_factors = [exp.(-((t-1:-1:0) ./ t^alpha)) for t in 1:T]

    progressBar = Progress((T - t0) * 2, 1)

    for x1 in 0:1
        # Initialize arrays
        X = fill(x1, T, sample)
        S = fill(float(x1), T, sample)
        D = ones(Float64, T, sample)
        Z = fill(float(x1), T, sample)
        next!(progressBar)

        for t in t0+1:T
            # X(t) based on the previous Z(t-1)
            decisions = decision_function(Z[t-1, :], p, q)
            X[t, :] .= rand(sample) .< decisions

            # Update S(t) and D(t) based on the decay rates
            decay_factors = max_decay_factors[t]
            S[t, :] = sum(X[1:t, :] .* repeat(decay_factors, 1, sample), dims=1)
            D[t, :] .= sum(decay_factors)
            Z[t, :] .= S[t, :] ./ D[t, :]
            next!(progressBar)
        end

        X_by_x1[:, :, x1+1] .= X
    end

    # Calculate Ct
    Ct = mean(X_by_x1[:, :, 2] - X_by_x1[:, :, 1], dims=2)[:, 1]

    return Ct
end

end
