local addonName, IFX = ...
local SpellEffects = IFX.SpellEffects
local Anim = IFX.Animation

-- Pure Kinetic Camera Sequence (Central Zoom & Recoil with Bulletproof Overshoot)
local function PlayCinematicShake(effectData, dynamicDuration)
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
        -- Note: Chaos Bolt configuration recoil uses recoil parameter, but the bulletproof
        -- overshoot implementation uses baseline correction. If recoil is specified, we can use it or fallback to overshoot.
        local recoilAmount = (effectData.recoil or 4.0) * IFX.Config:GetIntensity()
        local pushbackAmount = math.max(distanceToBaseline + overshootAmount, recoilAmount)

        if pushbackAmount > 0 then
            CameraZoomOut(pushbackAmount)
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

-- Register cinematic_shake as a Destruction-specific animation handler
Anim:Register("cinematic_shake", "UNIT_SPELLCAST_START", PlayCinematicShake)

-- Warlock Destruction specialization spells
local DestructionProfiles = {
    -- Chaos Bolt: Cinematic Sequence
    [116858] = {
        {
            type = "cinematic_shake",
            chargeDuration = 2.0,   -- Time it takes to cast the spell
            zoomIn = 2.0,           -- How claustrophobic the zoom gets
            recoil = 4.5,           -- The violent kickback distance
        },
    },
}

SpellEffects:RegisterProfiles(DestructionProfiles)
