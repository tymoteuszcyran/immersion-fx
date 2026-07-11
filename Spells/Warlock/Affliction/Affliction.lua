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

-- Channeled Soul Siphon Camera Sequence (Smooth, non-dizzying zoom-in with rhythmic vertical bobbing and velocity pulses)
local function PlaySoulSiphon(effectData, dynamicDuration)
    if not IFX.Config:IsEffectTypeEnabled("camera") then return end

    local duration = dynamicDuration or effectData.duration or 3.0
    local intensity = IFX.Config:GetIntensity()
    local zoomInAmount = (effectData.zoomInAmount or 1.5) * intensity
    local pulseHeight = (effectData.pulseHeight or 1.2) * intensity
    local pulseStrength = math.min(effectData.pulseStrength or 0.8, 0.95) -- Clamp to prevent backward zooming
    local numPulses = effectData.numPulses or 3
    local recoveryDuration = effectData.recoveryDuration or 0.5

    -- 1. Capture baseline state
    local baselineVertical = tonumber(GetCVar("test_cameraVerticalOffset")) or 0
    local baselineDistance = GetCameraZoom()

    -- 2. Define the target zoom curve (velocity-pulsed, strictly increasing)
    local function getZoomOffset(t)
        local term = t + (pulseStrength / (numPulses * 2 * math.pi)) * math.sin(t * numPulses * 2 * math.pi)
        return zoomInAmount * term
    end

    -- PHASE 1: The Channeled Siphon (Velocity-pulsed zoom-in + vertical bobbing)
    local steps = 30
    local stepDelay = duration / steps
    local lastZoomOffset = 0

    for i = 1, steps do
        C_Timer.After(stepDelay * (i - 1), function()
            local t = i / steps
            
            -- Zoom: Calculate delta zoom-in (guaranteed positive because pulseStrength < 1.0)
            local currentZoomOffset = getZoomOffset(t)
            local deltaZoom = currentZoomOffset - lastZoomOffset
            lastZoomOffset = currentZoomOffset

            if deltaZoom > 0 then
                CameraZoomIn(deltaZoom)
            end

            -- Vertical: Smooth bobbing sine wave
            local currentVerticalOffset = pulseHeight * math.sin(t * numPulses * 2 * math.pi)
            SetCVar("test_cameraVerticalOffset", baselineVertical + currentVerticalOffset)
        end)
    end

    -- PHASE 2: Smooth Recovery (Return zoom to baseline, reset vertical offset)
    C_Timer.After(duration, function()
        -- Ensure vertical offset is reset to baseline
        SetCVar("test_cameraVerticalOffset", baselineVertical)

        local currentDistance = GetCameraZoom()
        local returnDistance = baselineDistance - currentDistance

        if returnDistance == 0 then return end

        local settleSteps = 15
        local settleDelay = recoveryDuration / settleSteps
        local zoomOutPerStep = returnDistance / settleSteps

        for j = 1, settleSteps do
            C_Timer.After(settleDelay * (j - 1), function()
                CameraZoomOut(zoomOutPerStep)
            end)
        end
    end)

    -- Fallback safety cleanup to guarantee baseline is perfectly restored
    C_Timer.After(duration + recoveryDuration + 0.05, function()
        SetCVar("test_cameraVerticalOffset", baselineVertical)

        local finalDistance = GetCameraZoom()
        local drift = finalDistance - baselineDistance
        if drift > 0 then
            CameraZoomIn(drift)
        elseif drift < 0 then
            CameraZoomOut(math.abs(drift))
        end
    end)
end

-- Register soul_siphon as an Affliction-specific channeled animation handler
Anim:Register("soul_siphon", "UNIT_SPELLCAST_CHANNEL_START", PlaySoulSiphon)

-- Dark Harvest profile (shared across alternative IDs)
local DarkHarvestProfile = {
    {
        type = "soul_siphon",
        zoomInAmount = 1.4,       -- Max depth of the channel zoom-in (yards)
        pulseHeight = 1.2,        -- Vertical bobbing amplitude (yards)
        pulseStrength = 0.8,      -- Zoom velocity pulse strength (must be < 1.0 for smoothness)
        numPulses = 3,            -- Number of vertical bobbing cycles
        recoveryDuration = 0.50,  -- Time to smoothly return to baseline zoom (seconds)
    }
}

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
    -- Dark Harvest (Channeled Soul Siphon)
    [1257052] = DarkHarvestProfile,
    [387166] = DarkHarvestProfile,
    [447784] = DarkHarvestProfile,
}

SpellEffects:RegisterProfiles(AfflictionProfiles)
