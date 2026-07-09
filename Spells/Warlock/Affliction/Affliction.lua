local addonName, IFX = ...
local SpellEffects = IFX.SpellEffects
local Anim = IFX.Animation

-- Spectral Reverse Drift for Ghostly/Spiritual Casts (Haunt)
local function PlaySpectralDrift(effectData, dynamicDuration)
    local castDuration = dynamicDuration or effectData.castDuration or 1.5
    local driftOutAmount = (effectData.driftOut or 2.5) * IFX.Config:GetIntensity()
    local glideInDuration = effectData.glideInDuration or 0.35

    -- PHASE 1: The Out-of-Body Drift (Slowly Zoom Out during cast)
    local steps = 25
    local stepDelay = castDuration / steps
    local zoomOutPerStep = driftOutAmount / steps

    for i = 1, steps do
        C_Timer.After(stepDelay * (i - 1), function()
            CameraZoomOut(zoomOutPerStep)
        end)
    end

    -- PHASE 2: The Eerie Return (Swiftly Glide back in on finish)
    C_Timer.After(castDuration, function()
        local glideSteps = 12
        local glideDelay = glideInDuration / glideSteps
        local zoomInPerStep = driftOutAmount / glideSteps

        for j = 1, glideSteps do
            C_Timer.After(glideDelay * (j - 1), function()
                CameraZoomIn(zoomInPerStep)
            end)
        end
    end)
end

-- Register spectral_drift as an Affliction-specific animation handler
Anim:Register("spectral_drift", "UNIT_SPELLCAST_START", PlaySpectralDrift)

-- Warlock Affliction specialization spells
local AfflictionProfiles = {
    -- Haunt (Spectral Out-of-Body Drift)
    [48181] = {
        {
            type = "spectral_drift",
            castDuration = 1.5,       -- Handled dynamically, but sets base timing fallback
            driftOut = 2.6,           -- Smoothly pulls back 2.6 yards to create room detachment
            glideInDuration = 0.35,   -- Snappy, graceful magnetic return glide on projectile launch
        }
    },
}

SpellEffects:RegisterProfiles(AfflictionProfiles)
