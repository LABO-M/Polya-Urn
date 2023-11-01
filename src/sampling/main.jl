using ArgParse
include("simulation.jl")
include("output.jl")

function main(args)
    s = ArgParseSettings()

    @add_arg_table! s begin
        "--T"
        # help = "Total number of time steps"
        default = 10_000
        arg_type = Int
        "--p"
        default = 0.9 # 0.99
        arg_type = Float64
        "--q"
        default = 0.5
        arg_type = Float64
        "--alpha"
        # help = "Exponent parameter alpha"
        default = 1.0
        arg_type = Float64
        "--sample"
        # help = "Sample size"
        default = 10_000
        arg_type = Int
    end

    parsed_args = parse_args(args, s)
    T = parsed_args["T"]
    p = parsed_args["p"]
    q = parsed_args["q"]
    alpha = parsed_args["alpha"]
    sample = parsed_args["sample"]

    # Log the simulation parameters
    println("Running simulation with the following parameters:")
    println("T = $(int_to_SI_prefix(T)), p = $(p), q = $(q), alpha = $(alpha), sample = $(int_to_SI_prefix(sample))")

    # Run the simulation
    # Ct = Simulation.simulate_samples(S, T, p, q, alpha)
    Ct = Simulation.simulate(T, p, q, sample)

    # Output Z values to CSV
    dir = "data/Ct"
    if !isdir(dir)
        mkpath(dir)
    end
    filename = joinpath(dir, "T$(int_to_SI_prefix(T))_p$(p)_q$(q)_alpha$(alpha)_sample$(int_to_SI_prefix(sample)).csv")
    save_to_csv(Ct, filename)
    end

# Entry point of the script
isinteractive() || main(ARGS)
