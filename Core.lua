local addonName, IFX = ...

-- Initialize the Core namespace
IFX.Core = {}
local Core = IFX.Core

-- Initialize the Animation namespace and dynamic registration API
IFX.Animation = {
    Handlers = {}
}

function IFX.Animation:Register(name, eventType, func, stopFunc)
    self.Handlers[name] = {
        eventType = eventType,
        func = func,
        stopFunc = stopFunc
    }
end

-- Create the main hidden frame for event handling and updates
Core.Frame = CreateFrame("Frame", "ImmersionFXMainFrame", UIParent)

-- Basic logging system
function IFX:Log(message, isError)
    -- Only show logs if debug mode is on, unless it's a forced error
    if not (self.db and self.db.global.debugMode) and not isError then return end
    
    local prefix = isError and "|cffff0000[IFX Error]|r" or "|cff00ccff[IFX Debug]|r"
    print(prefix .. " " .. tostring(message))
end

-- Initialization function (called on ADDON_LOADED)
function Core:Initialize()
    -- Delegate database setup to Config.lua
    IFX.Config:InitializeDB()
    IFX:Log("Initialization complete. DB loaded.")
end

-- Startup function (called on PLAYER_LOGIN)
function Core:OnLogin()
    -- We will call setup methods for other modules (like Overlay) here later
    print("|cff00ccff[ImmersionFX]|r Loaded successfully. Type /ifx for options.")
end

-- Event Router for Core initialization
Core.Frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == addonName then
            Core:Initialize()
            self:UnregisterEvent("ADDON_LOADED")
        end
    elseif event == "PLAYER_LOGIN" then
        Core:OnLogin()
        self:UnregisterEvent("PLAYER_LOGIN")
    end
end)

-- Register the startup events
Core.Frame:RegisterEvent("ADDON_LOADED")
Core.Frame:RegisterEvent("PLAYER_LOGIN")

-- ==========================================
-- Slash Commands (/ifx)
-- ==========================================
SLASH_IMMERSIONFX1 = "/ifx"
SLASH_IMMERSIONFX2 = "/immersionfx"

SlashCmdList["IMMERSIONFX"] = function(msg)
    -- Clean up the input string
    msg = msg and string.lower(strtrim(msg)) or ""

    if msg == "debug" then
        IFX.db.global.debugMode = not IFX.db.global.debugMode
        print("|cff00ccff[IFX]|r Debug mode is now " .. (IFX.db.global.debugMode and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
    elseif msg == "toggle" then
        IFX.db.global.enabled = not IFX.db.global.enabled
        print("|cff00ccff[IFX]|r Effects are now " .. (IFX.db.global.enabled and "|cff00ff00ENABLED|r" or "|cffff0000DISABLED|r"))
    elseif msg == "test" or msg:find("^test%s+") then
        local targetID = tonumber(msg:match("^test%s+(%d+)"))
        if targetID then
            print("|cff00ccff[IFX]|r Testing Spell ID " .. targetID .. "...")
            local profile = IFX.SpellEffects:GetProfile(targetID)
            if profile then
                for _, effect in ipairs(profile) do
                    local handler = IFX.Animation.Handlers[effect.type]
                    if handler then
                        local simulatedDuration = nil
                        if handler.eventType == "UNIT_SPELLCAST_CHANNEL_START" then
                            simulatedDuration = 3.0
                        elseif handler.eventType == "UNIT_SPELLCAST_START" then
                            simulatedDuration = 1.5
                        end
                        handler.func(effect, simulatedDuration)
                    else
                        print("|cffff0000[IFX Error]|r No animation handler registered for effect: " .. tostring(effect.type))
                    end
                end
            else
                print("|cffff0000[IFX Error]|r No spell profile found for ID " .. targetID)
            end
        else
            print("|cff00ccff[IFX]|r Testing Death Strike (Spell ID 49998)...")
            IFX.Engine:PlaySpell(49998, "UNIT_SPELLCAST_SUCCEEDED")
        end
    else
        print("|cff00ccff[ImmersionFX]|r Commands:")
        print("  /ifx toggle - Enable or disable all effects")
        print("  /ifx debug  - Toggle debug logging")
        print("  /ifx test   - Test default spell (Death Strike)")
        print("  /ifx test <spellID> - Test a specific spell ID (e.g., 1257052 for Dark Harvest)")
    end
end