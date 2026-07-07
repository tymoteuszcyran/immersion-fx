local addonName, IFX = ...
local Events = IFX.Events

local EventFrame = CreateFrame("Frame", "ImmersionFXEventFrame", UIParent)

EventFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
EventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")

EventFrame:SetScript("OnEvent", function(self, event, unit, castGUID, spellID)
    if not IFX.Config:IsEnabled() then return end

    local dynamicDuration = nil

    -- If a spell is starting, ask the server exactly how long it will take
    if event == "UNIT_SPELLCAST_START" then
        local name, text, texture, startTime, endTime = UnitCastingInfo("player")
        if startTime and endTime then
            -- The API returns milliseconds, so we divide by 1000 for seconds
            dynamicDuration = (endTime - startTime) / 1000
        end
    end

    -- Pass the dynamic duration to the engine along with the spell ID
    IFX.Engine:PlaySpell(spellID, event, dynamicDuration)
end)