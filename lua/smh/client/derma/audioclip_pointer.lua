local PANEL = {}

local lockedHeight = 5
local editHeight = 15

function PANEL:Init()

    self:SetSize(8, 15)
    self.Color = Color(math.Rand(50,255), math.Rand(50,100), math.Rand(50,255), 200)
	self:SetBackgroundColor(self.Color)
	self:SetPaintBackground(true)
    self.OutlineColor = Color(0, 0, 0)
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

end

function PANEL:Setup(audioClip)
	self._audioClip = audioClip
	self._id = audioClip.ID
	local splitName = string.Split(audioClip.AudioChannel:GetFileName(),"/")
	self._fileName = splitName[#splitName]
	self._startFrame = audioClip.Frame
	self:SetFrame(self._startFrame)
end

function PANEL:Paint(width, height) end

function PANEL:PaintOverride()
	if SMH.State.EditAudioTrack then
		self:SetHeight(editHeight)
	else
		self:SetHeight(lockedHeight)
	end
	
	local width = self:GetWide()
	local height = self:GetTall()
	
	local outlineColor = ((self._selected or self._dragging) and self.OutlineColorDragged) or self.OutlineColor

	surface.SetDrawColor(self.Color:Unpack())
	surface.DrawRect(self.PosX+1, self.PosY+1, width - 1, height - 1)

	surface.SetDrawColor(outlineColor:Unpack())
	surface.DrawLine(self.PosX, self.PosY, self.PosX+width, self.PosY)
	surface.DrawLine(self.PosX+width, self.PosY, self.PosX+width, self.PosY+height)
	surface.DrawLine(self.PosX+width, self.PosY+height, self.PosX, self.PosY+height)
	surface.DrawLine(self.PosX, self.PosY+height, self.PosX, self.PosY)
	
	if SMH.State.EditAudioTrack then
		surface.SetTextPos(self.PosX+2, self.PosY+2)
		surface.SetTextColor(Color(255,255,255))
		surface.SetFont("DefaultSmall")
		surface.DrawText(self._fileName)
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
		return
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
