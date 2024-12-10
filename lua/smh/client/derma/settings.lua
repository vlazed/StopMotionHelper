---@class SMHSettings: DFrame
---@field BaseClass DFrame
local PANEL = {}

function PANEL:Init()

    local function CreateSettingChanger(name)
        return function(_self, value)
            if self._changingSettings then
                return
            end

            local updatedSettings = {
                [name] = value
            }
            self:OnSettingsUpdated(updatedSettings)
        end
    end

    local function CreateCheckBox(name, label)
        local cb = vgui.Create("DCheckBoxLabel", self)
        cb:SetText(label)
        cb:SizeToContents()
        cb.OnChange = CreateSettingChanger(name)
        return cb
    end

    local function CreateSlider(name, label, min, max, decimals)
        local slider = vgui.Create("DNumSlider", self)
        slider:SetMinMax(min, max)
        slider:SetDecimals(decimals)
        slider:SetText(label)
        slider.OnValueChanged = CreateSettingChanger(name)
        return slider
    end

    self:SetTitle("SMH Settings")
    self:SetDeleteOnClose(false)

    self.FreezeAll = CreateCheckBox("FreezeAll", "Freeze all")
    self.LocalizePhysBones = CreateCheckBox("LocalizePhysBones", "Localize phys bones")
    self.IgnorePhysBones = CreateCheckBox("IgnorePhysBones", "Don't animate phys bones")
    self.GhostPrevFrame = CreateCheckBox("GhostPrevFrame", "Ghost previous frame")
    self.GhostNextFrame = CreateCheckBox("GhostNextFrame", "Ghost next frame")
    self.GhostAllEntities = CreateCheckBox("GhostAllEntities", "Ghost all entities")
    self.TweenDisable = CreateCheckBox("TweenDisable", "Disable tweening")
    self.SmoothPlayback = CreateCheckBox("SmoothPlayback", "Smooth playback")
    self.EnableWorld = CreateCheckBox("EnableWorld", "Enable World keyframes")
    self.GhostTransparency = CreateSlider("GhostTransparency", "Ghost transparency", 0, 1, 2)

    self.PathButton = vgui.Create("DButton", self)
    self.PathButton:SetText("Motion Paths")
    self.PathButton.DoClick = function()
        self:OnRequestOpenMotionPaths()
    end

    self.PhysButton = vgui.Create("DButton", self)
    self.PhysButton:SetText("Physics Recorder")
    self.PhysButton.DoClick = function()
        self:OnRequestOpenPhysRecorder()
    end

    self.HelpButton = vgui.Create("DButton", self)
    self.HelpButton:SetText("Help")
    self.HelpButton.DoClick = function()
        self:OnRequestOpenHelp()
    end

    self.Width = 250
    self.Height = 315

    self:SetSize(self.Width, self.Height)

    self._changingSettings = false

end

---Initialize a starting position. Every call to this function will add to the pos variable 
---@param pos number Initial position
---@param offset number
---@return fun(panel: Panel)
local function setPosition(pos, offset)
    return function(panel)
        panel:SetPos(5, pos)
        pos = pos + offset
    end
end

function PANEL:PerformLayout(width, height)

    local setCheckboxPos = setPosition(25, 20)

    self.BaseClass.PerformLayout(self, width, height)

    setCheckboxPos(self.FreezeAll)
    setCheckboxPos(self.LocalizePhysBones)
    setCheckboxPos(self.IgnorePhysBones)
    setCheckboxPos(self.GhostPrevFrame)
    setCheckboxPos(self.GhostNextFrame)
    setCheckboxPos(self.GhostAllEntities)
    setCheckboxPos(self.TweenDisable)
    setCheckboxPos(self.SmoothPlayback)
    setCheckboxPos(self.EnableWorld)

    setCheckboxPos(self.GhostTransparency)
    self.GhostTransparency:SetSize(self:GetWide() - 5 - 5, 25)

    local setButtonPos = setPosition(self.GhostTransparency:GetY() + 25, 25)

    setButtonPos(self.PathButton)
    self.PathButton:SetSize(self:GetWide() - 10, 20)

    setButtonPos(self.PhysButton)
    self.PhysButton:SetSize(self:GetWide() - 10, 20)

    setButtonPos(self.HelpButton)
    self.HelpButton:SetSize(self:GetWide() - 5 - 5, 20)

end

---@param settings Settings
function PANEL:ApplySettings(settings)
    self._changingSettings = true

    local checkBoxes = {
        "FreezeAll",
        "LocalizePhysBones",
        "IgnorePhysBones",
        "GhostPrevFrame",
        "GhostNextFrame",
        "GhostAllEntities",
        "TweenDisable",
        "SmoothPlayback",
        "EnableWorld",
    }

    for _, key in pairs(checkBoxes) do
        if settings[key] ~= nil then
            self[key]:SetChecked(settings[key])
        end
    end

    if settings.GhostTransparency ~= nil then
        self.GhostTransparency:SetValue(settings.GhostTransparency)
    end

    self._changingSettings = false
end

---@param settings Settings
function PANEL:OnSettingsUpdated(settings) end
function PANEL:OnRequestOpenHelp() end
function PANEL:OnRequestOpenPhysRecorder() end
function PANEL:OnRequestOpenMotionPaths() end

vgui.Register("SMHSettings", PANEL, "DFrame")
