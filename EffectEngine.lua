local addonName, IFX = ...

IFX.Engine = {}
local Engine = IFX.Engine

function Engine:PlaySpell(spellID, eventType, dynamicDuration)
    local profile = IFX.SpellEffects:GetProfile(spellID)
    if not profile then return end

    for _, effect in ipairs(profile) do
        local handler = IFX.Animation.Handlers[effect.type]
        if handler then
            if handler.eventType == eventType then
                handler.func(effect, dynamicDuration)
            end
        else
            IFX:Log("No animation handler registered for: " .. tostring(effect.type), true)
        end
    end
end

function Engine:StopSpell(spellID, eventType)
    local profile = IFX.SpellEffects:GetProfile(spellID)
    if not profile then return end

    for _, effect in ipairs(profile) do
        local handler = IFX.Animation.Handlers[effect.type]
        if handler and handler.stopFunc then
            handler.stopFunc(effect)
        end
    end
end