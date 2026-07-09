local addonName, IFX = ...
local SpellEffects = IFX.SpellEffects
local Anim = IFX.Animation

-- Jump and Slam camera animation for heavy strikes (e.g. Death Strike)
local function PlayVampiricStrike(effectData)
    if not IFX.Config:IsEffectTypeEnabled("camera") then return end

    local intensity = (effectData.intensityMultiplier or 1.0) * IFX.Config:GetIntensity()

    -- Configurable timing and distance parameters
    local jumpHeight = (effectData.jumpHeight or 0.8) * intensity
    local jumpZoomOut = (effectData.jumpZoomOut or 0.4) * intensity
    local slamDrop = (effectData.slamDrop or 1.0) * intensity
    local slamZoomIn = (effectData.slamZoomIn or 1.4) * intensity

    local jumpDuration = effectData.jumpDuration or 0.12
    local holdDuration = effectData.holdDuration or 0.05
    local recoveryDuration = effectData.recoveryDuration or 0.28

    -- Capture baseline state
    local baselineVertical = tonumber(GetCVar("test_cameraVerticalOffset")) or 0
    local baselineDistance = GetCameraZoom()

    -- PHASE 1: The Jump (Camera rises slightly and zooms out to capture character movement)
    CameraZoomOut(jumpZoomOut)
    SetCVar("test_cameraVerticalOffset", baselineVertical + jumpHeight)

    -- PHASE 2: The Slam Impact (Triggered when the jump animation lands)
    C_Timer.After(jumpDuration, function()
        -- Camera drops below baseline for a heavy landing feel
        SetCVar("test_cameraVerticalOffset", baselineVertical - slamDrop)

        -- Rapid zoom-in past baseline to sell the heavy blow
        CameraZoomIn(jumpZoomOut + slamZoomIn)

        -- PHASE 3: Smooth Recovery (Interpolates camera back to baseline)
        local steps = 10
        local stepDelay = recoveryDuration / steps
        local verticalRaisePerStep = slamDrop / steps
        local zoomOutPerStep = slamZoomIn / steps

        for i = 1, steps do
            C_Timer.After(holdDuration + (stepDelay * (i - 1)), function()
                CameraZoomOut(zoomOutPerStep)
                local currentVertical = (baselineVertical - slamDrop) + (verticalRaisePerStep * i)
                SetCVar("test_cameraVerticalOffset", currentVertical)
            end)
        end
    end)

    -- Fallback safety cleanup to guarantee baseline is perfectly restored
    C_Timer.After(jumpDuration + holdDuration + recoveryDuration + 0.05, function()
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

-- Magnetic Pull & Impact Collision camera animation for Death Grip
local function PlayGripCollision(effectData)
    if not IFX.Config:IsEffectTypeEnabled("camera") then return end

    local intensity = (effectData.intensityMultiplier or 1.0) * IFX.Config:GetIntensity()

    local pullZoomOut = (effectData.pullZoomOut or 1.2) * intensity
    local pullDuration = effectData.pullDuration or 0.30
    local impactZoomIn = (effectData.impactZoomIn or 0.8) * intensity
    local impactVerticalDrop = (effectData.impactVerticalDrop or 0.6) * intensity
    local holdDuration = effectData.holdDuration or 0.05
    local recoveryDuration = effectData.recoveryDuration or 0.25

    -- Capture baseline state
    local baselineVertical = tonumber(GetCVar("test_cameraVerticalOffset")) or 0
    local baselineDistance = GetCameraZoom()

    -- PHASE 1: The Pull (Camera zooms out to frame the incoming target)
    CameraZoomOut(pullZoomOut)

    -- PHASE 2: The Impact (When target reaches player)
    C_Timer.After(pullDuration, function()
        -- Camera drops slightly for slam/grounding feel
        SetCVar("test_cameraVerticalOffset", baselineVertical - impactVerticalDrop)

        -- Quick zoom-in past baseline to sell collision impact
        CameraZoomIn(pullZoomOut + impactZoomIn)

        -- PHASE 3: Smooth Recovery (Interpolates camera back to baseline)
        local steps = 10
        local stepDelay = recoveryDuration / steps
        local verticalRaisePerStep = impactVerticalDrop / steps
        local zoomOutPerStep = impactZoomIn / steps

        for i = 1, steps do
            C_Timer.After(holdDuration + (stepDelay * (i - 1)), function()
                CameraZoomOut(zoomOutPerStep)
                local currentVertical = (baselineVertical - impactVerticalDrop) + (verticalRaisePerStep * i)
                SetCVar("test_cameraVerticalOffset", currentVertical)
            end)
        end
    end)

    -- Fallback safety cleanup to guarantee baseline is perfectly restored
    C_Timer.After(pullDuration + holdDuration + recoveryDuration + 0.05, function()
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

-- Register class-wide DK animation handlers
Anim:Register("vampiric_strike", "UNIT_SPELLCAST_SUCCEEDED", PlayVampiricStrike)
Anim:Register("grip_collision", "UNIT_SPELLCAST_SUCCEEDED", PlayGripCollision)

-- Death Knight Common Spells Configuration
local DKCommonProfiles = {
    -- Death Strike (Instant-cast heavy strike with life siphon)
    [49998] = {
        {
            type = "vampiric_strike",
            intensityMultiplier = 1.0,
            jumpHeight = 0.8,
            jumpZoomOut = 0.4,
            slamDrop = 1.0,
            slamZoomIn = 1.4,
            jumpDuration = 0.12,
            holdDuration = 0.05,
            recoveryDuration = 0.28,
        }
    },
    -- Death Grip (Ranged pull with impact collision)
    [49576] = {
        {
            type = "grip_collision",
            intensityMultiplier = 1.0,
            pullZoomOut = 1.2,
            pullDuration = 0.30,
            impactZoomIn = 0.8,
            impactVerticalDrop = 0.6,
            holdDuration = 0.05,
            recoveryDuration = 0.25,
        }
    }
}

SpellEffects:RegisterProfiles(DKCommonProfiles)
