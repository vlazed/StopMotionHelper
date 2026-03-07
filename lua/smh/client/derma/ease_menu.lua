---@class SMHEaseMenu: DFrame
---@field BaseClass DFrame
local PANEL = {}

local function createLayoutPanel(parent)
    local dPanel = vgui.Create("DPanel", parent)
    dPanel:DockPadding(20, 0, 20, 0)
    dPanel:SetPaintBackground(false)

    return dPanel
end

function PANEL:Init()

    self.Title = "Ease Menu"
    self:SetTitle(self.Title)
    self:SetSize(250, 60)
    self:SetPos(ScrW() * 0.125 - self:GetWide() * 0.5, ScrH() * 0.8 - self:GetTall() * 0.5)
    self:SetDraggable(true)
    self:SetDeleteOnClose(false)
    self:ShowCloseButton(false)

    self._sendKeyframeChanges = true

    self.Easing = createLayoutPanel(self)
    self.Easing:DockPadding(60, 0, 20, 0)
    self.Buttons = createLayoutPanel(self)

    self.EaseInControl = vgui.Create("DNumberWang", self.Easing)
    self.EaseInControl:Dock(LEFT)
    self.EaseInControl:SetNumberStep(0.1)
    self.EaseInControl:SetMinMax(0, 1)
    self.EaseInControl:SetDecimals(1)
    self.EaseInControl.OnValueChanged = function(_, value)
        if self._sendKeyframeChanges then
            self:OnRequestKeyframeUpdate({ EaseIn = tonumber(value) })
        end
    end
    self.EaseInControl.Label = vgui.Create("DLabel", self.Easing)
    self.EaseInControl.Label:SetText("Ease in")
    self.EaseInControl.Label:SizeToContents()

    self.EaseOutControl = vgui.Create("DNumberWang", self.Easing)
    self.EaseOutControl:Dock(RIGHT)
    self.EaseOutControl:SetNumberStep(0.1)
    self.EaseOutControl:SetMinMax(0, 1)
    self.EaseOutControl:SetDecimals(1)
    self.EaseOutControl.OnValueChanged = function(_, value)
        if self._sendKeyframeChanges then
            self:OnRequestKeyframeUpdate({ EaseOut = tonumber(value) })
        end
    end
    self.EaseOutControl.Label = vgui.Create("DLabel", self.Easing)
    self.EaseOutControl.Label:SetText("Ease out")
    self.EaseOutControl.Label:SizeToContents()

    -- self.CancelButton = vgui.Create("DButton", self.Buttons)
    -- self.CancelButton:SetText("Close")
    -- self.CancelButton.DoClick = function()
    --     self:SetVisible(false)
    -- end

end

---@param easeIn number
---@param easeOut number
function PANEL:ShowEasingControls(easeIn, easeOut)
    self:SetVisible(true)

    self._sendKeyframeChanges = false
    self.EaseInControl:SetValue(easeIn)
    self.EaseOutControl:SetValue(easeOut)
    self._sendKeyframeChanges = true
end

function PANEL:HideEasingControls()
    self:SetVisible(false)
end

function PANEL:PerformLayout(width, height)

    ---@diagnostic disable-next-line
    self.BaseClass.PerformLayout(self, width, height)

    self:SetTitle(self.Title)

    self.EaseInControl:SetSize(50, 20)
    local sizeX, sizeY = self.EaseInControl.Label:GetSize()
    self.EaseInControl.Label:SetRelativePos(self.EaseInControl, -(sizeX) - 5, 3)

    self.EaseOutControl:SetSize(50, 20)
    local sizeX, sizeY = self.EaseOutControl.Label:GetSize()
    self.EaseOutControl.Label:SetRelativePos(self.EaseOutControl, -(sizeX) - 5, 3)

    self.Easing:SetPos(0, height * 0.5)
    self.Easing:SetSize(width, 20)

    self.Buttons:SetPos(0, height * 0.75)
    self.Buttons:SetSize(width, 20)

    -- self.CancelButton:Dock(FILL)

end

---@param newKeyframeData any
function PANEL:OnRequestKeyframeUpdate(newKeyframeData) end

vgui.Register("SMHEaseMenu", PANEL, "DFrame")
