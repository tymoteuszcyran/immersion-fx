local addonName, IFX = ...

IFX.SpellEffects = {}
local SpellEffects = IFX.SpellEffects

SpellEffects.Profiles = {

    --- WARLOCK ---
   -- Chaos Bolt: Cinematic Sequence
    [116858] = {
        {
            type = "cinematic_shake",
            chargeDuration = 2.0,   -- Time it takes to cast the spell
            zoomIn = 2.0,           -- How claustrophobic the zoom gets
            recoil = 4.5,           -- The violent kickback distance
        },
    },
    
    -- Haunt (Spectral Out-of-Body Drift)
    [48181] = {
        {
            type = "spectral_drift",
            castDuration = 1.5,       -- Handled dynamically, but sets base timing fallback
            driftOut = 2.6,           -- Smoothly pulls back 2.6 yards to create room detachment
            glideInDuration = 0.35,   -- Snappy, graceful magnetic return glide on projectile launch
        }
    },

    -- DEATH KNIGHT ---
    -- Obliterate (Heavy Physical Cleave)
    [49020] = {
        {
            type = "heavy_cleave",
            intensity = 2.2,         -- Solid forward zoom-in distance
            verticalLift = 1.8,      -- How significantly the camera rises above your head to force a downward view
            holdDuration = 0.08,     -- Briefly locks the camera in position to feel the smash
            recoveryDuration = 0.32, -- Smoothly settles the camera axes back down to your baseline
        }
    }
}

function SpellEffects:GetProfile(spellID)
    return self.Profiles[spellID]
end