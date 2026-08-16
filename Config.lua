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

        -- Baseline Camera Placement Configuration
        cameraPlacement = {
            enabled = false,
            activeProfile = "high_immersion",
            baselineCVars = {},
        },

        -- UI & Text Configuration
        ui = {
            floatingTextScale = 1.0, -- In-world floating combat text scale (WorldTextScale_v2)
        },
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

function Config:SetEnabled(enabled)
    IFX.db.global.enabled = enabled
end

function Config:GetIntensity()
    return IFX.db.global.intensityMultiplier
end

function Config:SetIntensity(val)
    IFX.db.global.intensityMultiplier = math.max(0.1, math.min(2.0, val))
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

function Config:SetEffectTypeEnabled(effectType, enabled)
    local keys = {
        flash = "enableFlashes",
        pulse = "enablePulses",
        vignette = "enableVignettes",
        camera = "enableCamera",
        sound = "enableSounds"
    }
    local key = keys[effectType]
    if key then
        IFX.db.global[key] = enabled
    end
end

-- Camera Placement Settings API
function Config:IsCameraPlacementEnabled()
    return IFX.db and IFX.db.global.cameraPlacement and IFX.db.global.cameraPlacement.enabled or false
end

function Config:SetCameraPlacementEnabled(enabled)
    if IFX.db and IFX.db.global.cameraPlacement then
        IFX.db.global.cameraPlacement.enabled = enabled
    end
end

function Config:GetCameraActiveProfile()
    return IFX.db and IFX.db.global.cameraPlacement and IFX.db.global.cameraPlacement.activeProfile or "high_immersion"
end

function Config:SetCameraActiveProfile(profileId)
    if IFX.db and IFX.db.global.cameraPlacement then
        IFX.db.global.cameraPlacement.activeProfile = profileId
    end
end

-- ==========================================
-- UI Settings API
-- ==========================================

function Config:GetFloatingTextScale()
    if IFX.db and IFX.db.global and IFX.db.global.ui and IFX.db.global.ui.floatingTextScale ~= nil then
        return IFX.db.global.ui.floatingTextScale
    end
    return 1.0
end

function Config:SetFloatingTextScale(scale)
    local num = tonumber(scale) or 1.0
    num = math.max(0.5, math.min(2.5, num))
    if IFX.db and IFX.db.global then
        if not IFX.db.global.ui then
            IFX.db.global.ui = {}
        end
        IFX.db.global.ui.floatingTextScale = num
    end
    pcall(SetCVar, "WorldTextScale_v2", tostring(num))
end

function Config:ApplyUISettings()
    local scale = self:GetFloatingTextScale()
    pcall(SetCVar, "WorldTextScale_v2", tostring(scale))
end