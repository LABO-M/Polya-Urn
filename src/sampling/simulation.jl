module Simulation

using Random, ProgressMeter, LinearAlgebra
using Distributed, SharedArrays, Statistics


# Decision function f(z)
function decision_function(z::Float64, p::Float64, q::Float64)::Float64
    return (1 - p) * q + p * z
end

function simulate(T::Int, p::Float64, q::Float64, progressBar::Progress)::Matrix{Float64}
    Sum_of_zr_t_X1 = zeros(Float64, T, 2)

    X = zeros(Int, T)
    S = zeros(Float64, T)
    Z = zeros(Float64, T)
    for x1 in 0:1
        next!(progressBar)
        X[1] = x1
        S[1] = X[1]
        Z[1] = S[1]
        for t in 2:T
            X[t] = rand(Float64) < decision_function(Z[t-1], p, q)
            S[t] = S[t-1] + X[t]
            Z[t] = S[t] / t
        end
        Sum_of_zr_t_X1[:, x1+1] += Z
    end
    return Sum_of_zr_t_X1
end

function simulate_samples(Sample::Int, T::Int, p::Float64, q::Float64, alpha::Float64)::Vector{Float64}
    # Initialize a SharedArray for storing results
    Sum_of_zr_t_X1_samples = SharedArray{Float64}(T, 2, Sample)

    progressBar = Progress(Sample * 2, 1, "Samples: ")
    ProgressMeter.update!(progressBar, 0)

    # Parallelize the simulation across the specified number of samples
    @sync @distributed for i in 1:Sample
        Sum_of_zr_t_X1_samples[:, :, i] = simulate(T, p, q, progressBar)
    end

    println("Finished sampling")

    # Calculate mean and standard deviation values for Ct values
    total_Sum_of_zr_t_X1 = sum(Sum_of_zr_t_X1_samples, dims=3)[:,:,1]
    Ct = (total_Sum_of_zr_t_X1[:, 2] .- total_Sum_of_zr_t_X1[:, 1]) ./ Sample

    return Ct
end

end
