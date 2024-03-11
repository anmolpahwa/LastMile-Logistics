# Output
function output(env::Dict)
    # Step 0. Initialize
    𝑓   = env["𝑓"]
    p   = env["p"]
    θ   = env["θ"]
    Δ   = env["Δ"]
    H   = env["H"]
    Γ   = env["Γ"]
    df₁ = DataFrame(
        day                 = Int64[]   , 
        decision            = String[]  , 
        cutoff              = Int64[]   ,
        customers           = Int64[]   ,
        fulfillment_trip_e1 = Float64[] ,
        fulfillment_trip_e2 = Float64[] , 
        delivery_tour_e1    = Float64[] , 
        delivery_tour_e2    = Float64[] ,
        fixed_cost          = Float64[] ,
        operational_cost    = Float64[] ,
        penalty             = Float64[] ,
        isfeasible          = Bool[]
    )
    df₂ = DataFrame(
        dod                 = Float64[] ,
        day                 = Int64[]   ,
        decision            = String[]  ,
        cutoff              = Int64[]   ,
        vehicle_id          = Int64[]   ,
        route_id            = Int64[]   ,
        customers           = Int64[]   ,
        demand              = Float64[] ,
        length              = Float64[] ,
        initiation_time     = Float64[] ,
        start_time          = Float64[] ,
        end_time            = Float64[] ,
        duration            = Float64[] ,
        slack               = Float64[] ,    
        route_cutoff_time   = Float64[] ,
        status              = Int64[]
    )  
    ##  Step 1. Fetch strategic decision-making 
    println("STRATEGIC DECISION-MAKING")
    env["δ"] = 0.
    env["t"] = 0
    env["γ"] = 0
    env["⅄"] = "str"
    instance = "$𝑓/#1. strategic"
    if isfile("results/$instance/solution.dat")
        s = deserialize("results/$instance/solution.dat")
        push!(df₁, summary(s, env))
        push!(df₂, routes(s, env)...)
    end
    ##  Step 2. Fetch daily operations
    for δ ∈ Δ
        env["δ"] = δ
        𝛿 = rpad(δ, 4, "0")
        println("\nδ: $𝛿")
        for t ∈ H
            env["t"] = t
            𝑡 = lpad(t, 2, "0")
            println("\nt: $𝑡")
            # Step 2.1. Fetch tactical decision-making (actual)
            println("TACTICAL DECISION-MAKING - ACTUAL")
            env["⅄"] = "tac-act"
            instance = "$𝑓/#2. tactical - actual/dod $𝛿/day $𝑡"
            if isfile("results/$instance/solution.dat")
                s = deserialize("results/$instance/solution.dat")
                push!(df₁, summary(s, env))
                push!(df₂, routes(s, env)...)
            end
            # Step 2.2. Fetch tactical decision-making (counterfactual)
            println("TACTICAL DECISION-MAKING - COUNTERFACTUAL")
            env["⅄"] = "tac-cft"
            instance = "$𝑓/#2. tactical - counterfactual/dod $𝛿/day $𝑡"
            if isfile("results/$instance/solution.dat")
                s = deserialize("results/$instance/solution.dat")
                push!(df₁, summary(s, env))
                push!(df₂, routes(s, env)...)
            end
            # Step 2.3. Fetch operational decision-making
            for γ ∈ Γ
                env["γ"] = γ
                𝛾 = lpad(γ, 2, "0")
                println("OPERATIONAL DECISION-MAKING | γ: $𝛾")
                env["⅄"] = "opt"
                instance = "$𝑓/#3. operational/dod $𝛿/day $𝑡/cot $𝛾"
                if isfile("results/$instance/solution.dat")
                    s = deserialize("results/$instance/solution.dat")
                    push!(df₁, summary(s, env))
                    push!(df₂, routes(s, env)...)
                end
            end
            env["γ"] = 0
        end
        CSV.write(joinpath(pwd(), "results/$𝑓/summary.csv"), df₁)
        CSV.write(joinpath(pwd(), "results/$𝑓/routes.csv"), df₂)
    end
    return
end

# Return relevant macro-level data
function summary(s::LRP.Solution, env::Dict)
    𝑓   = env["𝑓"]
    t   = env["t"]
    ⅄   = env["⅄"]
    γ   = env["γ"]
    df  = DataFrame(CSV.File("instances/$𝑓/depot nodes.csv"))
    loc = [(df[k,:x], df[k,:y]) for k ∈ 1:nrow(df)]
    x₀  = 50.
    y₀  = 0.
    x₁  = 50.
    y₁  = 0.
    ft₁ = 0.
    dt₁ = 0.
    ft₂ = 0.
    dt₂ = 0.
    for d ∈ s.D
        if !LRP.isopt(d) continue end
        k  = findfirst(isequal((d.x, d.y)), loc)
        jⁿ = df[k, :Echelon]
        if isequal(jⁿ, 1)
            x₁ = d.x
            y₁ = d.y
            ft₁ += 2(abs(x₁-x₀) + abs(y₁-y₀))
            for v ∈ d.V for r ∈ v.R dt₁ += r.l end end
        end
        if isequal(jⁿ, 2)
            x₂ = d.x
            y₂ = d.y
            ft₂ += 2(abs(x₂-x₁) + abs(y₂-y₁))
            for v ∈ d.V for r ∈ v.R dt₂ += r.l end end
        end
    end
    summary = (t, ⅄, γ, length(s.C), ft₁, ft₂, dt₁, dt₂, s.πᶠ, s.πᵒ, s.πᵖ, isfeasible(s))
    return summary
end

# Return relevant micro-level route data
function routes(s::LRP.Solution, env::Dict)
    t   = env["t"]
    ⅄   = env["⅄"]
    δ   = env["δ"]
    γ   = env["γ"]
    routes = ()
    for d ∈ s.D
        for v ∈ d.V
            for r ∈ v.R
                if !LRP.isopt(r) continue end
                routes = (routes..., (δ, t, ⅄, γ, v.iᵛ, r.iʳ, r.n, r.q, r.l, r.tⁱ, r.tˢ, r.tᵉ, r.tᵉ - r.tⁱ, r.τ, d.tˢ + floor(r.tⁱ + r.τ - d.tˢ), r.φ))
            end
        end
    end
    return routes
end