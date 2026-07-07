local addonName, IFX = ...

-- Initialize the Config namespace
IFX.Config = {}
local Config = IFX.Config

-- Define the default settings structure
Config.Defaults = {
    global = {
        enabled = true,
        debugMode = false,
        intensityMultiplier = 1.0, -- Master control for effect strength (alpha/scale)
        
        -- Toggles for specific effect types
        -- Allows users to disable specific things (e.g., if flashes give them eye strain)
        enableFlashes = true,
        enablePulses = true,
        enableVignettes = true,
        enableCamera = true,
        enableSounds = true,
    }
}

-- Deep merge function
-- Ensures that if we add new features in v0.0.2, existing users automatically get the new defaults 
-- without wiping out their saved settings.
local function CopyDefaults(dest, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dest[k]) ~= "table" then
                dest[k] = {}
            end
            CopyDefaults(dest[k], v)
        elseif dest[k] == nil then
            dest[k] = v
        end
    end
end

-- Called by Core.lua during the ADDON_LOADED event
function Config:InitializeDB()
    if type(ImmersionFXDB) ~= "table" then
        ImmersionFXDB = {}
    end
    
    -- Merge defaults into the SavedVariables
    CopyDefaults(ImmersionFXDB, Config.Defaults)
    
    -- Link to the main addon table for fast access
    IFX.db = ImmersionFXDB
end

-- ==========================================
-- Settings API
-- ==========================================
-- Other modules should use these methods rather than reading IFX.db directly, 
-- which keeps our architecture decoupled.

function Config:IsEnabled()
    return IFX.db.global.enabled
end

function Config:GetIntensity()
    return IFX.db.global.intensityMultiplier
end

function Config:IsEffectTypeEnabled(effectType)
    local keys = {
        flash = "enableFlashes",
        pulse = "enablePulses",
        vignette = "enableVignettes",
        camera = "enableCamera",
        sound = "enableSounds"
    }
    
    local key = keys[effectType]
    if key and IFX.db.global[key] ~= nil then
        return IFX.db.global[key]
    end
    
    return true -- Default to true if the type isn't tracked
end