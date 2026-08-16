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

-- Suppress Blizzard's recurring ActionCam / experimental CVar confirmation popup on reload/login
function Core:SuppressExperimentalWarnings()
    -- Unregister event from UIParent to prevent Blizzard from triggering the dialog
    if UIParent and UIParent.UnregisterEvent then
        UIParent:UnregisterEvent("EXPERIMENTAL_CVAR_CONFIRMATION_NEEDED")
    end

    -- Keep StaticPopupDialogs definition valid to avoid modern 11.x assertion errors,
    -- but ensure it hides immediately if shown
    if StaticPopupDialogs then
        if not StaticPopupDialogs["EXPERIMENTAL_CVAR_WARNING"] then
            StaticPopupDialogs["EXPERIMENTAL_CVAR_WARNING"] = {
                text = "",
                button1 = OKAY or "OK",
                timeout = 0,
                whileDead = 1,
                hideOnEscape = 1,
            }
        end
        StaticPopupDialogs["EXPERIMENTAL_CVAR_WARNING"].OnShow = function(self)
            self:Hide()
        end
    end

    -- Hook StaticPopup_Show to immediately dismiss the popup
    if not self.hookedStaticPopup and type(hooksecurefunc) == "function" then
        self.hookedStaticPopup = true
        hooksecurefunc("StaticPopup_Show", function(which)
            if which == "EXPERIMENTAL_CVAR_WARNING" then
                if type(StaticPopup_Hide) == "function" then
                    StaticPopup_Hide("EXPERIMENTAL_CVAR_WARNING")
                end
            end
        end)
    end

    if type(StaticPopup_Hide) == "function" then
        StaticPopup_Hide("EXPERIMENTAL_CVAR_WARNING")
    end
end

-- Suppress immediately upon file execution in case popup triggers early
Core:SuppressExperimentalWarnings()

-- Initialization function (called on ADDON_LOADED)
function Core:Initialize()
    self:SuppressExperimentalWarnings()
    -- Delegate database setup to Config.lua
    IFX.Config:InitializeDB()
    IFX:Log("Initialization complete. DB loaded.")
end

-- Startup function (called on PLAYER_LOGIN)
function Core:OnLogin()
    self:SuppressExperimentalWarnings()
    -- Initialize Camera placement, UI settings, and options panel
    if IFX.Config and IFX.Config.ApplyUISettings then
        IFX.Config:ApplyUISettings()
    end
    if IFX.Camera and IFX.Camera.Initialize then
        IFX.Camera:Initialize()
    end
    if IFX.UI and IFX.UI.CreateOptionsPanel then
        IFX.UI:CreateOptionsPanel()
    end
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

    if msg == "config" or msg == "options" or msg == "menu" or msg == "gui" then
        if IFX.UI and IFX.UI.OpenSettings then
            IFX.UI:OpenSettings()
        end
    elseif msg == "debug" then
        IFX.db.global.debugMode = not IFX.db.global.debugMode
        print("|cff00ccff[IFX]|r Debug mode is now " .. (IFX.db.global.debugMode and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
    elseif msg == "toggle" then
        IFX.db.global.enabled = not IFX.db.global.enabled
        print("|cff00ccff[IFX]|r Effects are now " .. (IFX.db.global.enabled and "|cff00ff00ENABLED|r" or "|cffff0000DISABLED|r"))
    elseif msg == "camera" then
        local current = IFX.Config:IsCameraPlacementEnabled()
        IFX.Config:SetCameraPlacementEnabled(not current)
        IFX.Camera:Refresh()
        print("|cff00ccff[IFX]|r Camera placement is now " .. (not current and "|cff00ff00ENABLED|r" or "|cffff0000DISABLED|r"))
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
        print("  /ifx config - Open the settings panel GUI")
        print("  /ifx camera - Toggle custom camera placement on/off")
        print("  /ifx toggle - Enable or disable all effects")
        print("  /ifx debug  - Toggle debug logging")
        print("  /ifx test   - Test default spell (Death Strike)")
        print("  /ifx test <spellID> - Test a specific spell ID")
    end
end