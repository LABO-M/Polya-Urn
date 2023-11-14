module Simulation

using Random, ProgressMeter, LinearAlgebra
using Distributed, SharedArrays, Statistics


# Decision function f(z)
function decision_function(z::AbstractArray, p::Float64, q::Float64)::AbstractArray
    return (1 - p) .* q .+ p .* z
end

function simulate(T::Int, p::Float64, q::Float64, sample::Int)::Vector{Float64}
    # Array to store Z values for each initial value of x1
    Z_by_x1 = zeros(Float64, T, sample, 2)

    progressBar = Progress(T * 2, 1)


    for x1 in 0:1
        # Initialize arrays
        X = fill(x1, T, sample)
        S = fill(float(x1), T, sample)
        Z = fill(float(x1), T, sample)
        next!(progressBar)

        for t in 2:T
            decisions = decision_function(Z[t-1, :], p, q)
            X[t, :] .= rand(sample) .< decisions
            S[t, :] = S[t-1, :] .+ X[t, :]
            Z[t, :] = S[t, :] ./ t
            next!(progressBar)
        end

        Z_by_x1[:, :, x1+1] = Z
    end

    # Calculate Ct
    Ct = mean(Z_by_x1[:, :, 2] - Z_by_x1[:, :, 1], dims=2)[:, 1]

    return Ct
end

function simulate(T::Int, p::Float64, q::Float64, r0::Int, sample::Int)::Vector{Float64}
    # Array to store Z values for each initial value of x1
    Z_by_x1 = zeros(Float64, T, sample, 2)

    exp_val = exp(-1/r0)

    progressBar = Progress(T * 2, 1)

    for x1 in 0:1
        # Initialize arrays
        X = fill(x1, T, sample)
        S = fill(float(x1), T, sample)
        D = ones(Float64, T, sample)
        Z = fill(float(x1), T, sample)
        next!(progressBar)

        for t in 2:T
            decisions = decision_function(Z[t-1, :], p, q)
            rand_vals = rand(sample)
            X[t, :] .= rand_vals .< decisions
            S[t, :] = S[t-1, :] .* exp_val + X[t, :]
            D[t, :] = D[t-1, :] .* exp_val .+ 1.0
            Z[t, :] = S[t, :] ./ D[t, :]
            next!(progressBar)
        end

        Z_by_x1[:, :, x1+1] = Z
    end

    # Calculate Ct
    Ct = mean(Z_by_x1[:, :, 2] - Z_by_x1[:, :, 1], dims=2)[:, 1]

    return Ct
end

function simulate(T::Int, p::Float64, q::Float64, alpha::Float64, sample::Int)::Vector{Float64}
    # Array to store Z values for each initial value of x1
    Z_by_x1 = zeros(Float64, T, sample, 2)

    max_decay_factors = [exp.(-((t-1:-1:0) ./ t^alpha)) for t in 1:T]

    progressBar = Progress(T * 2, 1)

    for x1 in 0:1
        # Initialize arrays
        X = fill(x1, T, sample)
        S = fill(float(x1), T, sample)
        D = ones(Float64, T, sample)
        Z = fill(float(x1), T, sample)
        next!(progressBar)

        for t in 2:T
            decay_factors = max_decay_factors[t]
            decisions = decision_function(Z[t-1, :], p, q)
            X[t, :] .= rand(sample) .< decisions


            # Update S(t) and D(t) based on the decay rates
            S[t, :] = sum(X[1:t, :] .* repeat(decay_factors, 1, sample), dims=1)
            D[t, :] .= sum(decay_factors)
            Z[t, :] .= S[t, :] ./ D[t, :]
            next!(progressBar)
        end

        Z_by_x1[:, :, x1+1] .= Z
    end

    # Calculate Ct
    Ct = mean(Z_by_x1[:, :, 2] - Z_by_x1[:, :, 1], dims=2)[:, 1]

    return Ct
end

end
