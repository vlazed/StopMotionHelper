---@class SMHSettings: DFrame
---@field BaseClass DFrame
local PANEL = {}

---@param tree DTree
---@param setting DPanel
---@param label string
---@param icon string?
---@return DTree_Node, DScrollPanel
local function createSettingsPanel(tree, setting, label, icon)
    local node = tree:AddNode(label, icon)
    ---@cast node DTree_Node
    local scroller = setting:Add("DScrollPanel")
    scroller:DockPadding(0, 20, 0, 20)
    scroller:Dock(FILL)

    function node:DoClick()
        for _, s in ipairs(setting:GetChildren()) do
            s:SetVisible(false)
        end
        scroller:SetVisible(true)
    end

    return node, scroller
end

---@generic T
---@param parent Panel
---@param panel Panel|T
---@return Panel|T
local function addSetting(parent, panel)
    parent:Add(panel)
    panel:Dock(TOP)
    panel:DockMargin(5, 10, 5, 0)

    return panel
end

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

    ---@param name string
    ---@param label string
    ---@return DCheckBoxLabel
    local function CreateCheckBox(name, label)
        local cb = vgui.Create("DCheckBoxLabel", self)
        cb:SetText(label)
        cb:SizeToContents()
        cb.OnChange = CreateSettingChanger(name)
        return cb
    end

    ---@param name string
    ---@param label string
    ---@param min number
    ---@param max number
    ---@param decimals integer
    ---@return DNumSlider
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

    self.MenuPanel = vgui.Create("DPanel", self)
    self.SettingPanel = vgui.Create("DPanel", self)
    self.SettingPanel:SetPaintBackground(false)

    self.MenuTree = vgui.Create("DTree", self.MenuPanel)
    self.Divider = vgui.Create("DHorizontalDivider", self)
    
    self.Divider:Dock(FILL)
    self.Divider:SetLeft(self.MenuPanel)
    self.Divider:SetRight(self.SettingPanel)
    self.MenuTree:Dock(FILL)
    
    self.GeneralSettingsNode, self.GeneralSettings = createSettingsPanel(self.MenuTree, self.SettingPanel, "General")
    self.GhostSettingsNode, self.GhostSettings = createSettingsPanel(self.MenuTree, self.SettingPanel, "Ghost")
    self.PlaybackSettingsNode, self.PlaybackSettings = createSettingsPanel(self.MenuTree, self.SettingPanel, "Playback")

    self.FreezeAll = addSetting(self.GeneralSettings, CreateCheckBox("FreezeAll", "Freeze all"))
    self.LocalizePhysBones = addSetting(self.GeneralSettings, CreateCheckBox("LocalizePhysBones", "Localize phys bones"))
    self.IgnorePhysBones = addSetting(self.GeneralSettings, CreateCheckBox("IgnorePhysBones", "Don't animate phys bones"))
    self.GhostPrevFrame = addSetting(self.GhostSettings, CreateCheckBox("GhostPrevFrame", "Ghost previous frame"))
    self.GhostNextFrame = addSetting(self.GhostSettings, CreateCheckBox("GhostNextFrame", "Ghost next frame"))
    self.GhostAllEntities = addSetting(self.GhostSettings, CreateCheckBox("GhostAllEntities", "Ghost all entities"))
    self.GhostXRay = addSetting(self.GhostSettings, CreateCheckBox("GhostXRay", "Enable X-Ray ghosts"))
    self.GhostTransparency = addSetting(self.GhostSettings, CreateSlider("GhostTransparency", "Ghost transparency", 0, 1, 2))
    self.TweenDisable = addSetting(self.PlaybackSettings, CreateCheckBox("TweenDisable", "Disable tweening"))
    self.SmoothPlayback = addSetting(self.PlaybackSettings, CreateCheckBox("SmoothPlayback", "Smooth playback"))
    self.EnableWorld = addSetting(self.PlaybackSettings, CreateCheckBox("EnableWorld", "Enable World keyframes"))
    
    self.MajorTickInterval = vgui.Create("DNumSlider", self)
    self.MajorTickInterval:SetMinMax(3, 16)
    self.MajorTickInterval:SetDecimals(0)
    self.MajorTickInterval:SetText("Major Tick Interval")
    self.MajorTickInterval:SetConVar("smh_majortickinterval")
    self.MajorTickInterval.OnValueChanged = function(_, newVal)
        if newVal < 4 then
            self.MajorTickInterval.TextArea:SetValue("Disabled") ---@diagnostic disable-line
        end
    end

    addSetting(self.GeneralSettings, self.MajorTickInterval)

    ---@diagnostic disable-next-line
    self.GeneralSettingsNode:DoClick()
    
    self.Width = 500
    self.Height = 360

    self:SetSize(self.Width, self.Height)

    self._changingSettings = false

end

function PANEL:PerformLayout(width, height)
    ---@diagnostic disable-next-line
    self.BaseClass.PerformLayout(self, width, height)
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
        "GhostXRay",
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

vgui.Register("SMHSettings", PANEL, "DFrame")
