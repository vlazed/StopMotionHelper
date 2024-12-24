---@class SMHKeyframeSettings: DFrame
---@field BaseClass DFrame
local PANEL = {}

function PANEL:Init()

    self:SetDraggable(false)
    self:ShowCloseButton(false)
    self:SetDeleteOnClose(false)
    self:ShowCloseButton(false)

    self:SetTitle("Keyframe Settings")
    self:SetDeleteOnClose(false)

    local function CreateSlider(label, min, max, default, func)
        local slider = vgui.Create("DNumSlider", self)

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
        return slider
    end

    self.Smoothing = 1
    self.SmoothSlider = CreateSlider("Smoothness", 1, 10, self.Smoothing, function(_, value)
        value = tonumber(value)
        if not value then return end

        if value < 1 then
            value = 1
        end
        self.Smoothing = value
    end)

    self.SmoothButton = vgui.Create("DButton", self)
    self.SmoothButton:SetText("Smooth")
    self.SmoothButton.DoClick = function()
        self:OnRequestSmooth()
    end

    self.SelectAllButton = vgui.Create("DButton", self)
    self.SelectAllButton:SetText("Select All")
    self.SelectAllButton.DoClick = function()
        self:OnRequestSelectAllFrames()
    end

    self.Width = 240
    self.Height = 80

    self:SetSize(self.Width, self.Height)

    self._changingSettings = false

end

---Initialize a starting position. Every call to this function will add to the pos variable 
---@param pos number Initial position
---@param offset number
---@return fun(panel: Panel)
local function setPosition(pos, height, offset)
    return function(panel)
        panel:SetPos(pos, height)
        pos = pos + offset
    end
end

function PANEL:PerformLayout(width, height)

    local buttonWidth = 60
    local setButtonPos = setPosition(width * 0.48 - buttonWidth, height * 0.45, 70)

    ---@diagnostic disable-next-line
    self.BaseClass.PerformLayout(self, width, height)

    setButtonPos(self.SelectAllButton)
    self.SelectAllButton:SetSize(buttonWidth, 20)
    setButtonPos(self.SmoothButton)
    self.SmoothButton:SetSize(buttonWidth, 20)

    self.SmoothSlider:SetPos(width * 0.08, height * 0.65)
    self.SmoothSlider:SetSize(self:GetWide() - 5, 25)
end

function PANEL:OnRequestSelectAllFrames() end
function PANEL:OnRequestSmooth() end

vgui.Register("SMHKeyframeSettings", PANEL, "DFrame")
