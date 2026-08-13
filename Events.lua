local addonName, IFX = ...
local Events = IFX.Events

local EventFrame = CreateFrame("Frame", "ImmersionFXEventFrame", UIParent)

EventFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
EventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
EventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
EventFrame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player")

EventFrame:SetScript("OnEvent", function(self, event, unit, castGUID, spellID)
    if not IFX.Config:IsEnabled() then return end

    if event == "UNIT_SPELLCAST_STOP" then
        IFX.Engine:StopSpell(spellID, event)
        return
    end

    local dynamicDuration = nil

    -- If a spell is starting or channeling, ask the server exactly how long it will take
    if event == "UNIT_SPELLCAST_START" then
        local startTime, endTime
        if C_Spell and C_Spell.GetSpellCastInfo then
            local info = C_Spell.GetSpellCastInfo("player")
            if info then
                startTime, endTime = info.startTime, info.endTime
            end
        end
        if not (startTime and endTime) and UnitCastingInfo then
            _, _, _, startTime, endTime = UnitCastingInfo("player")
        end
        if startTime and endTime then
            -- The API returns milliseconds, so we divide by 1000 for seconds
            dynamicDuration = (endTime - startTime) / 1000
        end
    elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
        local startTime, endTime
        if C_Spell and C_Spell.GetSpellChannelInfo then
            local info = C_Spell.GetSpellChannelInfo("player")
            if info then
                startTime, endTime = info.startTime, info.endTime
            end
        end
        if not (startTime and endTime) and UnitChannelInfo then
            _, _, _, startTime, endTime = UnitChannelInfo("player")
        end
        if startTime and endTime then
            -- The API returns milliseconds, so we divide by 1000 for seconds
            dynamicDuration = (endTime - startTime) / 1000
        end
    end

    -- Pass the dynamic duration to the engine along with the spell ID
    IFX.Engine:PlaySpell(spellID, event, dynamicDuration)
end)