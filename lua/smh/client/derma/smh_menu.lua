---@class SMHMenu: DFrame
---@field BaseClass DFrame
local PANEL = {}

---@param parentMenu DMenu
---@param label string
---@param callback function?
---@return DMenu
function PANEL:AddSubMenu(parentMenu, label, callback)
    local m = parentMenu:AddSubMenu(label, callback)
    self.SubMenus[label] = m
    return m
end

function PANEL:AddMenu(label, callback)
	local m = DermaMenu()
	m:SetDeleteSelf( false )
	m:SetDrawColumn( true )
	self.Menus[ label ] = m
	self.SubMenus[ label ] = m

	local b = self.MenuBar:Add( "DButton" )
	b:SetText( label )
	b:Dock( RIGHT )
	b:DockMargin( 0, 0, 2, 0 )
	b:SetIsMenu( true )
	b:SetPaintBackground( true )
	b:SizeToContentsX( 16 )
	b.DoClick = function()

		if ( m:IsVisible() ) then
			m:Hide()
			return
		end

        local x, y = b:LocalToScreen( 0, 0 )
		m:Open( x, y - m:GetTall(), false, m )

        if isfunction(callback) then
            callback()
        end

	end

    if not callback then
        b.OnCursorEntered = function()
            local opened = self:GetOpenMenu()
            if ( not IsValid( opened ) or opened == m ) then return end
            ---@cast opened DMenu
            opened:Hide()
            b:DoClick()
        end
    end

	return m
end

function PANEL:GetOpenMenu()

	for k, v in pairs( self.Menus ) do
		if ( v:IsVisible() ) then return v end
	end

	return nil

end

---@param parent Panel
---@param image string
---@param tooltip string?
---@return DButton
local function addButton(parent, image, callback, tooltip)
    local b = parent:Add("DButton")
    b:SetText("")
    b:Dock(LEFT)
    
    b:SetIcon(image)
    b:DockPadding(2, 2, 2, 2)

    b:SizeToContents()
    ---@diagnostic disable
    b.m_Image:Dock(FILL)
    b.m_Image:SetKeepAspect(true)
    ---@diagnostic enable
    if tooltip then
        b:SetTooltip(tooltip)
        b:SetTooltipDelay(0)
    end

    b.DoClick = callback

    return b
end

function PANEL:Init()

    self:SetTitle("Stop Motion Helper")
    self:SetSize(ScrW(), 90)
    self:SetPos(0, ScrH() - self:GetTall())
    self:SetDraggable(false)
    self:ShowCloseButton(false)
    self:SetDeleteOnClose(false)
    self:ShowCloseButton(false)

    ---@type {[string]: DMenu}
    self.Menus = {}
    ---@type {[string]: DMenu}
    self.SubMenus = {}

    self._sendKeyframeChanges = true

    self.FramePanel = vgui.Create("SMHFramePanel", self)

    self.FramePointer = self.FramePanel:CreateFramePointer(Color(255, 255, 255), self.FramePanel:GetTall() / 4, true)

    self.TimelinesBase = vgui.Create("Panel", self)

    self.PositionLabel = vgui.Create("DLabel", self)

    self.MenuBar = vgui.Create("DPanel", self)
    self.MenuBar:SetPaintBackground(false)
    self.MenuBar:DockPadding(0, 0, 2, 0)
    -- self.MenuBar:SetBackgroundColor(color_transparent)
    
    self.NavigationPlayback = vgui.Create("DPanel", self)
    self.NavigationPlayback:SetPaintBackground(false)

    self.PlaybackRateControl = vgui.Create("DNumberWang", self)
    self.PlaybackRateControl:SetMinMax(1, 216000)
    self.PlaybackRateControl:SetDecimals(0)
    self.PlaybackRateControl:SetConVar("smh_fps")
    self.PlaybackRateControl.Think = function(self)
        self:ConVarNumberThink()
    end
    self.PlaybackRateControl.OnValueChanged = function(_, value)
        self:OnRequestStateUpdate({ PlaybackRate = tonumber(value) })
    end
    self.PlaybackRateControl.Label = vgui.Create("DLabel", self)
    self.PlaybackRateControl.Label:SetText("Framerate")
    self.PlaybackRateControl.Label:SizeToContents()

    self.PlaybackLengthControl = vgui.Create("DNumberWang", self)
    self.PlaybackLengthControl:SetMinMax(1, 100000)
    self.PlaybackLengthControl:SetDecimals(0)
    self.PlaybackLengthControl:SetConVar("smh_framecount")
    self.PlaybackLengthControl.Think = function(self)
        self:ConVarNumberThink()
    end
    self.PlaybackLengthControl.OnValueChanged = function(_, value)
        self:OnRequestStateUpdate({ PlaybackLength = tonumber(value) })
    end
    self.PlaybackLengthControl.Label = vgui.Create("DLabel", self)
    self.PlaybackLengthControl.Label:SetText("Frame count")
    self.PlaybackLengthControl.Label:SizeToContents()

    self.Easing = vgui.Create("Panel", self)

    self.EaseInControl = vgui.Create("DNumberWang", self.Easing)
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

    self.Help = self:AddMenu("Help...", function() self:OnRequestOpenHelp() end)
    self.Addons = self:AddMenu("Addons")
    self.Properties = self:AddMenu("Properties...", function() self:OnRequestOpenPropertiesMenu() end)
    self.Record = self:AddMenu("Record...", function() self:OnRequestRecord() end)
    self.Edit = self:AddMenu("Edit")
    self.File = self:AddMenu("File")

    local audioClipToolOption

    self.File:AddOption("New", function ()
        -- This could be used to clear up animation data
    end)
    self.File:AddOption("Save...", function() self:OnRequestOpenSaveMenu() end)
    self.File:AddOption("Load...", function() self:OnRequestOpenLoadMenu() end)
    self.File:AddSpacer()
    self.File:AddOption("Save Audio Sequence...", function() self:OnRequestOpenSaveAudioMenu() end)
    self.File:AddOption("Load Audio Sequence...", function() self:OnRequestOpenLoadAudioMenu() end)
    self.Keyframe = self:AddSubMenu(self.Edit, "Keyframes")
    self.Keyframe:AddOption("Record", function() self:OnRequestRecord() end)
    self.Keyframe:AddOption("Smooth...", function() self:OnRequestOpenSmoothMenu() end)
    self.Keyframe:AddOption("Stretch...", function() self:OnRequestOpenStretchMenu() end)
    self.Keyframe:SetDeleteSelf(false)
    self.Edit:AddOption("Settings...", function() self:OnRequestOpenSettings() end)
    self.Edit:AddSpacer()
    self.Edit:AddOption("Insert Audio...", function() self:OnRequestInsertAudioMenu() end)
    self.Edit:AddOption("Edit Audio Track", function()
        self.EditAudioTrack = not self.EditAudioTrack
        self:OnRequestEditAudioTrack(self.EditAudioTrack)
        if audioClipToolOption then
            audioClipToolOption:SetEnabled(self.EditAudioTrack)
        end
    end)
    audioClipToolOption = self.Edit:AddOption("Audio Clip Tools...", function()
        self:OnRequestAudioClipTools()
    end)

    self.Addons:AddOption("Physics Recorder", function()
        self:OnRequestOpenPhysRecorder()
    end)
    self.Addons:AddOption("Motion Paths", function()
        self:OnRequestOpenMotionPaths()
    end)


    self.SelectPrevious = addButton(self.NavigationPlayback, "icon16/arrow_left.png", function()
        self:OnSelectPrevious()
    end, "Select left keyframes")
    self.PreviousFrame = addButton(self.NavigationPlayback, "icon16/resultset_first.png", function()
        self:OnPreviousFrame()
    end, "Jump playhead to previous keyframe")
    self.Play = addButton(self.NavigationPlayback, "icon16/resultset_next.png", function()
        self:OnPlay()
    end)
    self.NextFrame = addButton(self.NavigationPlayback, "icon16/resultset_last.png", function()
        self:OnNextFrame()
    end, "Jump playhead to next keyframe")
    self.SelectNext = addButton(self.NavigationPlayback, "icon16/arrow_right.png", function()
        self:OnSelectNext()
    end, "Select right keyframes")
    self.SelectAll = addButton(self.NavigationPlayback, "icon16/arrow_in.png", function()
        self:OnSelectAll()
    end, "Select all keyframes")

    self.Easing:SetVisible(false)

    -- Hack to get menus to update their sizes
    -- This prevents the menu from opening at the cursor location
	self.Addons:Open()
    self.Edit:Open()
    self.File:Open()
	self.Addons:Hide()
    self.Edit:Hide()
    self.File:Hide()
end

function PANEL:PerformLayout(width, height)

    ---@diagnostic disable-next-line
    self.BaseClass.PerformLayout(self, width, height)

    self:SetTitle("Stop Motion Helper")

    self.FramePanel:SetPos(5, 40)
    self.FramePanel:SetSize(width - 5 * 2, 45)

    self.FramePointer.VerticalPosition = self.FramePanel:GetTall() / 4

    self.TimelinesBase:SetPos(0, 25)
    self.TimelinesBase:SetSize(ScrW(),15)

    self.PositionLabel:SetPos(150, 5)

    self.PlaybackRateControl:SetPos(340, 2)
    self.PlaybackRateControl:SetSize(50, 20)
    local sizeX, sizeY = self.PlaybackRateControl.Label:GetSize()
    self.PlaybackRateControl.Label:SetRelativePos(self.PlaybackRateControl, -(sizeX) - 5, 3)

    self.PlaybackLengthControl:SetPos(460, 2)
    self.PlaybackLengthControl:SetSize(50, 20)
    sizeX, sizeY = self.PlaybackLengthControl.Label:GetSize()
    self.PlaybackLengthControl.Label:SetRelativePos(self.PlaybackLengthControl, -(sizeX) - 5, 3)

    self.Easing:SetPos(540, 0)
    self.Easing:SetSize(250, 30)

    self.EaseInControl:SetPos(60, 2)
    self.EaseInControl:SetSize(50, 20)
    sizeX, sizeY = self.EaseInControl.Label:GetSize()
    self.EaseInControl.Label:SetRelativePos(self.EaseInControl, -(sizeX) - 5, 3)

    self.EaseOutControl:SetPos(160, 2)
    self.EaseOutControl:SetSize(50, 20)
    sizeX, sizeY = self.EaseOutControl.Label:GetSize()
    self.EaseOutControl.Label:SetRelativePos(self.EaseOutControl, -(sizeX) - 5, 3)

    self.MenuBar:SetPos(0, 2)
    self.MenuBar:SetSize(width, 20)

    self.NavigationPlayback:SetSize(width * 0.25, 20)
    self.NavigationPlayback:SetPos(width * 0.52125 - self.NavigationPlayback:GetWide() * 0.25, 2)

end

---@param timelineinfo TimelineSetting
function PANEL:UpdateTimelines(timelineinfo)
    self.TimelinesBase:Clear()

    if next(timelineinfo) == nil then return end --check if supplied table is empty
    local TotallTimelines = timelineinfo.Timelines
    if TotallTimelines < SMH.State.Timeline then SMH.State.Timeline = 1 end
    self.TimelinesBase.Timeline = {}

    for i = 1, TotallTimelines do
        self.TimelinesBase.Timeline[i] = vgui.Create("DPanel", self.TimelinesBase)
        self.TimelinesBase.Timeline[i]:SetPos((i - 1) * (ScrW() / TotallTimelines) + 4,0)
        self.TimelinesBase.Timeline[i]:SetSize((ScrW() / TotallTimelines) - 8,15)
        if i == SMH.State.Timeline then
            self.TimelinesBase.Timeline[i]:SetBackgroundColor(Color(220, 220, 220, 255))
        else
            self.TimelinesBase.Timeline[i]:SetBackgroundColor(Color(175, 175, 175, 255))
        end

        self.TimelinesBase.Timeline[i].Label = vgui.Create("DLabel", self.TimelinesBase.Timeline[i])
        self.TimelinesBase.Timeline[i].Label:SetText("Timeline " .. i)
        self.TimelinesBase.Timeline[i].Label:SetTextColor(Color(100, 100, 100))
        self.TimelinesBase.Timeline[i].Label:SizeToContents()
        self.TimelinesBase.Timeline[i].Label:Center()

        self.TimelinesBase.Timeline[i]._pressed = false
        self.TimelinesBase.Timeline[i].OnMousePressed = function(_, mousecode)
            if mousecode ~= MOUSE_LEFT then return end

            SMH.State.Timeline = i
            SMH.State.TimeStamp = RealTime()
            SMH.Controller.UpdateTimeline()

            for j = 1, TotallTimelines do
                if j ~= i then
                    self.TimelinesBase.Timeline[j]:SetBackgroundColor(Color(175, 175, 175, 255))
                else
                    self.TimelinesBase.Timeline[j]:SetBackgroundColor(Color(220, 220, 220, 255))
                end
            end
        end
    end
end

---@param state State
function PANEL:SetInitialState(state)
    self.PlaybackRateControl:SetValue(state.PlaybackRate)
    self.PlaybackLengthControl:SetValue(state.PlaybackLength)
    self:UpdatePositionLabel(state.Frame, state.PlaybackLength)
end

---@param frame integer
---@param totalFrames integer
function PANEL:UpdatePositionLabel(frame, totalFrames)
    local offset = GetConVar("smh_startatone"):GetInt()
    self.PositionLabel:SetText("Position: " .. frame + offset .. " / " .. totalFrames - (1 - offset))
    self.PositionLabel:SizeToContents()
end

-- AUDIO
function PANEL:UpdateAudioTrackEditMode(edit)
	-- self.AudioClipTools:SetEnabled(edit)
end

---@param easeIn number
---@param easeOut number
function PANEL:ShowEasingControls(easeIn, easeOut)
    self._sendKeyframeChanges = false
    self.EaseInControl:SetValue(easeIn)
    self.EaseOutControl:SetValue(easeOut)
    self.Easing:SetVisible(true)
    self._sendKeyframeChanges = true
end

function PANEL:HideEasingControls()
    self.Easing:SetVisible(false)
end

function PANEL:SetVisible(bool)
    if not bool then
        for _, menu in pairs(self.SubMenus) do
            menu:SetVisible(bool)
        end
    end
    return self.BaseClass.SetVisible(self, bool)
end

---@param newState NewState
function PANEL:OnRequestStateUpdate(newState) end
---@param newKeyframeData any
function PANEL:OnRequestKeyframeUpdate(newKeyframeData) end
function PANEL:OnRequestOpenPropertiesMenu() end
function PANEL:OnRequestRecord() end
function PANEL:OnRequestOpenSaveMenu() end
function PANEL:OnRequestOpenLoadMenu() end
function PANEL:OnRequestOpenSettings() end
function PANEL:OnRequestOpenStretchMenu() end
function PANEL:OnRequestOpenSmoothMenu() end
function PANEL:OnRequestOpenHelp() end
function PANEL:OnRequestOpenPhysRecorder() end
function PANEL:OnRequestOpenMotionPaths() end

function PANEL:OnSelectPrevious() end
function PANEL:OnPreviousFrame() end
function PANEL:OnPlay() end
function PANEL:OnNextFrame() end
function PANEL:OnSelectNext() end
function PANEL:OnSelectAll() end

-- AUDIO =========================================
function PANEL:OnRequestInsertAudioMenu() end
function PANEL:OnRequestEditAudioTrack(bool) end
function PANEL:OnRequestAudioClipTools() end
function PANEL:OnRequestOpenSaveAudioMenu() end
function PANEL:OnRequestOpenLoadAudioMenu() end
-- ===============================================

vgui.Register("SMHMenu", PANEL, "DFrame")
