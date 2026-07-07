local addonName, IFX = ...

IFX.Animation = {}
local Anim = IFX.Animation

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

-- Snappy Forward-and-Back Cinematic Pulse for Instant Casts
function Anim:PlayInstantPulse(effectData)
    local intensity = (effectData.intensity or 1.2) * IFX.Config:GetIntensity()
    local snapInDuration = effectData.snapInDuration or 0.08
    local fadeOutDuration = effectData.fadeOutDuration or 0.25

    -- PHASE 1: The Snappy Bite (Fast Zoom In)
    CameraZoomIn(intensity)

    -- PHASE 2: The Smooth Release (Gradual Zoom Out back to baseline)
    local steps = 8
    local stepDelay = fadeOutDuration / steps
    local zoomOutPerStep = intensity / steps

    for i = 1, steps do
        C_Timer.After(snapInDuration + (stepDelay * (i - 1)), function()
            CameraZoomOut(zoomOutPerStep)
        end)
    end
end