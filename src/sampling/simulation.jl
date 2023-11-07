module Simulation

using Random, ProgressMeter, LinearAlgebra
using Distributed, SharedArrays, Statistics


# Decision function f(z)
function decision_function(z::Float64, p::Float64, q::Float64)::Float64
    return (1 - p) * q + p * z
end

function simulate(T::Int, p::Float64, q::Float64, sample::Int)::Vector{Float64}
    # Array to store Z values for each initial value of x1
    Z_by_x1 = zeros(Float64, T, sample, 2)

    progressBar = Progress(T * 2, 1)

    for x1 in 0:1
        next!(progressBar)
        # Initialize arrays for computation
        X = zeros(Int, T, sample)
        S = zeros(Float64, T, sample)
        Z = zeros(Float64, T, sample)

        # Initial values
        X[1, :] .= x1
        S[1, :] .= x1
        Z[1, :] .= x1

        for t in 2:T
            next!(progressBar)
            decisions = decision_function.(Z[t-1, :], p, q)
            rand_vals = rand.(Float64, sample)
            X[t, :] .= rand_vals .< decisions
            S[t, :] = S[t-1, :] .+ X[t, :]
            Z[t, :] = S[t, :] ./ t
        end

        Z_by_x1[:, :, x1+1] = Z
    end

    # Calculate Ct
    Ct = (mean(Z_by_x1[:, :, 2], dims=2) .- mean(Z_by_x1[:, :, 1], dims=2))[:]

    return Ct
end

function simulate(T::Int, p::Float64, q::Float64, r0::Int, sample::Int)::Vector{Float64}
    # Array to store Z values for each initial value of x1
    Z_by_x1 = zeros(Float64, T, sample, 2)

    exp_val = exp(-1/r0)

    progressBar = Progress(T * 2, 1)

    for x1 in 0:1
        next!(progressBar)
        # Initialize arrays for computation
        X = zeros(Int, T, sample)
        S = zeros(Float64, T, sample)
        D = zeros(Float64, T, sample)
        Z = zeros(Float64, T, sample)

        # Initial values
        X[1, :] .= x1
        S[1, :] .= x1
        D[1, :] .= 1.0
        Z[1, :] .= S[1, :] ./ D[1, :]

        for t in 2:T
            next!(progressBar)
            decisions = decision_function.(Z[t-1, :], p, q)
            rand_vals = rand.(Float64, sample)
            X[t, :] .= rand_vals .< decisions
            S[t, :] = S[t-1, :] .* exp_val + X[t, :]
            D[t, :] = D[t-1, :] .* exp_val .+ 1.0
            Z[t, :] = S[t, :] ./ D[t, :]
        end

        Z_by_x1[:, :, x1+1] = Z
    end

    # Calculate Ct
    Ct = (mean(Z_by_x1[:, :, 2], dims=2) .- mean(Z_by_x1[:, :, 1], dims=2))[:]

    return Ct
end

function simulate(T::Int, p::Float64, q::Float64, r0::Int, alpha::Float64, sample::Int)::Vector{Float64}
    # Array to store Z values for each initial value of x1
    Z_by_x1 = zeros(Float64, T, sample, 2)

    progressBar = Progress(T * 2, 1)

    for x1 in 0:1
        next!(progressBar)
        # Initialize arrays for computation
        X = zeros(Int, T, sample)
        S = zeros(Float64, T, sample)
        D = zeros(Float64, T, sample)
        Z = zeros(Float64, T, sample)

        # Initial values
        X[1, :] .= x1
        S[1, :] .= x1
        D[1, :] .= 1.0
        Z[1, :] .= x1

        prev_r = 1.0

        for t in 2:T
            next!(progressBar)
            r_t = t <= r0 ? t : floor(r0 * (t / r0)^alpha)
            decay_factor = exp(-1/r_t)
            decisions = decision_function.(Z[t-1, :], p, q)
            rand_vals = rand.(Float64, sample)
            X[t, :] .= rand_vals .< decisions

            # Determine if r changed
            delta_r = prev_r != r_t ? 1 : 0

            # If r did not change, use the efficient update
            # For t in 2:r0, update without decay
            if t <= r0
                S[t, :] = S[t-1, :] .+ X[t, :]
                D[t, :] = D[t-1, :] .+ 1.0
                Z[t, :] = S[t, :] ./ D[t, :]
            elseif delta_r == 0
                S[t, :] = S[t-1, :] .* decay_factor + X[t, :]
                D[t, :] = D[t-1, :] .* decay_factor .+ 1.0
            else
                # If r changed, recompute d_r and sums
                d_r = repeat(exp.(-((0:t-1) ./ r_t)), 1, sample)

                # Update S(t) and D(t) based on the decay rates
                S[t, :] .= vec(sum((X[1:t, :] .* d_r), dims=1))
                D[t, :] .= vec(sum(d_r, dims=1))
            end
            Z[t, :] .= S[t, :] ./ D[t, :]
            prev_r = r_t
        end

        Z_by_x1[:, :, x1+1] .= Z
    end

    # Calculate Ct
    Ct = (mean(Z_by_x1[:, :, 2], dims=2) .- mean(Z_by_x1[:, :, 1], dims=2))[:]

    return Ct
end

end
