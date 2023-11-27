using ArgParse
include("simulation.jl")
include("output.jl")

function main(args)
    s = ArgParseSettings()

    @add_arg_table! s begin
        "--T"
        help = "Total number of time steps in the simulation."
        default = 1_000
        arg_type = Int

        "--t0"
        help = "Initialization time."
        default = 100
        arg_type = Int

        "--p"
        help = "Influence parameter for the previous ball's color. A higher value indicates a greater impact of the previous outcome on the next outcome."
        default = 0.9
        arg_type = Float64

        "--q"
        help = "Randomness parameter. Represents the base probability of selecting a particular color, irrespective of the urn's current composition."
        default = 0.5
        arg_type = Float64

        "--alpha"
        help = "Decay exponent parameter. Controls the rate at which the impact of past events diminishes over time."
        default = 0.5
        arg_type = Float64

        "--sample"
        help = "Sample size."
        default = 10_000
        arg_type = Int
    end


    parsed_args = parse_args(args, s)
    T = parsed_args["T"]
    t0 = parsed_args["t0"]
    p = parsed_args["p"]
    q = parsed_args["q"]
    alpha = parsed_args["alpha"]
    sample = parsed_args["sample"]

    # Log the simulation parameters
    println("Running simulation with the following parameters:")
    if alpha == 0.0
        println("T = $(int_to_SI_prefix(T)), t0 = $(int_to_SI_prefix(t0)), p = $(p), q = $(q), sample = $(int_to_SI_prefix(sample))")
    else
        println("T = $(int_to_SI_prefix(T)), t0 = $(int_to_SI_prefix(t0)), p = $(p), q = $(q), alpha = $(alpha), sample = $(int_to_SI_prefix(sample))")
    end

    # Run the simulation
    if alpha == 0.0
        Ct = Simulation.simulate(T, t0, p, q, sample)
    else
        Ct = Simulation.simulate(T, t0, p, q, alpha, sample)
    end

    # Output Z values to CSV
    dir = "data/Ct"
    if !isdir(dir)
        mkpath(dir)
    end

    filename = joinpath(dir, "T$(int_to_SI_prefix(T))_p$(p)_q$(q)_alpha$(alpha)_t0$(int_to_SI_prefix(t0))_sample$(int_to_SI_prefix(sample)).csv")
    save_to_csv(Ct, filename)
end

# Entry point of the script
isinteractive() || main(ARGS)
