local addonName, IFX = ...

IFX.SpellEffects = {}
local SpellEffects = IFX.SpellEffects

SpellEffects.Profiles = {
   -- Chaos Bolt: Cinematic Sequence
    [116858] = {
        {
            type = "cinematic_shake",
            chargeDuration = 2.0,   -- Time it takes to cast the spell
            zoomIn = 2.0,           -- How claustrophobic the zoom gets
            recoil = 4.5,           -- The violent kickback distance
        },
    },
    -- Wither (Instant Cast)
    [445474] = {
        {
            type = "instant_pulse",
            intensity = 1.0,        -- Snappy forward lunge distance
            snapInDuration = 0.06,  -- Near instant contraction (60 milliseconds)
            fadeOutDuration = 0.24, -- Smooth elastic bounce-back
        }
    }
}

function SpellEffects:GetProfile(spellID)
    return self.Profiles[spellID]
end