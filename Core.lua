local addonName, IFX = ...

-- Initialize the Core namespace
IFX.Core = {}
local Core = IFX.Core

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
    elseif msg == "test" then
        -- Placeholder for testing the engine later
        print("|cff00ccff[IFX]|r Test command triggered. (EffectEngine not yet implemented)")
    else
        print("|cff00ccff[ImmersionFX]|r Commands:")
        print("  /ifx toggle - Enable or disable all effects")
        print("  /ifx debug  - Toggle debug logging")
        print("  /ifx test   - Test the current spell effect profile")
    end
end