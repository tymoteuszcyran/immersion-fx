local addonName, IFX = ...

-- Initialize the Camera namespace
IFX.Camera = {
    Profiles = {},
    ProfileOrder = {},
    activeProfileId = nil,
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

-- Standard WoW default CVar values as fallback
local DEFAULT_CVARS = {
    test_cameraOverShoulder = "0",
    test_cameraVerticalOffset = "0",
    test_cameraDynamicPitch = "0",
    test_cameraDynamicPitchBaseFov = "100",
    test_cameraHeadMovement = "0",
}

local function GetBaselineDB()
    if IFX.db and IFX.db.global and IFX.db.global.cameraPlacement then
        if not IFX.db.global.cameraPlacement.baselineCVars then
            IFX.db.global.cameraPlacement.baselineCVars = {}
        end
        return IFX.db.global.cameraPlacement.baselineCVars
    end
    return nil
end

-- Capture the player's current CVars before modifying them
local function CaptureBaselineCVars()
    local savedBaselines = GetBaselineDB()
    if not savedBaselines then return end

    -- Check if we already have saved baselines
    local hasAny = false
    for _, _ in pairs(savedBaselines) do
        hasAny = true
        break
    end

    -- If no saved baseline exists, capture current state
    if not hasAny then
        for _, cvar in ipairs(MANAGED_CVARS) do
            local val = GetCVar(cvar)
            savedBaselines[cvar] = val or DEFAULT_CVARS[cvar] or "0"
        end
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

    -- Ensure warning popups are suppressed before applying CVars
    if IFX.Core and IFX.Core.SuppressExperimentalWarnings then
        IFX.Core:SuppressExperimentalWarnings()
    end

    -- Snapshot baseline before first apply
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
    local savedBaselines = GetBaselineDB() or DEFAULT_CVARS

    for _, cvar in ipairs(MANAGED_CVARS) do
        local baselineVal = savedBaselines[cvar] or DEFAULT_CVARS[cvar] or "0"
        pcall(SetCVar, cvar, tostring(baselineVal))
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
    -- Small delay on login to ensure WoW client has finished loading world camera
    C_Timer.After(0.2, function()
        self:Refresh()
    end)
    IFX:Log("Camera module initialized.")
end
