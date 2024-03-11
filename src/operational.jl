# Operational decision-making
function optopr(rng::AbstractRNG, env::Dict, sₒ::LRP.Solution; mute=false)
    # Step 1. Initialize
    𝑓 = env["𝑓"]
    t = env["t"]
    δ = env["δ"]
    γ = env["γ"]
    𝛿 = rpad(δ, 4, "0")
    𝑡 = lpad(t, 2, "0")
    𝛾 = lpad(γ, 2, "0")
    s = deepcopy(sₒ)
    df = DataFrame(CSV.File("instances/$𝑓/#3. operational/dod $𝛿/day $𝑡/cot $𝛾/customer_nodes.csv"))
    Iⁿ = (df[1,1]:df[nrow(df),1])::UnitRange{Int64}
    Tʳ = Dict{Int64, Float64}(iⁿ => 0. for iⁿ ∈ Iⁿ)
    C  = OffsetVector{LRP.CustomerNode}(undef, Iⁿ)
    for k ∈ 1:nrow(df)
        iⁿ = df[k,1]
        x  = df[k,2]
        y  = df[k,3]
        q  = df[k,4]
        τᶜ = df[k,5]
        tʳ = df[k,6]
        tᵉ = df[k,7]
        tˡ = df[k,8]
        iᵗ = 0
        iʰ = 0
        tˢ = tʳ
        tᵃ = 0
        tᵈ = 0
        c  = LRP.CustomerNode(iⁿ, x, y, q, τᶜ, tʳ, tᵉ, tˡ, iᵗ, iʰ, tˢ, tᵃ, tᵈ, LRP.NullRoute)
        C[iⁿ]  = c
        Tʳ[iⁿ] = tʳ
    end
    df = DataFrame(CSV.File("instances/$𝑓/#3. operational/dod $𝛿/day $𝑡/cot $𝛾/arcs.csv", header=false))
    n  = length(s.D) + length(s.C) + length(C)
    A  = Dict{Tuple{Int64,Int64},LRP.Arc}()
    for iᵗ ∈ 1:n for iʰ ∈ 1:n A[(iᵗ,iʰ)] = LRP.Arc(iᵗ, iʰ, df[iᵗ,iʰ]) end end
    # Step 2. Simulate daily operations for day-t
    tˢ = Inf
    tᵉ = 0.
    for d ∈ s.D if d.tˢ < tˢ tˢ = d.tˢ end end
    for d ∈ s.D if d.tᵉ > tᵉ tᵉ = d.tᵉ end end
    τ = 1.
    t = tˢ - τ
    if !mute p = Progress(Int64((tᵉ - tˢ)/τ), desc="Computing...", color=:blue, showspeed=true) end
    while t ≤ tᵉ
        if !mute println("   δ: $𝛿 | t: $𝑡 | γ: $𝛾 | time: $t") end
        # Step 2.1. Process route updates
        for d ∈ s.D
            for v ∈ d.V
                s.πᶠ -= 0.
                s.πᵒ -= (v.tᵉ - v.tˢ) * v.πᵗ
                s.πᵖ -= (d.tˢ > v.tˢ) ? (d.tˢ - v.tˢ) : 0.
                s.πᵖ -= (v.tᵉ > d.tᵉ) ? (v.tᵉ - d.tᵉ) : 0.
                s.πᵖ -= ((v.tᵉ - v.tˢ) > v.τʷ) ? ((v.tᵉ - v.tˢ) - v.τʷ) : 0.
                for r ∈ v.R
                    if LRP.isopt(r)
                        if !LRP.isactive(r) continue end
                        r.tⁱ = t
                        r.tˢ = r.tⁱ + v.τᶠ * (r.θˢ - r.θⁱ) + v.τᵈ * r.q
                        cˢ = s.C[r.iˢ]
                        cᵉ = s.C[r.iᵉ]
                        tᵈ = r.tˢ
                        c  = cˢ
                        while true
                            s.πᶠ -= 0.
                            s.πᵒ -= 0.
                            s.πᵖ -= (c.tʳ > c.tˢ) ? (c.tʳ - c.tˢ) : 0.
                            s.πᵖ -= (c.tᵃ > c.tˡ) ? (c.tᵃ - c.tˡ) : 0.
                            c.tˢ  = r.tˢ
                            c.tᵃ  = tᵈ + s.A[(c.iᵗ, c.iⁿ)].l/v.sᵛ
                            c.tᵈ  = c.tᵃ + v.τᶜ + max(0., c.tᵉ - c.tᵃ - v.τᶜ) + c.τᶜ
                            s.πᶠ += 0.
                            s.πᵒ += 0.
                            s.πᵖ += (c.tʳ > c.tˢ) ? (c.tʳ - c.tˢ) : 0.
                            s.πᵖ += (c.tᵃ > c.tˡ) ? (c.tᵃ - c.tˡ) : 0.
                            if isequal(c, cᵉ) break end
                            tᵈ = c.tᵈ
                            c = s.C[c.iʰ]
                        end
                        r.tᵉ = cᵉ.tᵈ + s.A[(cᵉ.iⁿ, cᵉ.iʰ)].l/v.sᵛ
                    else
                        r.tⁱ = t
                        r.tˢ = t
                        r.tᵉ = t
                    end
                end
                (v.tˢ, v.tᵉ) = isempty(v.R) ? (d.tˢ, d.tˢ) : (v.R[1].tⁱ, v.R[length(v.R)].tᵉ)
                s.πᶠ += 0.
                s.πᵒ += (v.tᵉ - v.tˢ) * v.πᵗ
                s.πᵖ += (d.tˢ > v.tˢ) ? (d.tˢ - v.tˢ) : 0.
                s.πᵖ += (v.tᵉ > d.tᵉ) ? (v.tᵉ - d.tᵉ) : 0.
                s.πᵖ += ((v.tᵉ - v.tˢ) > v.τʷ) ? ((v.tᵉ - v.tˢ) - v.τʷ) : 0.
            end
        end
        # Step 2.2. Update slack
        for d ∈ s.D
            τᵒ = Inf
            for v ∈ d.V
                τᵒ = d.tᵉ - v.tᵉ
                for r ∈ reverse(v.R)
                    if !LRP.isopt(r) continue end
                    cˢ = s.C[r.iˢ]
                    cᵉ = s.C[r.iᵉ]
                    c  = cˢ
                    while true
                        τᵒ = min(τᵒ, c.tˡ - c.tᵃ - v.τᶜ)
                        if isequal(c, cᵉ) break end
                        c = s.C[c.iʰ]
                    end
                    r.τ = τᵒ
                end
                v.τ = τᵒ
            end
            d.τ = τᵒ
        end
        # Step 2.3. Process delivery commitments
        n  = length(s.D) + length(s.C)
        Δn = 0
        for c ∈ C
            iⁿ = c.iⁿ
            tʳ = Tʳ[iⁿ]
            tᶜ = tˢ + ceil((tʳ - tˢ)/τ) * τ
            if isequal(tᶜ, t)
                push!(s.C, c)
                n += 1
                Δn += 1
                for jⁿ ∈ 1:n
                    s.A[(iⁿ,jⁿ)] = A[(iⁿ,jⁿ)]
                    s.A[(jⁿ,iⁿ)] = A[(jⁿ,iⁿ)]
                end
                s.πᵖ += c.qᶜ
                preopt!(t, s)
                LRP.precise!(rng, s)
                postopt!(t, s)
            end
        end
        # Step 2.4. Optimize solution
        preopt!(t, s)
        x = ceil((Δn/3) / length(s.D))
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
        for d ∈ s.D
            if iszero(d.n) continue end
            # Step 2.3.1. Split
            Dᵈ = [d]
            Vᵈ = [v for v ∈ d.V]
            Rᵈ = [r for v ∈ d.V for r ∈ v.R]
            Cᵈ = OffsetVector([c for c ∈ s.C if isequal(c.r.iᵈ, d.iⁿ)], 2:(d.n + 1))
            Nᵈ = [Dᵈ..., Cᵈ...]
            Aᵈ = Dict{Tuple{Int,Int},LRP.Arc}()
            nᵈ = length(Nᵈ)
            Xᵈ = Dict{Int64,Int64}(n.iⁿ => i for (i,n) ∈ pairs(Nᵈ))
            Yᵈ = Dict{Int64,Int64}(i => n.iⁿ for (i,n) ∈ pairs(Nᵈ))
            for n ∈ Nᵈ
                n.iⁿ = Xᵈ[n.iⁿ]
            end
            for v ∈ Vᵈ
                v.iᵈ = Xᵈ[v.iᵈ]
            end
            for r ∈ Rᵈ
                r.iᵈ = Xᵈ[r.iᵈ]
                r.iˢ = Xᵈ[r.iˢ]
                r.iᵉ = Xᵈ[r.iᵉ]
            end
            for c ∈ Cᵈ
                c.iᵗ = Xᵈ[c.iᵗ]
                c.iʰ = Xᵈ[c.iʰ]
                c.r  = Rᵈ[findfirst(r -> isequal("$(r.iʳ)-$(r.iᵛ)", "$(c.r.iʳ)-$(c.r.iᵛ)"), Rᵈ)]
            end
            for iᵗ ∈ 1:nᵈ for iʰ ∈ 1:nᵈ Aᵈ[(iᵗ,iʰ)] = s.A[(Yᵈ[iᵗ],Yᵈ[iʰ])] end end
            sᵈ = deepcopy(LRP.Solution(Dᵈ, Cᵈ, Aᵈ))
            # Step 2.3.2. Perform ALNS
            sᵈ = ALNS(rng, χ, sᵈ; mute=mute)
            # Step 2.3.3. Merge
            d = sᵈ.D[d.iⁿ]
            Dᵈ = [d]
            Vᵈ = [v for v ∈ d.V]
            Rᵈ = [r for v ∈ d.V for r ∈ v.R]
            Cᵈ = OffsetVector([c for c ∈ sᵈ.C if isequal(c.r.iᵈ, d.iⁿ)], 2:(d.n + 1))
            Nᵈ = [Dᵈ..., Cᵈ...]
            for n ∈ Nᵈ
                n.iⁿ = Yᵈ[n.iⁿ]
            end 
            for v ∈ Vᵈ
                v.iᵈ = Yᵈ[v.iᵈ]
            end 
            for r ∈ Rᵈ
                r.iᵈ = Yᵈ[r.iᵈ]
                r.iˢ = Yᵈ[r.iˢ]
                r.iᵉ = Yᵈ[r.iᵉ]
            end
            for c ∈ Cᵈ
                c.iᵗ = Yᵈ[c.iᵗ]
                c.iʰ = Yᵈ[c.iʰ]
                c.r  = Rᵈ[findfirst(r -> isequal("$(r.iʳ)-$(r.iᵛ)", "$(c.r.iʳ)-$(c.r.iᵛ)"), Rᵈ)]
            end
            for n ∈ Nᵈ LRP.isdepot(n) ? s.D[n.iⁿ] = n : s.C[n.iⁿ] = n end
            for n ∈ Nᵈ if n.iⁿ ∈ keys(C) C[n.iⁿ] = n end end
            s = deepcopy(LRP.Solution(s.D, s.C, s.A))
        end
        postopt!(t, s)
        # Step 2.5. Process route commitments
        for d ∈ s.D
            if !LRP.isopt(d) continue end
            for v ∈ d.V
                if !LRP.isopt(v) continue end
                s.πᶠ -= 0.
                s.πᵒ -= (v.tᵉ - v.tˢ) * v.πᵗ
                s.πᵖ -= (d.tˢ > v.tˢ) ? (d.tˢ - v.tˢ) : 0.
                s.πᵖ -= (v.tᵉ > d.tᵉ) ? (v.tᵉ - d.tᵉ) : 0.
                s.πᵖ -= ((v.tᵉ - v.tˢ) > v.τʷ) ? ((v.tᵉ - v.tˢ) - v.τʷ) : 0.
                for r ∈ v.R
                    tᶜ = r.tⁱ + r.τ
                    if tᶜ > t + τ continue end
                    if !LRP.isopt(r) continue end 
                    if !LRP.isactive(r) continue end
                    r.φ  = 0
                    r.tⁱ = tᶜ
                    r.tˢ = r.tⁱ + v.τᶠ * (r.θˢ - r.θⁱ) + v.τᵈ * r.q
                    cˢ = s.C[r.iˢ]
                    cᵉ = s.C[r.iᵉ]
                    tᵈ = r.tˢ
                    c  = cˢ
                    while true
                        s.πᶠ -= 0.
                        s.πᵒ -= 0.
                        s.πᵖ -= (c.tʳ > c.tˢ) ? (c.tʳ - c.tˢ) : 0.
                        s.πᵖ -= (c.tᵃ > c.tˡ) ? (c.tᵃ - c.tˡ) : 0.
                        c.tˢ  = r.tˢ
                        c.tᵃ  = tᵈ + s.A[(c.iᵗ, c.iⁿ)].l/v.sᵛ
                        c.tᵈ  = c.tᵃ + v.τᶜ + max(0., c.tᵉ - c.tᵃ - v.τᶜ) + c.τᶜ
                        s.πᶠ += 0.
                        s.πᵒ += 0.
                        s.πᵖ += (c.tʳ > c.tˢ) ? (c.tʳ - c.tˢ) : 0.
                        s.πᵖ += (c.tᵃ > c.tˡ) ? (c.tᵃ - c.tˡ) : 0.
                        if isequal(c, cᵉ) break end
                        tᵈ = c.tᵈ
                        c = s.C[c.iʰ]
                    end
                    r.tᵉ = cᵉ.tᵈ + s.A[(cᵉ.iⁿ, cᵉ.iʰ)].l/v.sᵛ
                end
                (v.tˢ, v.tᵉ) = isempty(v.R) ? (d.tˢ, d.tˢ) : (v.R[1].tⁱ, v.R[length(v.R)].tᵉ)
                s.πᶠ += 0.
                s.πᵒ += (v.tᵉ - v.tˢ) * v.πᵗ
                s.πᵖ += (d.tˢ > v.tˢ) ? (d.tˢ - v.tˢ) : 0.
                s.πᵖ += (v.tᵉ > d.tᵉ) ? (v.tᵉ - d.tᵉ) : 0.
                s.πᵖ += ((v.tᵉ - v.tˢ) > v.τʷ) ? ((v.tᵉ - v.tˢ) - v.τʷ) : 0.
            end
        end
        # Step 2.6. Update slack
        for d ∈ s.D
            τᵒ = Inf
            for v ∈ d.V
                τᵒ = d.tᵉ - v.tᵉ
                for r ∈ reverse(v.R)
                    if !LRP.isopt(r) continue end
                    cˢ = s.C[r.iˢ]
                    cᵉ = s.C[r.iᵉ]
                    c  = cˢ
                    while true
                        τᵒ = min(τᵒ, c.tˡ - c.tᵃ - v.τᶜ)
                        if isequal(c, cᵉ) break end
                        c = s.C[c.iʰ]
                    end
                    r.τ = τᵒ
                end
                v.τ = τᵒ
            end
            d.τ = τᵒ
        end
        t += τ
        if !mute next!(p) end
    end
    # Step 3. Return solution
    return s
end



# Pre-optimization procedures
function preopt!(t::Float64, s::LRP.Solution)
    for d ∈ s.D
        for v ∈ d.V
            iʳ = lastindex(v.R) + 1
            iᵛ = v.iᵛ
            iᵈ = d.iⁿ
            x  = 0.
            y  = 0. 
            iˢ = iᵈ
            iᵉ = iᵈ
            θⁱ = isone(iʳ) ? 1.0 : v.R[iʳ-1].θᵉ
            θˢ = θⁱ
            θᵉ = θˢ
            tⁱ = isone(iʳ) ? t : v.R[iʳ-1].tᵉ
            tˢ = tⁱ
            tᵉ = tⁱ
            τ  = d.tᵉ - v.tᵉ
            n  = 0 
            q  = 0.
            l  = 0.
            φ  = 1
            r  = LRP.Route(iʳ, iᵛ, iᵈ, x, y, iˢ, iᵉ, θⁱ, θˢ, θᵉ, tⁱ, tˢ, tᵉ, τ, n, q, l, φ)
            φ  = any(!LRP.isopt, v.R) || isequal(length(v.R), v.r̅)
            if isequal(φ, false) push!(v.R, r) end
            iᵛ = lastindex(d.V) + 1
            jᵛ = v.jᵛ
            iᵈ = v.iᵈ
            qᵛ = v.qᵛ
            lᵛ = v.lᵛ
            sᵛ = v.sᵛ
            τᶠ = v.τᶠ
            τᵈ = v.τᵈ
            τᶜ = v.τᶜ
            τʷ = v.τʷ
            r̅  = v.r̅
            πᵈ = v.πᵈ
            πᵗ = v.πᵗ
            πᶠ = v.πᶠ
            tˢ = t
            tᵉ = tˢ
            τ  = d.tᵉ - tᵉ
            n  = 0
            q  = 0.
            l  = 0.
            R  = LRP.Route[]
            v  = LRP.Vehicle(iᵛ, jᵛ, iᵈ, qᵛ, lᵛ, sᵛ, τᶠ, τᵈ, τᶜ, τʷ, r̅, πᵈ, πᵗ, πᶠ, tˢ, tᵉ, τ, n, q, l, R)
            φ  = any(!LRP.isopt, filter(v′ -> isequal(v′.jᵛ, v.jᵛ), d.V))
            if isequal(φ, false) push!(d.V, v) end
        end
    end
    return s
end



# Post-optimization procedures
function postopt!(t::Float64, s::LRP.Solution)
    for d ∈ s.D
        k = 1
        while true
            v = d.V[k]
            if LRP.deletevehicle(v, s)
                deleteat!(d.V, k)
            else
                v.iᵛ = k
                for r ∈ v.R r.iᵛ = k end
                k += 1
            end
            if k > length(d.V) break end
        end
        for v ∈ d.V
            if isempty(v.R) continue end
            k = 1
            while true
                r = v.R[k]
                if LRP.deleteroute(r, s) 
                    deleteat!(v.R, k)
                else
                    r.iʳ = k
                    k += 1
                end
                if k > length(v.R) break end
            end
        end
    end
    return s
end