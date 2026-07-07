local addonName, IFX = ...

IFX.Engine = {}
local Engine = IFX.Engine

function Engine:PlaySpell(spellID, eventType, dynamicDuration)
    local profile = IFX.SpellEffects:GetProfile(spellID)
    if not profile then return end

    for _, effect in ipairs(profile) do
        -- Chaos Bolt Route
        if effect.type == "cinematic_shake" and eventType == "UNIT_SPELLCAST_START" then
            IFX.Animation:PlayCinematicShake(effect, dynamicDuration)
            
        -- Wither / Instant Cast Route
        elseif effect.type == "instant_pulse" and eventType == "UNIT_SPELLCAST_SUCCEEDED" then
            IFX.Animation:PlayInstantPulse(effect)
        end
    end
end