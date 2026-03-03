---@class SMHFramePanel: DPanel
local PANEL = {}

Derma_Install_Convar_Functions(PANEL)

---@param scrollPanel DPanel
---@param pressed function
---@param released function
---@param cursorMoved function
---@return DPanel leftSizer
---@return DPanel rightSizer
local function scrollSizePair(scrollPanel, pressed, released, cursorMoved)
    local pair = {}
    for i = 1, 2 do
        local sizer = vgui.Create("DPanel", scrollPanel)
        sizer:SetCursor("sizewe")
        sizer:SetPaintBackground(false)
        sizer:Dock(i == 1 and LEFT or RIGHT)
        
        sizer.OnMousePressed = function(_, mousecode) pressed(mousecode, i == 1) end
        sizer.OnMouseReleased = function(_, mousecode) released(mousecode, i == 1) end
        sizer.OnCursorMoved = function(_, x, y) cursorMoved(x, y, i == 1) end

        table.insert(pair, sizer)
    end

    return unpack(pair)
end

function PANEL:Init()

    self:SetBackgroundColor(Color(64, 64, 64, 64))

    self.ScrollBar = vgui.Create("DPanel", self)
    self.ScrollBar.Paint = function(self, w, h) derma.SkinHook("Paint", "ScrollBarGrip", self, w, h) end
    self.ScrollBar.OnMousePressed = function(_, mousecode) self:OnScrollBarPressed(mousecode) end
    self.ScrollBar.OnMouseReleased = function(_, mousecode) self:OnScrollBarReleased(mousecode) end
    self.ScrollBar.OnCursorMoved = function(_, x, y) self:OnScrollBarCursorMoved(x, y) end

    self.ScrollBar.Left, self.ScrollBar.Right = scrollSizePair(
        self.ScrollBar, 
        function(mousecode, isLeft) self:OnScrollBarSizerPressed(mousecode, isLeft) end,
        function(mousecode, isLeft) self:OnScrollBarSizerReleased(mousecode, isLeft) end,
        function(x, y, isLeft) self:OnScrollBarSizerCursorMoved(x, y, isLeft) end
    )

    self.ScrollButtonLeft = vgui.Create("DButton", self)
    self.ScrollButtonLeft:SetText("")
    self.ScrollButtonLeft.Paint = function(self, w, h) derma.SkinHook("Paint", "ButtonLeft", self, w, h) end
    self.ScrollButtonLeft.DoClick = function() self:SetScrollOffset(self.ScrollOffset - 1) end

    self.ScrollButtonRight = vgui.Create("DButton", self)
    self.ScrollButtonRight:SetText("")
    self.ScrollButtonRight.Paint = function(self, w, h) derma.SkinHook("Paint", "ButtonRight", self, w, h) end
    self.ScrollButtonRight.DoClick = function() self:SetScrollOffset(self.ScrollOffset + 1) end

    self.Zoom = 100
    self:SetConVar("smh_zoom")
    self.TotalFrames = 100
    self.ScrollOffset = 0
    self.FrameArea = {0, 1}
    self._draggingScrollBar = false
    self._scrollCursorOffset = 0
    self._scrollCursorPos = 0
    self._resizingScrollBar = false
    self._oldWidth = 0

    self.FramePointers = {}
	self.AudioClipPointers = {}

    self:UpdateMajor(GetConVar("smh_majortickinterval"):GetInt())

end

function PANEL:PerformLayout(width, height)

    local frameAreaPadding = 10
    local scrollPadding = 18
    local scrollHeight = 12
    local scrollPosY = self:GetTall() - scrollHeight

    self.ScrollBarRect = {
        X = scrollPadding,
        Y = scrollPosY,
        Width = self:GetWide() - scrollPadding * 2,
        Height = scrollHeight,
    }

    self.ScrollButtonLeft:SetPos(scrollPadding - 12, scrollPosY)
    self.ScrollButtonLeft:SetSize(12, scrollHeight)

    self.ScrollButtonRight:SetPos(scrollPadding + self.ScrollBarRect.Width, scrollPosY)
    self.ScrollButtonRight:SetSize(12, scrollHeight)

    local startPoint = frameAreaPadding
    local endPoint = self:GetWide() - frameAreaPadding
    self.FrameArea = {startPoint, endPoint}

    self:RefreshScrollBar()
    self:RefreshFrames()
	
end

---@param newMajor integer
function PANEL:UpdateMajor(newMajor)
    self.major = newMajor
    self.majorFactorSet = {}
    local quarter, half = math.floor(self.major * 0.25), math.floor(self.major * 0.5)
    for i = 0, quarter do
        local _, frac = math.modf(self.major / i)
        local factor = 0.45
        local inv = 1 / (i+1)
        if frac == 0 and inv ~= 0.5 then 
            factor = inv * 0.85
        end
        self.majorFactorSet[i] = factor
    end
    for i = quarter, half do
        self.majorFactorSet[i] = self.majorFactorSet[half-i]
    end
end

---Triangle sine wave function with range [0, 4*a/p] 
---@param x number point
---@param a number amplitude
---@param p number period
---@return number
local function triangle(x, a, p)
    return 4 * a / p * math.abs(((x - p * 0.5) % p) - p * 0.5)
end

function PANEL:Paint(width, height)
    local startX, endX = unpack(self.FrameArea)
    local frameWidth = (endX - startX) / (self.Zoom - 1)
    local major = self.major
    local majorFactorSet = self.majorFactorSet

    surface.SetDrawColor(255, 255, 255, 255)
    for i = self.ScrollOffset, math.min(self.ScrollOffset + self.Zoom - 1, self.TotalFrames - 1) do
        local x = startX + frameWidth * i - self.ScrollOffset * frameWidth
        local index = major > 3 and triangle(i, major * 0.25, major) or -1
        local tickHeight = Either(major > 3, majorFactorSet[index] or 0.45, 0.85)
        surface.DrawLine(x, height * (1 - tickHeight), x, height * tickHeight)
    end
	
	for _, pointer in pairs(self.AudioClipPointers) do
        pointer:PaintOverride()
    end
    
    self.ScrollBar.Left:SetSize(5, self.ScrollBar:GetTall())
    self.ScrollBar.Right:SetSize(5, self.ScrollBar:GetTall())
end

function PANEL:UpdateFrameCount(totalframes)
    self.TotalFrames = totalframes

    if not self.ScrollBarRect then return end --check if we actually initialized the panel
    self:RefreshScrollBar()
end

function PANEL:RefreshScrollBar()
    if self.TotalFrames == self.Zoom then
        self.ScrollBar:SetPos(self.ScrollBarRect.X, self.ScrollBarRect.Y)
        self.ScrollBar:SetSize(self.ScrollBarRect.Width, self.ScrollBarRect.Height)
        return
    end

    local barWidthPerc = self.Zoom / self.TotalFrames
    barWidthPerc = barWidthPerc > 1 and 1 or barWidthPerc

    local barXPerc = self.ScrollOffset / (self.TotalFrames - self.Zoom)
    barXPerc = barXPerc < 0 and 0 or (barXPerc > 1 and 1 or barXPerc)

    local width = self.ScrollBarRect.Width * barWidthPerc
    local height = self.ScrollBarRect.Height
    local x = self.ScrollBarRect.X + (self.ScrollBarRect.Width - width) * barXPerc
    local y = self.ScrollBarRect.Y

    self.ScrollBar:SetPos(x, y)
    self.ScrollBar:SetSize(width, height)
end

function PANEL:RefreshFrames()
    for _, pointer in pairs(self.FramePointers) do
        pointer:RefreshFrame()
    end
	for i, pointer in pairs(self.AudioClipPointers) do -- AUDIO
        pointer:RefreshFrame(i)
    end
end

function PANEL:SetScrollOffset(offset)
    if offset < 0 then
        offset = 0
    elseif offset >= self.TotalFrames then
        offset = self.TotalFrames - 1
    end

    self.ScrollOffset = offset
    self:RefreshScrollBar()
    self:RefreshFrames()
end

function PANEL:CreateFramePointer(color, verticalPosition, pointyBottom)
    local pointer = vgui.Create("SMHFramePointer", self)
    pointer.Color = color
    pointer.VerticalPosition = verticalPosition
    pointer.PointyBottom = pointyBottom
    table.insert(self.FramePointers, pointer)

    return pointer
end

function PANEL:DeleteFramePointer(pointer)
    table.RemoveByValue(self.FramePointers, pointer)
    pointer:Remove()
end

-- AUDIO ======================================================
function PANEL:SortClipOrder()
	table.sort(self.AudioClipPointers, function(a, b)
		local aFrame = a:GetStartFrame()
		local bFrame = b:GetStartFrame()
		if aFrame == bFrame then
			return a:GetDuration() > b:GetDuration()
		else
			return aFrame < bFrame
		end
	end)
	self:RefreshFrames()
end

function PANEL:GetAudioClipPointerAtFrame(frame)
	--get all clips that exist at this frame
	local clips = {}
	for k,v in pairs(self.AudioClipPointers) do
		local startFrame = v:GetFrame()
		local endFrame = v:GetDuration()*SMH.State.PlaybackRate
		if startFrame <= frame and endFrame >= frame then
			table.insert(clips,v)
		end
	end
	--return last clip
	if not table.IsEmpty(clips) then
		return clips[#clips]
	end
end

function PANEL:CreateAudioClipPointer(audioClip)
    local pointer = vgui.Create("SMHAudioClipPointer", self)
	pointer:Setup(audioClip)
	table.insert(self.AudioClipPointers, pointer)
	self:SortClipOrder()

    return pointer
end

function PANEL:DeleteAudioClipPointer(pointer)
    table.RemoveByValue(self.AudioClipPointers, pointer)
    pointer:Remove()
end

function PANEL:DeleteAllAudioClipPointers()
	for k,v in pairs(self.AudioClipPointers) do
		v:Remove()
	end
	table.Empty(self.AudioClipPointers)
end
-- ============================================================

function PANEL:OnMousePressed(mousecode)
    if mousecode ~= MOUSE_LEFT then
        return
    end

    local startX, endX = unpack(self.FrameArea)
    local posX, posY = self:CursorPos()

    local targetX = posX - startX
    local width = endX - startX
    local framePosition = math.Round(self.ScrollOffset + (targetX / width) * (self.Zoom - 1))
    framePosition = framePosition < 0 and 0 or (framePosition >= self.TotalFrames and self.TotalFrames - 1 or framePosition)

    self:OnFramePressed(framePosition)
end

local scrollMultiplierConVar = GetConVar("smh_scrollmultiplier")

function PANEL:SetZoom(newZoom)
    self:SetValue(newZoom)
    self:ConVarChanged(tostring(newZoom))
end

local function validateZoom(newZoom)
    if newZoom < 30 then
        newZoom = 30
    end

    return newZoom
end

function PANEL:OnMouseWheeled(scrollDelta)
    scrollMultiplierConVar = scrollMultiplierConVar or GetConVar("smh_scrollmultiplier")

    scrollDelta = -scrollDelta
    local newZoom = self.Zoom + scrollDelta * scrollMultiplierConVar:GetFloat()
    newZoom = validateZoom(newZoom)

    self:SetZoom(newZoom)
end

function PANEL:OnScrollBarSizerPressed(mousecode, isLeft)
    if mousecode ~= MOUSE_LEFT then 
        return
    end

    local scrollBarSizer
    if isLeft then
        scrollBarSizer = self.ScrollBar.Left
    else
        scrollBarSizer = self.ScrollBar.Right
    end
    scrollBarSizer:MouseCapture(true)
    self._resizingScrollBar = true
    self._oldWidth = self.ScrollBar:GetWide()
    local cursorXOffset, _ = self.ScrollBar:CursorPos()
    self._scrollCursorOffset = cursorXOffset
    self._scrollCursorPos = self.ScrollBar:GetX()
end

function PANEL:OnScrollBarSizerReleased(mousecode, isLeft)
    if mousecode ~= MOUSE_LEFT then
        return
    end

    self.ScrollBar.Left:MouseCapture(false)
    self.ScrollBar.Right:MouseCapture(false)
    self._resizingScrollBar = false
end

function PANEL:ValidateScroll(movePos, movableWidth, numSteps)
    if movableWidth ~= 0 then
        local targetScrollOffset = math.Round((movePos / movableWidth) * numSteps)

        if targetScrollOffset >= 0 and targetScrollOffset <= numSteps and targetScrollOffset ~= self.ScrollOffset then
            self:SetScrollOffset(targetScrollOffset)
        end
    elseif self.ScrollOffset ~= 0 then
        self:SetScrollOffset(0)
    end
end

function PANEL:OnScrollBarSizerCursorMoved(x, y, isLeft)
    if not self._resizingScrollBar then
        return
    end

    local cursorX, _ = self:CursorPos()
    local movePos = cursorX - self._scrollCursorOffset - self._scrollCursorPos

    local newWidth = self._oldWidth + (isLeft and -movePos or movePos)
    local newZoom = validateZoom(newWidth * self.TotalFrames / self.ScrollBarRect.Width)
    self:SetZoom(newZoom)
    if isLeft then
        local movableWidth = self.ScrollBarRect.Width - newWidth
        local numSteps = self.TotalFrames - self.Zoom
        -- I prescribe an offset of 16 here to prevent the scroller from moving when clicking the left side
        -- TODO: Investigate where 16 offset comes from and apply the correct offset
        self:ValidateScroll(self._scrollCursorPos + movePos - 16, movableWidth, numSteps)
    end
end

function PANEL:OnScrollBarPressed(mousecode)
    if mousecode ~= MOUSE_LEFT then
        return
    end

    self.ScrollBar:MouseCapture(true)
    self._draggingScrollBar = true

    local cursorXOffset, _ = self.ScrollBar:CursorPos()
    self._scrollCursorOffset = cursorXOffset
end

function PANEL:SetValue(newValue)
    self.Zoom = newValue
    self:RefreshFrames()
    
    if not self.ScrollBarRect then return end
    self:RefreshScrollBar()
end

function PANEL:Think()
    local newMajor = GetConVar("smh_majortickinterval"):GetInt()
    if self.major ~= newMajor then
        self:UpdateMajor(newMajor)
    end
    self:ConVarNumberThink()
end

function PANEL:OnScrollBarReleased(mousecode)
    if mousecode ~= MOUSE_LEFT then
        return
    end

    self.ScrollBar:MouseCapture(false)
    self._draggingScrollBar = false
end

function PANEL:OnScrollBarCursorMoved(x, y)
    if not self._draggingScrollBar then
        return
    end

    local cursorX, _ = self:CursorPos()
    local movePos = cursorX - self._scrollCursorOffset - self.ScrollBarRect.X
    local movableWidth = self.ScrollBarRect.Width - self.ScrollBar:GetWide()
    local numSteps = self.TotalFrames - self.Zoom
    self:ValidateScroll(movePos, movableWidth, numSteps)
end

function PANEL:OnFramePressed(frame) end

vgui.Register("SMHFramePanel", PANEL, "DPanel")
