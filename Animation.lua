local addonName, IFX = ...

IFX.Animation = {}
local Anim = IFX.Animation


-- Spectral Reverse Drift for Ghostly/Spiritual Casts (Haunt)
function Anim:PlaySpectralDrift(effectData, dynamicDuration)
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

-- Pure Kinetic Camera Sequence (Central Zoom & Recoil)
function Anim:PlayCinematicShake(effectData, dynamicDuration)
    local chargeDuration = dynamicDuration or effectData.chargeDuration or 2.0
    local zoomInAmount = (effectData.zoomIn or 2.5) * IFX.Config:GetIntensity()
    local recoilAmount = (effectData.recoil or 4.0) * IFX.Config:GetIntensity()

    -- PHASE 1 & 2: Smooth Central Zoom-In Build-Up
    local steps = 30
    local stepDelay = chargeDuration / steps
    local zoomPerStep = zoomInAmount / steps

    for i = 1, steps do
        C_Timer.After(stepDelay * (i - 1), function()
            CameraZoomIn(zoomPerStep)
        end)
    end

    -- PHASE 3: The Release (Violent Recoil & Recovery)
    C_Timer.After(chargeDuration, function()
        CameraZoomOut(recoilAmount)

        -- Smooth recovery zoom ease-in back to baseline
        local recoverySteps = 10
        local recoveryDelay = 0.5 / recoverySteps
        local recoveryZoom = (recoilAmount - zoomInAmount) / recoverySteps

        for j = 1, recoverySteps do
            C_Timer.After(recoveryDelay * j, function()
                CameraZoomIn(recoveryZoom)
            end)
        end
    end)
end


-- Pure Kinetic Camera Sequence (Central Zoom & Recoil with Bulletproof Overshoot)
function Anim:PlayCinematicShake(effectData, dynamicDuration)
    local chargeDuration = dynamicDuration or effectData.chargeDuration or 2.0
    local zoomInAmount = (effectData.zoomIn or 2.5) * IFX.Config:GetIntensity()
    
    -- How far the camera violently blasts PAST your baseline on release
    local overshootAmount = 1.2 * IFX.Config:GetIntensity()

    -- 1. Lock the absolute baseline distance before the cast begins
    local baselineDistance = GetCameraZoom()

    -- PHASE 1: The Build-Up (Slow track-in during the cast)
    local steps = 30
    local stepDelay = chargeDuration / steps
    local zoomPerStep = zoomInAmount / steps

    for i = 1, steps do
        C_Timer.After(stepDelay * (i - 1), function()
            CameraZoomIn(zoomPerStep)
        end)
    end

    -- PHASE 2: The Explosive Release (Blast past the baseline)
    C_Timer.After(chargeDuration, function()
        local currentDistance = GetCameraZoom()
        local distanceToBaseline = baselineDistance - currentDistance

        -- Total pushback = the distance lost during cast + the extra overshoot bump
        local totalPushback = distanceToBaseline + overshootAmount

        if totalPushback > 0 then
            CameraZoomOut(totalPushback)
        end

        -- PHASE 3: The Elastic Settle (Smoothly pull back to perfect baseline)
        -- 0.20s allows the camera to reach the peak of the overshoot without grinding gears
        C_Timer.After(0.20, function()
            local finalDistance = GetCameraZoom()
            local finalCorrection = finalDistance - baselineDistance

            if finalCorrection > 0 then
                CameraZoomIn(finalCorrection)
            elseif finalCorrection < 0 then
                CameraZoomOut(math.abs(finalCorrection))
            end
        end)
    end)
end

-- NEW: Heavy Grounded Vertical Cleave for Obliterate
function Anim:PlayHeavyCleave(effectData)
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