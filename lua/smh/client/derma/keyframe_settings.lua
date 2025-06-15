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

    self.StretchButton = vgui.Create("DButton", self)
    self.StretchButton:SetText("Stretch")
    self.StretchButton.DoClick = function()
        self:OnRequestStretch()
    end

    self.Stretching = 1
    self.StretchSlider = CreateSlider("Stretch Amount", 0, 10, self.Smoothing, function(_, value)
        value = tonumber(value)
        if not value then return end
        if value < 1 then
            self.StretchButton:SetText("Compress")
        else
            self.StretchButton:SetText("Stretch")
        end

        self.Stretching = value
    end)
    self.StretchSlider:SetDecimals(3)

    self.SelectAllButton = vgui.Create("DButton", self)
    self.SelectAllButton:SetText("Select All")
    self.SelectAllButton.DoClick = function()
        self:OnRequestSelectFrames(0)
    end

    self.SelectLeftButton = vgui.Create("DButton", self)
    self.SelectLeftButton:SetText("Select Left")
    self.SelectLeftButton.DoClick = function()
        self:OnRequestSelectFrames(-1)
    end

    self.SelectRightButton = vgui.Create("DButton", self)
    self.SelectRightButton:SetText("Select Right")
    self.SelectRightButton.DoClick = function()
        self:OnRequestSelectFrames(1)
    end

    self.Width = 360
    self.Height = 120

    self:SetSize(self.Width, self.Height)

    self._changingSettings = false

end

---Initialize a starting position. Every call to this function will add to the pos variable 
---@param pos number Initial position
---@param offset number
---@return fun(panel: Panel)
local function setPositionX(pos, height, offset)
    return function(panel)
        panel:SetPos(pos, height)
        pos = pos + offset
    end
end

local function setPositionY(pos, height, offset)
    return function(panel)
        panel:SetPos(height, pos)
        pos = pos + offset
    end
end

function PANEL:PerformLayout(width, height)

    local topMargin = 10
    local topButtonWidth = width / 3 - topMargin * 0.75
    local setButtonPos = setPositionX(topMargin, height * 0.275, topButtonWidth)

    ---@diagnostic disable-next-line
    self.BaseClass.PerformLayout(self, width, height)

    setButtonPos(self.SelectLeftButton)
    self.SelectLeftButton:SetSize(topButtonWidth, 20)
    setButtonPos(self.SelectAllButton)
    self.SelectAllButton:SetSize(topButtonWidth, 20)
    setButtonPos(self.SelectRightButton)
    self.SelectRightButton:SetSize(topButtonWidth, 20)

    local buttonWidth = 60
    local sliderMargin = 90
    local sliderOffset = 30
    self.SmoothSlider:SetPos(width * 0.08, height * 0.50)
    self.SmoothSlider:SetSize(self:GetWide() - sliderMargin, 25)
    self.SmoothButton:SetSize(buttonWidth, 20)
    self.SmoothButton:SetPos(width - buttonWidth - 10, self.SmoothSlider:GetY())

    local setHeightPos = setPositionY(self.SmoothSlider:GetY() + sliderOffset, self.SmoothSlider:GetX(), sliderOffset)
    setHeightPos(self.StretchSlider)
    self.StretchSlider:SetSize(self:GetWide() - sliderMargin, 25)
    self.StretchButton:SetSize(buttonWidth, 20)
    self.StretchButton:SetPos(width - buttonWidth - 10, self.StretchSlider:GetY())
end

function PANEL:OnRequestSelectFrames(increment) end
function PANEL:OnRequestSmooth() end
function PANEL:OnRequestStretch() end

vgui.Register("SMHKeyframeSettings", PANEL, "DFrame")
