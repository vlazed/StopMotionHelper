---@class SMHMotionPaths: DFrame
---@field BaseClass DFrame
local PANEL = {}

local PRECISION = 10000
Derma_Install_Convar_Functions(PANEL)

function PANEL:Init()

    local function CreateSlider(label, min, max, default, decimals, component)
        local slider = vgui.Create("DNumSlider", self)

        -- overriding default functions as it used to clamp result between mix and max, and we kinda want to go over the max if need be
        ---@param panel DNumSlider
        ---@param val number
        slider.SetValue = function(panel, val)

            if ( panel:GetValue() == val ) then return end

            ---@diagnostic disable-next-line
            panel.Scratch:SetValue( val )

            panel:ValueChanged( panel:GetValue() )

        end

        ---@param panel DNumSlider
        ---@param val number
        slider.ValueChanged = function(panel, val)

            ---@diagnostic disable-next-line
            if ( panel.TextArea != vgui.GetKeyboardFocus() ) then
                ---@diagnostic disable-next-line
                panel.TextArea:SetValue( panel.Scratch:GetTextValue() )
            end

            ---@diagnostic disable-next-line
            panel.Slider:SetSlideX( panel.Scratch:GetFraction( val ) )

            if component then
                ---@diagnostic disable-next-line
                local currentOffset = GetConVar(self.m_strConVar)
                local offsets = currentOffset:GetString():Split(" ")
                offsets[component] = math.floor(val * PRECISION) / PRECISION
                self:ConVarChanged(table.concat(offsets, " "))
            end

            ---@diagnostic disable-next-line
            panel:OnValueChanged( val )

        end

        slider:SetMinMax(min, max)
        slider:SetDecimals(decimals)
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

    local motionPathValue = GetConVar("smh_motionpathrange")
    self.PathRange = CreateSlider("Path Range", 0, 10, motionPathValue and motionPathValue:GetInt() or 0, 0)
    self.PathRange:SetConVar("smh_motionpathrange")

    local sizeValue = GetConVar("smh_motionpathsize")
    self.NodeSize = CreateSlider("Node Size", 0, 10, sizeValue and sizeValue:GetInt() or 0, 2)
    self.NodeSize:SetConVar("smh_motionpathsize")

    local offsetValue = GetConVar("smh_motionpathoffset")
    local offsets = offsetValue:GetString():Split(" ")

    self:SetConVar("smh_motionpathoffset")
    self.OffsetXSlider = CreateSlider("X Offset", -100, 100, tonumber(offsets[1]) or 0, 2, 1)
    self.OffsetYSlider = CreateSlider("Y Offset", -100, 100, tonumber(offsets[2]) or 0, 2, 2)
    self.OffsetZSlider = CreateSlider("Z Offset", -100, 100, tonumber(offsets[3]) or 0, 2, 3)

    self.ResetOffset = vgui.Create("DButton", self)
    self.ResetOffset:SetText("Reset Offset")
    self.ResetOffset.DoClick = function()
        self.OffsetXSlider:SetValue(0)
        self.OffsetYSlider:SetValue(0)
        self.OffsetZSlider:SetValue(0)
    end

    self.Width = 250
    self.Height = 175

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

function PANEL:SetValue(newValue)
    local offsets = newValue:Split(" ")
    self.OffsetXSlider:SetValue(tonumber(offsets[1]) or 0)
    self.OffsetYSlider:SetValue(tonumber(offsets[2]) or 0)
    self.OffsetZSlider:SetValue(tonumber(offsets[3]) or 0)
end

function PANEL:Think()
    self:ConVarStringThink()
end

function PANEL:PerformLayout(width, height)

    local setPos = setPosition(25, 20)

    ---@diagnostic disable-next-line
    self.BaseClass.PerformLayout(self, width, height)

    setPos(self.PathRange)
    self.PathRange:SetSize(width, 20)

    setPos(self.NodeSize)
    self.NodeSize:SetSize(width, 20)

    setPos(self.BoneName)
    self.BoneName:SetX(120)
    self.BoneName:SetSize(width - 20 - self.BoneName:GetX(), 20)
    self.BoneName.Label:SetPos(5, self.BoneName:GetY())
    self.BoneName.Label:SetSize(self.BoneName:GetX(), 20)

    local _, y = self.BoneName:GetPos()
    local _, offset = self.BoneName:GetSize()
    local setPos = setPosition(y + offset, 20)
    setPos(self.OffsetXSlider)
    self.OffsetXSlider:SetSize(width - 10, 20)
    setPos(self.OffsetYSlider)
    self.OffsetYSlider:SetSize(width - 10, 20)
    setPos(self.OffsetZSlider)
    self.OffsetZSlider:SetSize(width - 10, 20)
    setPos(self.ResetOffset)
    self.ResetOffset:SetSize(width - 10, 20)
end

vgui.Register("SMHMotionPaths", PANEL, "DFrame")
