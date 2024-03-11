
"""
    feasible(s::Solution)

Returns `true` if customer service and time-window constraints;
vehicle capacity, range, working-hours, and operations constraints; and 
depot capacity constraints are not violated.
"""
function feasible(s::LRP.Solution)
    for d ∈ s.D
        if !LRP.isopt(d) continue end
        for v ∈ d.V
            if !LRP.isopt(v) continue end
            for r ∈ v.R
                if !LRP.isopt(r) continue end
                cˢ = s.C[r.iˢ]
                cᵉ = s.C[r.iᵉ] 
                c  = cˢ
                while true
                    if c.tʳ > c.tˢ println("Service constraint: $(c.iⁿ) | $(c.tʳ) > $(c.tˢ)") end
                    if c.tᵃ > c.tˡ println("Time-window constraint: $(c.iⁿ) | $(c.tᵃ) > $(c.tˡ)") end
                    if isequal(c, cᵉ) break end
                    c = s.C[c.iʰ]
                end
                if r.q > v.qᵛ println("Vehicle capacity constraint: $(d.iⁿ)|$(v.iᵛ)|$(r.iʳ) | $(r.q) > $(v.qᵛ)") end
                if r.l > v.lᵛ println("Vehicle range constraint: $(d.iⁿ)|$(v.iᵛ)|$(r.iʳ) | $(r.l) > $(v.lᵛ)") end
            end
            if d.tˢ > v.tˢ println("Working-hours start-time constraint: $(d.iⁿ)|$(v.iᵛ) | $(d.tˢ) > $(v.tˢ)") end
            if v.tᵉ > d.tᵉ println("Working-hours end-time constraint: $(d.iⁿ)|$(v.iᵛ) | $(v.tᵉ) > $(d.tᵉ)") end
            if v.tᵉ - v.tˢ > v.τʷ println("Working-hours duration constraint: $(d.iⁿ)|$(v.iᵛ) | $(v.tᵉ - v.tˢ) > $(v.τʷ)") end
            if length(v.R) > v.r̅ println("Working-load constraint: $(d.iⁿ)|$(v.iᵛ) | $(length(v.R)) > $(v.r̅)") end
        end
        if d.q > d.qᵈ println("Depot capacity constraint: $(d.iⁿ) | $(d.q) > $(d.qᵈ)") end
    end
end



"""
    Π(s::Solution)

Returns objective function evaluation for solution `s`
"""
function Π(s)
    πᶠ = 0.
    πᵒ = 0.
    πᵖ = 0.
    for d ∈ s.D
        πᶠ += LRP.isopt(d) * d.πᶠ
        πᵒ += d.q * d.πᵒ
        πᵖ += (d.q > d.qᵈ) ? (d.q - d.qᵈ) : 0.
        for v ∈ d.V
            πᶠ += LRP.isopt(v) * v.πᶠ
            πᵒ += (v.tᵉ - v.tˢ) * v.πᵗ
            πᵖ += (length(v.R) > v.r̅) ? (length(v.R) - v.r̅) : 0.
            πᵖ += (d.tˢ > v.tˢ) ? (d.tˢ - v.tˢ) : 0.
            πᵖ += (v.tᵉ > d.tᵉ) ? (v.tᵉ - d.tᵉ) : 0.
            πᵖ += ((v.tᵉ - v.tˢ) > v.τʷ) ? ((v.tᵉ - v.tˢ) - v.τʷ) : 0.
            for r ∈ v.R
                πᶠ += 0.
                πᵒ += r.l * v.πᵈ
                πᵖ += (r.q > v.qᵛ) ? (r.q - v.qᵛ) : 0.
                πᵖ += (r.l > v.lᵛ) ? (r.l - v.lᵛ) : 0.
            end
        end
    end
    for c ∈ s.C
        πᶠ += 0.
        πᵒ += 0.
        πᵖ += (c.tᵃ > c.tˡ) ? (c.tᵃ - c.tˡ) : 0.
        πᵖ += LRP.isopen(c) * c.qᶜ
    end
    return πᶠ + πᵒ + πᵖ
end