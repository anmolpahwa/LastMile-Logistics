using LRP
using CSV
using HTTP
using JSON
using Random
using Revise
using StatsBase
using DataFrames
using OffsetArrays
using Serialization
using ProgressMeter
using Distributions
using ElasticArrays

include("strategic.jl")
include("tactical.jl")
include("operational.jl")
include("output.jl")
include("solution.jl")

let
##  Step 0. Initialize the environment
    # Input
    𝑓 = "Los Angeles/Base Case/#01. DD-C5DT"                                                            # directory of files
    p = 0.01                                                                                            # market share for the e-retailer
    θ = 3                                                                                               # customer consolidation per stop
    Δ = [0.2]                                                                                           # degree of dynamism (vector of dods)
    H = 1:30                                                                                            # planning horizon (vector of days)
    Γ = [14]                                                                                            # dynamic demand cutoff time (vector of cutoffs) 
##
##  Step 1. Strategic decision-making 
    println("STRATEGIC DECISION-MAKING")
    env = Dict()
    env["𝑓"] = 𝑓
    env["p"] = p
    env["θ"] = θ
    env["Δ"] = Δ
    env["H"] = H
    env["Γ"] = Γ
    env["δ"] = 0.
    env["t"] = 0
    env["⅄"] = "str"
    env["γ"] = 0
    env["s"] = LRP.Solution([], [], Dict(), 0., 0., 0., false)
    instance = "$𝑓/#1. strategic"
    if !isfile("results/$instance/solution.dat")
        rng = MersenneTwister(0)
        sₒ  = initialize(rng, instance; dir=joinpath(dirname(@__DIR__), "instances"))
        s   = optstr(rng, env, sₒ; mute=false)
        serialize("results/$instance/solution.dat", s)
    end
    s = deserialize("results/$instance/solution.dat")
    strategic = deepcopy(s)
    env["s"]  = strategic
##
##  Step 2. Simulate daily operations
    for δ ∈ Δ
        𝛿 = rpad(δ, 4, "0")
        for t ∈ H
            𝑡 = lpad(t, 2, "0")
            # Step 2.1. Tactical decision-making (actual)
            println("TACTICAL DECISION-MAKING - ACTUAL | δ: $𝛿 | t: $𝑡")
            env = Dict()
            env["𝑓"] = 𝑓
            env["p"] = p
            env["θ"] = θ
            env["Δ"] = Δ
            env["H"] = H
            env["Γ"] = Γ
            env["δ"] = δ
            env["t"] = t
            env["⅄"] = "tac-act"
            env["γ"] = 0
            env["s"] = strategic
            instance = "$𝑓/#2. tactical - actual/dod $𝛿/day $𝑡"
            if !isfile("results/$instance/solution.dat")
                rng = MersenneTwister(t)
                sₒ  = initialize(rng, instance; dir=joinpath(dirname(@__DIR__), "instances"))
                s   = optact(rng, env, sₒ; mute=true)
                serialize("results/$instance/solution.dat", s)
            end
            s = deserialize("results/$instance/solution.dat")
            tacact = deepcopy(s)
            # Step 2.2. Tactical decision-making (counterfactual)
            println("TACTICAL DECISION-MAKING - COUNTERFACTUAL | δ: $𝛿 | t: $𝑡")
            env = Dict()
            env["𝑓"] = 𝑓
            env["p"] = p
            env["θ"] = θ
            env["δ"] = δ
            env["t"] = t
            env["⅄"] = "tac-cft"
            env["γ"] = 0
            env["s"] = strategic
            instance = "$𝑓/#2. tactical - counterfactual/dod $𝛿/day $𝑡"
            if !isfile("results/$instance/solution.dat")
                rng = MersenneTwister(t)
                sₒ  = deepcopy(tacact)
                s   = optcft(rng, env, sₒ; mute=true)
                serialize("results/$instance/solution.dat", s)
            end
            s = deserialize("results/$instance/solution.dat")
            taccft = deepcopy(s)
            # Step 2.3. Operational decision-making
            for γ ∈ Γ
                𝛾 = lpad(γ, 2, "0")
                println("OPERATIONAL DECISION-MAKING | δ: $𝛿 | t: $𝑡 | γ: $𝛾")
                env = Dict()
                env["𝑓"] = 𝑓
                env["p"] = p
                env["θ"] = θ
                env["Δ"] = Δ
                env["H"] = H
                env["Γ"] = Γ
                env["δ"] = δ
                env["t"] = t
                env["⅄"] = "opt"
                env["γ"] = γ
                env["s"] = strategic
                instance = "$𝑓/#3. operational/dod $𝛿/day $𝑡/cot $𝛾"
                if !isfile("results/$instance/solution.dat")
                    rng = MersenneTwister(t)
                    sₒ  = deepcopy(tacact)
                    s   = optopr(rng, env, sₒ; mute=true)
                    serialize("results/$instance/solution.dat", s)
                end
                s = deserialize("results/$instance/solution.dat")
                opr = deepcopy(s)
            end
        end
    end
##
##  Step 3. Fetch output
    output(env)
end