local addonName, IFX = ...

-- Initialize the Camera namespace
IFX.Camera = {
    Profiles = {},
    ProfileOrder = {},
    activeProfileId = nil,
    baselineCVars = nil,
    isApplied = false,
}
local Camera = IFX.Camera

-- List of CVars managed across camera profiles
local MANAGED_CVARS = {
    "test_cameraOverShoulder",
    "test_cameraVerticalOffset",
    "test_cameraDynamicPitch",
    "test_cameraDynamicPitchBaseFov",
    "test_cameraHeadMovement",
}

-- Capture the player's current CVars before modifying them
local function CaptureBaselineCVars()
    if Camera.baselineCVars then return end
    
    Camera.baselineCVars = {}
    for _, cvar in ipairs(MANAGED_CVARS) do
        local val = GetCVar(cvar)
        Camera.baselineCVars[cvar] = val
    end
end

-- ==========================================
-- Profile Registration API
-- ==========================================

--- Registers a new camera placement profile.
--- @param id string Unique identifier for the profile (e.g., "high_immersion")
--- @param data table Profile definition with { name, description, cvars = { cvarName = value } }
function Camera:RegisterProfile(id, data)
    if not id or type(data) ~= "table" then
        IFX:Log("Failed to register camera profile: invalid arguments", true)
        return
    end

    if not self.Profiles[id] then
        table.insert(self.ProfileOrder, id)
    end

    self.Profiles[id] = {
        id = id,
        name = data.name or id,
        description = data.description or "",
        cvars = data.cvars or {},
    }

    IFX:Log("Registered Camera Profile: " .. tostring(id))
end

--- Returns a list of all registered profiles in order.
--- @return table Array of profile definition tables
function Camera:GetProfileList()
    local list = {}
    for _, id in ipairs(self.ProfileOrder) do
        local profile = self.Profiles[id]
        if profile then
            table.insert(list, profile)
        end
    end
    return list
end

--- Returns a specific profile by ID.
--- @param id string
--- @return table|nil
function Camera:GetProfile(id)
    return self.Profiles[id]
end

-- ==========================================
-- Application & Reversion Engine
-- ==========================================

--- Applies a registered camera profile by setting its CVars.
--- @param profileId string
function Camera:ApplyProfile(profileId)
    local profile = self.Profiles[profileId]
    if not profile then
        IFX:Log("Camera profile not found: " .. tostring(profileId), true)
        return
    end

    -- Snapshot baseline if not already captured
    CaptureBaselineCVars()

    -- Apply profile CVars
    for cvar, value in pairs(profile.cvars) do
        pcall(SetCVar, cvar, tostring(value))
    end

    self.activeProfileId = profileId
    self.isApplied = true
    IFX:Log("Applied Camera Profile: " .. profile.name)
end

--- Restores baseline CVars back to original player values.
function Camera:RevertToBaseline()
    if not self.isApplied or not self.baselineCVars then return end

    for cvar, baselineVal in pairs(self.baselineCVars) do
        if baselineVal ~= nil then
            pcall(SetCVar, cvar, tostring(baselineVal))
        end
    end

    self.isApplied = false
    self.activeProfileId = nil
    IFX:Log("Restored camera CVars to baseline.")
end

--- Synchronizes the camera state with the current SavedVariables configuration.
function Camera:Refresh()
    if not IFX.Config then return end

    local isEnabled = IFX.Config:IsCameraPlacementEnabled()
    local activeProfile = IFX.Config:GetCameraActiveProfile()

    if isEnabled and activeProfile and self.Profiles[activeProfile] then
        self:ApplyProfile(activeProfile)
    else
        self:RevertToBaseline()
    end
end

-- ==========================================
-- Initialization
-- ==========================================

function Camera:Initialize()
    -- Sync camera state on load
    self:Refresh()
    IFX:Log("Camera module initialized.")
end
