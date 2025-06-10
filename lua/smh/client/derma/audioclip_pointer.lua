---@class SMHAudioClipPointer: SMHFramePointer
---@field GetParent fun(self: SMHAudioClipPointer): SMHFramePanel
local PANEL = {}

local lockedHeightConVar = CreateClientConVar("smh_audioclip_scale", "50", true, false, "Set the relative height of the audio clip in the timeline. 100 means the clip takes up the full height of the timeline, and 0 disables its rendering completely.", 0, 100)
local lockedHeight = lockedHeightConVar:GetFloat() / 100
cvars.AddChangeCallback("smh_audioclip_scale", function (convar, oldValue, newValue)
    lockedHeight = Either(tonumber(newValue) ~= nil, tonumber(newValue), oldValue)  / 100
end)
local framePanelHeight = 30
local editHeight = 15
-- local barWidth = 5 / 1000

local ENABLED_ALPHA, DISABLED_ALPHA = 200, 50
local COLOR_TRANSPARENT = Color(255, 255, 255, ENABLED_ALPHA)
local COLOR_TRANSPARENT_DISABLED = Color(255, 255, 255, DISABLED_ALPHA * 2)

---@param color Color
---@returns Color darkerColor
local function Darken(color, offset)
    if offset > 1 then
        offset = offset / 100
    end

    local h,s,v = color:ToHSV()
    v = math.max(0, v - offset)
    return HSVToColor(h,s,v)
end

function PANEL:Init()

    self:SetSize(8, 15)
    self.Color = Color(math.Rand(50,255), math.Rand(50,100), math.Rand(50,255), ENABLED_ALPHA)
	self:SetBackgroundColor(self.Color)
	self:SetPaintBackground(true)
    self.OutlineColor = Color(0, 0, 0)
    self.DarkColor = Darken(self.Color, 40)
    self.DisabledColor = ColorAlpha(self.Color, DISABLED_ALPHA)
    self.OutlineColorDragged = Color(255, 255, 255)
    self.VerticalPosition = 32
	self.CursorOffsetX = 0
	
	self._audioClip = nil
    self._startFrame = 0
	self._duration = 0
    self._dragging = false
	self._draggingEnd = false
    self._id = 0
	self._fileName = ""
    self._selected = false
    self._maxoffset = 0
    self._minoffset = 0
    self._waveform = {}
end

function PANEL:Setup(audioClip)
	self._audioClip = audioClip
	self._id = audioClip.ID
	local splitName = string.Split(audioClip.AudioChannel:GetFileName(),"/")
	self._fileName = splitName[#splitName]
	self._startFrame = audioClip.Frame
    self._waveform = audioClip.Waveform
	self:SetFrame(self._startFrame)
end

function PANEL:Think()
    self:SetMouseInputEnabled(SMH.State.EditAudioTrack)
end

function PANEL:Paint(width, height) end

function PANEL:PaintOverride()
    if lockedHeight == 0 then return end
    
    local canEditAudioTrack = SMH.State.EditAudioTrack

	if SMH.State.EditAudioTrack then
		self:SetHeight(editHeight)
	else
		self:SetHeight(lockedHeight * framePanelHeight)
	end
	
	local width = self:GetWide()
	local height = self:GetTall()

	local outlineColor = ((self._selected or self._dragging) and self.OutlineColorDragged) or self.OutlineColor

    local color = canEditAudioTrack and self.Color or self.DisabledColor
	surface.SetDrawColor(color:Unpack())
	surface.DrawRect(self.PosX+1, self.PosY+1, width - 1, height - 1)

	surface.SetDrawColor(outlineColor:Unpack())
	surface.DrawLine(self.PosX, self.PosY, self.PosX+width, self.PosY)
	surface.DrawLine(self.PosX+width, self.PosY, self.PosX+width, self.PosY+height)
	surface.DrawLine(self.PosX+width, self.PosY+height, self.PosX, self.PosY+height)
	surface.DrawLine(self.PosX, self.PosY+height, self.PosX, self.PosY)

    if self._waveform and #self._waveform > 0 then
        local waveColor = canEditAudioTrack and COLOR_TRANSPARENT or COLOR_TRANSPARENT_DISABLED
        for i = 1, #self._waveform-1 do
            local wave1 = self._waveform[i]
            local wave2 = self._waveform[i+1]
            local avg = math.max((wave1.Left + wave1.Right) * 0.5, 0.1)
            local barWidth = (wave2.Fraction - wave1.Fraction) * self:GetWide()
            surface.SetDrawColor(waveColor:Unpack())
            local y = (1 - avg) * height
            local x = self:GetWide() * wave1.Fraction
            surface.DrawRect(self.PosX + x, self.PosY + y / 2 + 1, barWidth, height - y)
        end
    end

	if SMH.State.EditAudioTrack then
        draw.SimpleTextOutlined(self._fileName, "DefaultSmall", self.PosX+2, self.PosY+2, color_white, nil, nil, 1, self.DarkColor)
	end
end

function PANEL:GetFrame()
    return self._startFrame
end

function PANEL:SetFrame(frame)
    local parent = self:GetParent()

    local startX, endX = unpack(parent.FrameArea)
    local height = self.VerticalPosition

    local frameAreaWidth = endX - startX
    local offsetFrame = frame - parent.ScrollOffset
    local x = startX + (offsetFrame / (parent.Zoom - 1)) * frameAreaWidth

    
	self.PosX = x
	self.PosY = height - self:GetTall()
	
	self:SetPos(self.PosX, self.PosY)
	
	local startX, endX = unpack(parent.FrameArea)
    local frameGap = (endX - startX) / (parent.Zoom - 1)
	
	self._duration = self._audioClip.Duration
	
	self:SetWidth(frameGap*self._duration*SMH.State.PlaybackRate)
	
    self._startFrame = frame
end

function PANEL:RefreshFrame(z)
    self:SetFrame(self._startFrame)
	self:SetZPos(z)
end

function PANEL:IsDragging()
    return self._dragging
end

function PANEL:SetSelected(selected)
    self._selected = selected
end

function PANEL:GetSelected()
    return self._selected
end

function PANEL:GetID()
    return self._id
end

function PANEL:GetDuration()
	return self._duration
end

function PANEL:OnMousePressed(mousecode)
	if not SMH.State.EditAudioTrack then
		return false
	end
	
    if mousecode ~= MOUSE_LEFT then
        self:MouseCapture(false)
        self._dragging = false
        self:OnCustomMousePressed(mousecode)
        return
    end

    self:MouseCapture(true)
	local offsetX,offsetY = self:CursorPos()
	self.CursorOffsetX = offsetX --get offset
    self._dragging = true

    SMH.UI.SetOffsets(self)
end

function PANEL:SetParentPointer(ppointer)
    self._parent = ppointer
end

function PANEL:ClearParentPointer()
    self._parent = nil
end

function PANEL:GetParentKeyframe()
    return self._parent
end

function PANEL:SetOffsets(minimum, maximum)
    self._minoffset = minimum
    self._maxoffset = maximum
end

function PANEL:GetStartFrame()
	return self._startFrame
end

function PANEL:GetDuration()
	return self._duration
end

function PANEL:OnMouseReleased(mousecode)
    if not self._dragging then
        return
    end

    self:SetOffsets(0, 0)

    self:MouseCapture(false)
    self._dragging = false
    self:OnPointerReleased(self._startFrame)

    if mousecode == MOUSE_LEFT then
		self:GetParent():SortClipOrder()
		print(table.ToString(self:GetParent().AudioClipPointers, "AudioClipPointers", true))
        if input.IsKeyDown(KEY_LSHIFT) then
            SMH.UI.ShiftSelect(self)
        elseif input.IsKeyDown(KEY_LCONTROL) then
            SMH.UI.ToggleSelect(self)
        else
            SMH.UI.ClearAllSelected()
        end
    end
end

function PANEL:OnCursorMoved()
    if not self._dragging then
        return
    end

    local parent = self:GetParent()
    local cursorX, cursorY = parent:CursorPos()
    local startX, endX = unpack(parent.FrameArea)

    local targetX = cursorX - startX - self.CursorOffsetX
    local width = endX - startX

    local targetPos = math.Round(parent.ScrollOffset + (targetX / width) * (parent.Zoom - 1))
    targetPos = targetPos < 0 - self._minoffset and 0 - self._minoffset or (targetPos >= parent.TotalFrames - self._maxoffset and parent.TotalFrames - 1 - self._maxoffset or targetPos)

    if targetPos ~= self._startFrame then
        SMH.UI.MoveChildren(self, targetPos)
        self:SetFrame(targetPos)
        self:OnFrameChanged(targetPos)
        SMH.UI.MoveChildren(self, targetPos)
    end
end

function PANEL:OnFrameChanged(newFrame) end
function PANEL:OnPointerReleased(frame) end
function PANEL:OnCustomMousePressed(mousecode) end

vgui.Register("SMHAudioClipPointer", PANEL, "DPanel")
