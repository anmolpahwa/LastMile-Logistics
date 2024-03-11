# Tactical decision-making (actual)
function optact(rng::AbstractRNG, env::Dict, sₒ::LRP.Solution; mute=false)
    x = ceil(lastindex(sₒ.C)/3)
    χ = ALNSparameters(
        j   =   50                      ,
        k   =   5                       ,
        n   =   x                       ,
        m   =   100x                    ,
        Ψᵣ  =   [
                    :randomcustomer!    ,
                    :randomroute!       ,
                    :randomvehicle!     ,
                    :relatedcustomer!   ,
                    :relatedroute!      ,
                    :relatedvehicle!    ,
                    :worstcustomer!     ,
                    :worstroute!        ,
                    :worstvehicle!
                ]                       ,
        Ψᵢ  =   [
                    :best!              ,
                    :precise!           ,
                    :perturb!           ,
                    :regret2!           ,
                    :regret3!
                ]                       ,
        Ψₗ  =   [
                    :intramove!         ,
                    :intraswap!         ,
                    :intraopt!          ,
                    :intermove!         ,
                    :interswap!         ,
                    :interopt!
                ]                       ,
        σ₁  =   15                      ,
        σ₂  =   10                      ,
        σ₃  =   3                       ,
        μ̲   =   0.1                     ,
        c̲   =   4                       ,
        μ̅   =   0.4                     ,
        c̅   =   60                      ,
        ω̅   =   0.05                    ,
        τ̅   =   0.5                     ,
        ω̲   =   0.01                    ,
        τ̲   =   0.01                    ,
        θ   =   exp(-0.1/x)             ,
        ρ   =   0.1
    );
    s = ALNS(rng, χ, sₒ; mute=mute)
    return s
end

# Tactical decision-making (counterfactual)
function optcft(rng::AbstractRNG, env::Dict, sₒ::LRP.Solution; mute=false)
    𝑓 = env["𝑓"]
    t = env["t"]
    δ = env["δ"]
    𝛿 = rpad(δ, 4, "0")
    𝑡 = lpad(t, 2, "0")
    G = LRP.build("$𝑓/#2. tactical - counterfactual/dod $𝛿/day $𝑡"; dir=joinpath(dirname(@__DIR__), "instances"))
    Dₒ, Cₒ  = sₒ.D, sₒ.C
    D, C, A = G
    for iⁿ ∈ eachindex(Dₒ) D[iⁿ] = Dₒ[iⁿ] end
    for iⁿ ∈ eachindex(Cₒ) C[iⁿ] = Cₒ[iⁿ] end
    s = LRP.Solution(D, C, A) 
    LRP.precise!(rng, s)
    x = ceil((lastindex(s.C) - lastindex(sₒ.C))/3)
    χ = ALNSparameters(
        j   =   50                      ,
        k   =   5                       ,
        n   =   x                       ,
        m   =   100x                    ,
        Ψᵣ  =   [
                    :randomcustomer!    ,
                    :randomroute!       ,
                    :randomvehicle!     ,
                    :relatedcustomer!   ,
                    :relatedroute!      ,
                    :relatedvehicle!    ,
                    :worstcustomer!     ,
                    :worstroute!        ,
                    :worstvehicle!
                ]                       ,
        Ψᵢ  =   [
                    :best!              ,
                    :precise!           ,
                    :perturb!           ,
                    :regret2!           ,
                    :regret3!
                ]                       ,
        Ψₗ  =   [
                    :intramove!         ,
                    :intraswap!         ,
                    :intraopt!          ,
                    :intermove!         ,
                    :interswap!         ,
                    :interopt!
                ]                       ,
        σ₁  =   15                      ,
        σ₂  =   10                      ,
        σ₃  =   3                       ,
        μ̲   =   0.1                     ,
        c̲   =   4                       ,
        μ̅   =   0.4                     ,
        c̅   =   60                      ,
        ω̅   =   0.05                    ,
        τ̅   =   0.5                     ,
        ω̲   =   0.01                    ,
        τ̲   =   0.01                    ,
        θ   =   exp(-0.1/x)             ,
        ρ   =   0.1
    );
    s = ALNS(rng, χ, s; mute=mute)
    return s
end