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
            
        -- Haunt / Spectral Route
        elseif effect.type == "spectral_drift" and eventType == "UNIT_SPELLCAST_START" then
            IFX.Animation:PlaySpectralDrift(effect, dynamicDuration)
            
        -- Obliterate Route
        elseif effect.type == "heavy_cleave" and eventType == "UNIT_SPELLCAST_SUCCEEDED" then
            IFX.Animation:PlayHeavyCleave(effect)
        end
    end
end