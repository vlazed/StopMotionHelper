---@class SMHSmoothMenu: DFrame
---@field BaseClass DFrame
local PANEL = {}

local function createLayoutPanel(parent)
    local dPanel = vgui.Create("DPanel", parent)
    dPanel:DockPadding(20, 0, 20, 0)
    dPanel:SetPaintBackground(false)

    return dPanel
end

function PANEL:Init()

    self.Title = "Stretch Menu"
    self:SetTitle(self.Title)
    self:SetSize(ScrW() * 0.125, ScrH() * 0.1)
    self:SetPos(ScrW() * 0.5 - self:GetWide() * 0.5, ScrH() * 0.5 - self:GetTall() * 0.5)
    self:SetDraggable(true)
    self:ShowCloseButton(false)
    self:SetDeleteOnClose(false)
    self:ShowCloseButton(false)

    local function CreateSlider(parent, label, min, max, default, func)
        local slider = vgui.Create("DNumSlider", parent)
        ---@diagnostic disable: undefined-field
        -- overriding default functions as it used to clamp result between mix and max, and we kinda want to go over the max if need be
        slider.SetValue = function(self, val)

            if ( self:GetValue() == val ) then return end

            self.Scratch:SetValue( val )

            self:ValueChanged( self:GetValue() )

        end

        slider.ValueChanged = function(self, val)

            if ( self.TextArea != vgui.GetKeyboardFocus() ) then
                self.TextArea:SetValue( self.Scratch:GetTextValue() )
            end

            self.Slider:SetSlideX( self.Scratch:GetFraction( val ) )

            self:OnValueChanged( val )

        end

        slider:SetMinMax(min, max)
        slider:SetDecimals(0)
        slider:SetDefaultValue(default)
        slider:SetValue(default)
        slider:SetText(label)
        slider.OnValueChanged = func
        slider:GetTextArea().OnValueChange = func

        ---@diagnostic enable

        return slider
    end

    self.Smoothing = 1

    self.Sliders = createLayoutPanel(self)
    self.Sliders:DockPadding(10, 0, 0, 2)
    self.Buttons = createLayoutPanel(self)

    self.SmoothSlider = CreateSlider(self.Sliders, "Smoothness", 1, 10, self.Smoothing, function(_, value)
        value = tonumber(value)
        if not value then return end

        if value < 1 then
            value = 1
        end
        self.Smoothing = value
    end)

    self.SmoothButton = vgui.Create("DButton", self.Buttons)
    self.SmoothButton:SetText("Smooth")
    self.SmoothButton.DoClick = function()
        self:OnRequestSmooth()
        self:SetSmoothEnabled(false)
    end

    self.CancelButton = vgui.Create("DButton", self.Buttons)
    self.CancelButton:SetText("Close")
    self.CancelButton.DoClick = function()
        self:SetVisible(false)
    end

end

function PANEL:SetSmoothEnabled(bool)
    self.SmoothButton:SetEnabled(bool)
end

function PANEL:PerformLayout(width, height)

    ---@diagnostic disable-next-line
    self.BaseClass.PerformLayout(self, width, height)

    self:SetTitle(self.Title)

    self.Sliders:SetPos(0, height * 0.375)
    self.Sliders:SetSize(width, 20)
    self.SmoothSlider:Dock(FILL)

    self.Buttons:SetPos(0, height * 0.75)
    self.Buttons:SetSize(width, 20)

    self.CancelButton:Dock(RIGHT)
    self.SmoothButton:Dock(LEFT)

end

function PANEL:OnRequestSmooth() end

vgui.Register("SMHSmoothMenu", PANEL, "DFrame")
