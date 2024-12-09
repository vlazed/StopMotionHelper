local PANEL = {}

function PANEL:Init()

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
        return slider
    end

    self:SetTitle("SMH Motion Paths")
    self:SetDeleteOnClose(false)

    self.BoneName = vgui.Create("DTextEntry", self)
    self.BoneName:SetConVar("smh_motionpathbone")
    self.BoneName.Label = vgui.Create("DLabel", self)
    self.BoneName.Label:SetText("Bone Name")

    local convarValue = GetConVar("smh_motionpathrange")
    self.PathRange = CreateSlider("Path Range", 0, 10, convarValue and convarValue:GetInt() or 0)
    self.PathRange:SetConVar("smh_motionpathrange")

    self.Width = 250
    self.Height = 75

    self:SetSize(self.Width, self.Height)

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

    local setPos = setPosition(25, 20)

    self.BaseClass.PerformLayout(self, width, height)

    setPos(self.PathRange)
    self.PathRange:SetSize(width, 20)

    setPos(self.BoneName)
    self.BoneName:SetX(120)
    self.BoneName:SetSize(width - 20 - self.BoneName:GetX(), 20)
    self.BoneName.Label:SetPos(5, self.BoneName:GetY())
    self.BoneName.Label:SetSize(self.BoneName:GetX(), 20)
end

vgui.Register("SMHMotionPaths", PANEL, "DFrame")
