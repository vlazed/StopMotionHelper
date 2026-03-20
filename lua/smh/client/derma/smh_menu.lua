---@class SMHMenu: DFrame
---@field BaseClass DFrame
---@field FramePanel SMHFramePanel
---@field FramePointer SMHFramePointer
local PANEL = {}

---The first and second string is the identifier and the format string expected
---of the identifier. The last index is a table with the following labels:
---
---`{hours, minutes, seconds, frame % frameRate, adjustedFrame, frameCount}`
---
---where adjustedFrame accounts for the `smh_startatone` offset.
---
---I expect more position label formats, hence the use of a table
---to store these.
---
---@type {[1]: string, [2]: string, [3]: integer[]}[]
local labelFormats = {
    {"Position", "%d / %d", {5, 6}},
    {"Time", "%02d:%02d:%02d.%03d", {1, 2, 3, 4}},
}
local labelCount = #labelFormats

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

	return m, b
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

---This function positions the playback and navigation
---buttons such that they are centered on the timeline
---This is fed into DockMargin to preserve
---docking behavior
---@param width integer
---@return number
local function playbackScale(width)
    return math.max(width * 0.46875 - 400, 10)
end

---This function positions the popsition label
---to a specific spot
---This is fed into DockMargin to preserve
---docking behavior
---@param width integer
---@return number
local function positionLabelScale(width)
    return math.max(width * 0.53125 - 424, 10)
end

function PANEL:Init()

    self:SetTitle("Stop Motion Helper")
    self:SetSize(ScrW(), 90)
    self:SetPos(0, ScrH() - self:GetTall())
    self:SetDraggable(true)
    self:ShowCloseButton(false)
    self:SetDeleteOnClose(false)
    self:SetSizable(true)

    ---@type {[string]: DMenu}
    self.Menus = {}
    ---@type {[string]: DMenu}
    self.SubMenus = {}

    self.EditAudioTrack = false

    self.FramePanel = vgui.Create("SMHFramePanel", self)

    self.FramePointer = self.FramePanel:CreateFramePointer(Color(255, 255, 255), self.FramePanel:GetTall() / 4, true)

    self.TimelinesBase = vgui.Create("Panel", self)

    self.MenuBar = vgui.Create("Panel", self)
    self.MenuBar:DockPadding(0, 0, 2, 0)
    -- self.MenuBar:SetBackgroundColor(color_transparent)

    self.Help = self:AddMenu("Help...", function() self:OnRequestOpenHelp() end)
    self.Addons = self:AddMenu("Addons")
    self.Edit = self:AddMenu("Edit")
    self.File = self:AddMenu("File")
    self.Properties = self:AddMenu("Properties...", function() self:OnRequestOpenPropertiesMenu() end)
    self.Record, self.RecordButton = self:AddMenu("Record", function() self:OnRequestRecord() end)
    self.RecordButton:SetTooltip("Record a keyframe")
    self.RecordButton:SetTooltipDelay(0)

    self.NavigationPlayback = vgui.Create("Panel", self.MenuBar)

    self.NavigationPlayback:Dock(RIGHT)

    self.PositionBar = vgui.Create("Panel", self.MenuBar)
    self.PositionBar:Dock(RIGHT)

    self.PositionLabelCycle = 0
    self.PositionLabel = vgui.Create("DLabel", self.PositionBar)
    self.PositionLabel:SetTooltipDelay(0)
    self.PositionLabel:SetMouseInputEnabled(true)
    self.PositionLabel:Dock(RIGHT)
    self.PositionLabel:SetTooltip("Click to change time format")

    self.PositionLabel.DoClick = function(_)
        self.PositionLabelCycle = (self.PositionLabelCycle + 1) % labelCount
        self:UpdatePositionLabel(SMH.State.Frame, SMH.State.PlaybackLength, SMH.State.PlaybackRate)
    end

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
    audioClipToolOption:SetEnabled(self.EditAudioTrack)
    self.Edit:AddSpacer()
    self.Edit:AddOption("Settings...", function() self:OnRequestOpenSettings() end)

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

    -- self.PositionLabel:SetPos(150, 5)
    self.PositionBar:SetSize(300, 5)

    self.MenuBar:SetPos(0, 2)
    self.MenuBar:SetSize(width, 20)

    self.NavigationPlayback:SetTall(20)
    self.NavigationPlayback:SizeToChildren(true)

    self.NavigationPlayback:DockMargin(0, 0, playbackScale(width), 0)
    self.PositionBar:DockMargin(0, 0, positionLabelScale(width), 0)
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

---@param frame integer
---@param totalFrames integer
---@param rate integer
function PANEL:UpdatePositionLabel(frame, totalFrames, rate)
    local offset = GetConVar("smh_startatone"):GetInt()
    local adjustedFrame = frame + offset
    local total = totalFrames - (1 - offset)

    local seconds = adjustedFrame / rate
    local minutes = math.floor(seconds / 60)
    local hours = math.floor(minutes / 60)
    local timeFormat = {
        hours, minutes, seconds, frame % rate, adjustedFrame, total 
    }
    local format = labelFormats[self.PositionLabelCycle + 1]
    local selectedList = {}
    for _, key in ipairs(format[3]) do
        table.insert(selectedList, timeFormat[key])
    end

    self.PositionLabel:SetText(Format("%s: %s", format[1], Format(format[2], unpack(selectedList))))
    self.PositionLabel:SizeToContents()
end

---@param state State
function PANEL:SetInitialState(state)
    self:UpdatePositionLabel(state.Frame, state.PlaybackLength, state.PlaybackRate)
end

-- AUDIO
function PANEL:UpdateAudioTrackEditMode(edit)
	-- self.AudioClipTools:SetEnabled(edit)
end

function PANEL:SetVisible(bool)
    if not bool then
        for _, menu in pairs(self.SubMenus) do
            menu:SetVisible(bool)
        end
    end
    return self.BaseClass.SetVisible(self, bool)
end

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
