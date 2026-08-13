local addonName, IFX = ...

-- Initialize UI Namespace
IFX.UI = {
    category = nil,
    panel = nil,
}
local UI = IFX.UI

-- Helper to create styled checkbox
local function CreateCheckbox(parent, labelText, initialValue, onClick)
    local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    local textFS = cb.Text or cb.text
    if textFS then
        textFS:SetText(labelText)
        textFS:SetFontObject("GameFontHighlight")
    else
        textFS = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        textFS:SetPoint("LEFT", cb, "RIGHT", 4, 0)
        textFS:SetText(labelText)
        cb.Text = textFS
    end
    cb:SetChecked(initialValue)
    cb:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        onClick(checked)
    end)
    return cb
end

function UI:CreateOptionsPanel()
    if self.panel then return self.panel end

    local panel = CreateFrame("Frame", "ImmersionFXOptionsPanel", UIParent)
    panel.name = "ImmersionFX"
    self.panel = panel

    -- Title
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cff00ccffImmersionFX|r")

    -- Subtitle
    local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    subtitle:SetText("Subtle, immersive camera and combat screen effects.")

    -- Master Enable Checkbox
    local masterToggle = CreateCheckbox(panel, "Enable ImmersionFX Effects", IFX.Config:IsEnabled(), function(checked)
        IFX.Config:SetEnabled(checked)
        IFX:Log("Master effects " .. (checked and "enabled" or "disabled"))
    end)
    masterToggle:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -14)

    -- Divider 1
    local divider = panel:CreateLine()
    divider:SetColorTexture(0.3, 0.3, 0.3, 0.6)
    divider:SetStartPoint("TOPLEFT", masterToggle, "BOTTOMLEFT", 0, -12)
    divider:SetEndPoint("TOPRIGHT", panel, "TOPRIGHT", -16, -96)
    divider:SetThickness(1)

    -- ==========================================
    -- Camera Placement Section
    -- ==========================================
    local cameraHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    cameraHeader:SetPoint("TOPLEFT", masterToggle, "BOTTOMLEFT", 0, -24)
    cameraHeader:SetText("Standard Camera Placement")

    local cameraSubtext = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    cameraSubtext:SetPoint("TOPLEFT", cameraHeader, "BOTTOMLEFT", 0, -4)
    cameraSubtext:SetText("Customize the default camera angle and framing for enhanced combat immersion.")

    -- Camera Placement Enable Checkbox
    local cameraToggle = CreateCheckbox(panel, "Enable Custom Camera Placement", IFX.Config:IsCameraPlacementEnabled(), function(checked)
        IFX.Config:SetCameraPlacementEnabled(checked)
        IFX.Camera:Refresh()
    end)
    cameraToggle:SetPoint("TOPLEFT", cameraSubtext, "BOTTOMLEFT", 0, -10)
    self.cameraToggle = cameraToggle

    -- Profiles Container
    local profilesLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    profilesLabel:SetPoint("TOPLEFT", cameraToggle, "BOTTOMLEFT", 0, -14)
    profilesLabel:SetText("Active Camera Profile:")

    local profileButtons = {}
    local currentActive = IFX.Config:GetCameraActiveProfile()
    local profileList = IFX.Camera:GetProfileList()
    local lastAnchor = profilesLabel

    for i, profile in ipairs(profileList) do
        local radio = CreateFrame("CheckButton", nil, panel, "UIRadioButtonTemplate")
        radio:SetPoint("TOPLEFT", lastAnchor, "BOTTOMLEFT", 10, -8)
        
        local labelFS = radio.Text or radio.text
        if labelFS then
            labelFS:SetText(profile.name)
            labelFS:SetFontObject("GameFontHighlight")
        else
            labelFS = radio:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
            labelFS:SetPoint("LEFT", radio, "RIGHT", 4, 0)
            labelFS:SetText(profile.name)
            radio.Text = labelFS
        end
        radio:SetChecked(profile.id == currentActive)

        local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        desc:SetPoint("TOPLEFT", labelFS, "BOTTOMLEFT", 0, -4)
        desc:SetText(profile.description)
        desc:SetWidth(480)
        desc:SetJustifyH("LEFT")

        radio:SetScript("OnClick", function(self)
            for _, btn in ipairs(profileButtons) do
                btn:SetChecked(false)
            end
            self:SetChecked(true)
            IFX.Config:SetCameraActiveProfile(profile.id)
            IFX.Camera:Refresh()
        end)

        table.insert(profileButtons, radio)
        lastAnchor = desc
    end
    self.profileButtons = profileButtons

    -- Register with Blizzard Settings UI
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, "ImmersionFX")
        Settings.RegisterAddOnCategory(category)
        self.category = category
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end

    -- Refresh UI values whenever the panel is shown
    panel:SetScript("OnShow", function()
        masterToggle:SetChecked(IFX.Config:IsEnabled())
        if self.cameraToggle then
            self.cameraToggle:SetChecked(IFX.Config:IsCameraPlacementEnabled())
        end
        local active = IFX.Config:GetCameraActiveProfile()
        for i, btn in ipairs(self.profileButtons) do
            local p = profileList[i]
            if p then
                btn:SetChecked(p.id == active)
            end
        end
    end)

    return panel
end

--- Opens the ImmersionFX settings page in the game menu.
function UI:OpenSettings()
    if self.category and Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(self.category:GetID())
    elseif SettingsPanel and SettingsPanel.Open then
        SettingsPanel:Open()
        if self.category then
            SettingsPanel:SelectCategory(self.category)
        end
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(self.panel)
    end
end
