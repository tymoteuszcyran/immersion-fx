local addonName, IFX = ...
local SpellEffects = IFX.SpellEffects
local Anim = IFX.Animation

-- Heavy Grounded Vertical Cleave for Obliterate
local function PlayHeavyCleave(effectData)
    local intensity = (effectData.intensity or 2.0) * IFX.Config:GetIntensity()
    local verticalLift = effectData.verticalLift or 1.5
    local holdDuration = effectData.holdDuration or 0.08
    local recoveryDuration = effectData.recoveryDuration or 0.35

    -- Get baseline vertical offset so we return to your exact original UI layout
    local baselineVertical = tonumber(GetCVar("test_cameraVerticalOffset")) or 0

    -- PHASE 1: The Heavy Impact Slam (Instant Zoom In + Vertical Lift)
    CameraZoomIn(intensity)
    SetCVar("test_cameraVerticalOffset", baselineVertical + verticalLift)

    -- PHASE 2 & 3: The Heavy Hold and Smooth Recovery Ease-Out
    local steps = 12
    local stepDelay = recoveryDuration / steps
    local zoomOutPerStep = intensity / steps
    local verticalDropPerStep = verticalLift / steps

    for i = 1, steps do
        C_Timer.After(holdDuration + (stepDelay * (i - 1)), function()
            CameraZoomOut(zoomOutPerStep)
            
            local currentVertical = (baselineVertical + verticalLift) - (verticalDropPerStep * i)
            SetCVar("test_cameraVerticalOffset", currentVertical)
        end)
    end
    
    -- Absolute fallback safety cleanup to guarantee baseline is perfectly restored
    C_Timer.After(holdDuration + recoveryDuration + 0.05, function()
        SetCVar("test_cameraVerticalOffset", baselineVertical)
    end)
end

-- Register heavy_cleave as a Frost-specific animation handler
Anim:Register("heavy_cleave", "UNIT_SPELLCAST_SUCCEEDED", PlayHeavyCleave)

-- Death Knight Frost specialization spells
local FrostProfiles = {
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

SpellEffects:RegisterProfiles(FrostProfiles)
