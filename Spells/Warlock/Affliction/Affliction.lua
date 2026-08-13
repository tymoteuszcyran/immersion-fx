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

-- Channeled Ethereal Crane Camera Sequence (Subtle, slow linear zoom-in and vertical crane lift)
local function PlayEtherealCrane(effectData, dynamicDuration)
    if not IFX.Config:IsEffectTypeEnabled("camera") then return end

    local duration = dynamicDuration or effectData.duration or 5.0
    local intensity = IFX.Config:GetIntensity()
    local zoomInAmount = (effectData.zoomInAmount or 0.8) * intensity
    local liftHeight = (effectData.liftHeight or 0.5) * intensity
    local recoveryDuration = effectData.recoveryDuration or 0.5

    -- 1. Capture baseline state
    local baselineVertical = tonumber(GetCVar("test_cameraVerticalOffset")) or 0
    local baselineDistance = GetCameraZoom()

    -- PHASE 1: The Ethereal Crane Rise (Slow linear zoom-in + vertical lift)
    local steps = 30
    local stepDelay = duration / steps
    local zoomPerStep = zoomInAmount / steps

    for i = 1, steps do
        C_Timer.After(stepDelay * (i - 1), function()
            local t = i / steps
            -- Zoom in (unidirectional)
            CameraZoomIn(zoomPerStep)
            -- Vertical lift (linear increase)
            SetCVar("test_cameraVerticalOffset", baselineVertical + (liftHeight * t))
        end)
    end

    -- PHASE 2: Smooth Recovery (Return zoom and height back to baseline)
    C_Timer.After(duration, function()
        local currentDistance = GetCameraZoom()
        local returnDistance = baselineDistance - currentDistance

        local settleSteps = 15
        local settleDelay = recoveryDuration / settleSteps
        local zoomOutPerStep = returnDistance / settleSteps

        for j = 1, settleSteps do
            C_Timer.After(settleDelay * (j - 1), function()
                local t = j / settleSteps
                -- Smoothly lower the vertical height back to baseline
                SetCVar("test_cameraVerticalOffset", baselineVertical + (liftHeight * (1 - t)))
                -- Zoom out back to baseline
                if zoomOutPerStep > 0 then
                    CameraZoomOut(zoomOutPerStep)
                end
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

-- Register ethereal_crane as an Affliction-specific channeled animation handler
Anim:Register("ethereal_crane", "UNIT_SPELLCAST_CHANNEL_START", PlayEtherealCrane)

-- Track the active cast state for Seed of Corruption to handle cast-recoil and interruptions
local seedCastActive = nil

-- Gravitational Siphon (Seed of Corruption cast charge-up)
local function PlayGravitationalSiphonStart(effectData, dynamicDuration)
    if not IFX.Config:IsEffectTypeEnabled("camera") then return end

    local castDuration = dynamicDuration or effectData.castDuration or 2.5
    local intensity = IFX.Config:GetIntensity()
    local driftOutAmount = (effectData.driftOut or 1.8) * intensity

    -- Capture baseline state
    local baselineDistance = GetCameraZoom()

    seedCastActive = {
        baselineDistance = baselineDistance,
        driftOutAmount = driftOutAmount,
        accumulatedZoomOut = 0,
        isFinished = false
    }

    local currentCast = seedCastActive
    local steps = 25
    local stepDelay = castDuration / steps
    local zoomOutPerStep = driftOutAmount / steps

    -- PHASE 1: The Vacuum Zoom-Out
    for i = 1, steps do
        C_Timer.After(stepDelay * (i - 1), function()
            if seedCastActive == currentCast and not currentCast.isFinished then
                CameraZoomOut(zoomOutPerStep)
                currentCast.accumulatedZoomOut = currentCast.accumulatedZoomOut + zoomOutPerStep
            end
        end)
    end
end

-- Gravitational Siphon Interruption Cleanup
local function StopGravitationalSiphonStart(effectData)
    if not seedCastActive then return end

    local currentCast = seedCastActive
    currentCast.isFinished = true
    seedCastActive = nil

    local accumulatedZoom = currentCast.accumulatedZoomOut
    local recoveryDuration = 0.3

    if accumulatedZoom > 0 then
        local steps = 10
        local stepDelay = recoveryDuration / steps
        local zoomInPerStep = accumulatedZoom / steps

        for i = 1, steps do
            C_Timer.After(stepDelay * (i - 1), function()
                CameraZoomIn(zoomInPerStep)
            end)
        end
    end

    -- Safety check to ensure perfect baseline return after recovery
    C_Timer.After(recoveryDuration + 0.05, function()
        local finalDistance = GetCameraZoom()
        local drift = finalDistance - currentCast.baselineDistance
        if drift > 0 then
            CameraZoomIn(drift)
        elseif drift < 0 then
            CameraZoomOut(math.abs(drift))
        end
    end)
end

-- Gravitational Siphon Release (Seed of Corruption launch / instant cast success)
local function PlayGravitationalSiphonSuccess(effectData)
    if not IFX.Config:IsEffectTypeEnabled("camera") then return end

    local intensity = IFX.Config:GetIntensity()
    local recoilAmount = (effectData.recoil or 0.6) * intensity
    local shakeDuration = effectData.shakeDuration or 0.15
    local recoveryDuration = 0.25

    local baselineVertical = tonumber(GetCVar("test_cameraVerticalOffset")) or 0
    local baselineDistance = GetCameraZoom()
    local targetBaseline = baselineDistance

    -- 1. CAMERA DISTANCE MOVEMENT
    if seedCastActive then
        -- Casted Path: Snappy snapback to baseline
        local currentCast = seedCastActive
        currentCast.isFinished = true
        seedCastActive = nil -- clear active cast reference

        targetBaseline = currentCast.baselineDistance
        local accumulatedZoom = currentCast.accumulatedZoomOut

        if accumulatedZoom > 0 then
            local steps = 10
            local stepDelay = recoveryDuration / steps
            local zoomInPerStep = accumulatedZoom / steps

            for i = 1, steps do
                C_Timer.After(stepDelay * (i - 1), function()
                    CameraZoomIn(zoomInPerStep)
                end)
            end
        end
    else
        -- Instant Path: Quick recoil pulse (zoom-in then zoom-out)
        CameraZoomIn(recoilAmount)
        C_Timer.After(0.08, function()
            CameraZoomOut(recoilAmount)
        end)
    end

    -- 2. HEAVY IMPACT SHUDDER (Vertical offset shift)
    SetCVar("test_cameraVerticalOffset", baselineVertical - (0.4 * intensity))
    
    C_Timer.After(0.05, function()
        SetCVar("test_cameraVerticalOffset", baselineVertical + (0.2 * intensity))
    end)

    C_Timer.After(0.10, function()
        SetCVar("test_cameraVerticalOffset", baselineVertical)
    end)

    -- Fallback safety cleanup to guarantee baseline vertical and zoom are restored
    C_Timer.After(recoveryDuration + 0.05, function()
        SetCVar("test_cameraVerticalOffset", baselineVertical)

        local finalDistance = GetCameraZoom()
        local drift = finalDistance - targetBaseline
        if drift > 0 then
            CameraZoomIn(drift)
        elseif drift < 0 then
            CameraZoomOut(math.abs(drift))
        end
    end)
end

-- Register Gravitational Siphon animation handlers
Anim:Register("gravitational_siphon_start", "UNIT_SPELLCAST_START", PlayGravitationalSiphonStart, StopGravitationalSiphonStart)
Anim:Register("gravitational_siphon_success", "UNIT_SPELLCAST_SUCCEEDED", PlayGravitationalSiphonSuccess)

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

-- Drain Soul profile (Ethereal Crane)
local DrainSoulProfile = {
    {
        type = "ethereal_crane",
        duration = 5.0,           -- Standard baseline duration for Drain Soul channel (seconds)
        zoomInAmount = 0.8,       -- Very subtle linear zoom-in (yards)
        liftHeight = 0.5,         -- Very subtle vertical crane lift (yards)
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
    
    -- Drain Soul (Channeled Ethereal Crane)
    [198590] = DrainSoulProfile,

    -- Seed of Corruption (Gravitational Siphon & Recoil)
    [27243] = {
        {
            type = "gravitational_siphon_start",
            driftOut = 1.8,
        },
        {
            type = "gravitational_siphon_success",
            recoil = 0.6,
            shakeDuration = 0.15,
        }
    },
}

SpellEffects:RegisterProfiles(AfflictionProfiles)
