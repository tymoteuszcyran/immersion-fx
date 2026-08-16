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

-- Helper to create styled slider
local function CreateSlider(parent, name, labelText, minVal, maxVal, step, initialValue, onValueChanged)
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:SetValue(initialValue)
    
    local textFS = _G[name .. "Text"] or slider.Text
    local lowFS = _G[name .. "Low"] or slider.Low
    local highFS = _G[name .. "High"] or slider.High
    
    local function updateText(val)
        if textFS then
            local isDefault = math.abs(val - 1.0) < 0.001
            textFS:SetText(string.format("%s: |cffffd100%.1fx|r%s", labelText, val, (isDefault and " |cff888888(Default)|r" or "")))
        end
    end

    if lowFS then
        lowFS:SetText(string.format("%.1fx", minVal))
    end
    if highFS then
        highFS:SetText(string.format("%.1fx", maxVal))
    end
    updateText(initialValue)

    slider:SetScript("OnValueChanged", function(self, value)
        local rounded = math.floor((value / step) + 0.5) * step
        updateText(rounded)
        onValueChanged(rounded)
    end)

    slider.UpdateValue = function(self, val)
        self:SetValue(val)
        updateText(val)
    end

    return slider
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

    -- Divider 2
    local divider2 = panel:CreateTexture(nil, "ARTWORK")
    divider2:SetColorTexture(0.3, 0.3, 0.3, 0.6)
    divider2:SetHeight(1)
    divider2:SetPoint("TOPLEFT", lastAnchor, "BOTTOMLEFT", -10, -16)
    divider2:SetPoint("RIGHT", panel, "RIGHT", -16, 0)

    -- ==========================================
    -- UI Section
    -- ==========================================
    local uiHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    uiHeader:SetPoint("TOPLEFT", lastAnchor, "BOTTOMLEFT", -10, -28)
    uiHeader:SetText("UI")

    local uiSubtext = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    uiSubtext:SetPoint("TOPLEFT", uiHeader, "BOTTOMLEFT", 0, -4)
    uiSubtext:SetText("Adjust in-world combat text scaling for enhanced visibility.")

    -- World Text Scale Slider
    local currentScale = IFX.Config:GetFloatingTextScale()
    local textScaleSlider = CreateSlider(panel, "ImmersionFX_WorldTextScaleSlider", "Floating Combat Text Scale", 0.5, 2.5, 0.1, currentScale, function(val)
        IFX.Config:SetFloatingTextScale(val)
    end)
    textScaleSlider:SetPoint("TOPLEFT", uiSubtext, "BOTTOMLEFT", 0, -22)
    textScaleSlider:SetWidth(220)
    self.textScaleSlider = textScaleSlider

    -- Reset Button
    local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetBtn:SetSize(70, 22)
    resetBtn:SetPoint("LEFT", textScaleSlider, "RIGHT", 24, 0)
    resetBtn:SetText("Reset")
    resetBtn:SetScript("OnClick", function()
        textScaleSlider:UpdateValue(1.0)
        IFX.Config:SetFloatingTextScale(1.0)
    end)

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
        if self.textScaleSlider then
            self.textScaleSlider:UpdateValue(IFX.Config:GetFloatingTextScale())
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
