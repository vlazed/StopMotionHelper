---@type SMHWorldClicker
local WorldClicker = nil
---@type SMHTooltip
local Tooltip = nil
---@type SMHSave
local SaveMenu = nil
---@type SMHLoad
local LoadMenu = nil
---@type SMHProperties
local PropertiesMenu = nil

---@type {[integer]: integer}
local FrameToKeyframe = {}
---@type FramePointerDictionary
local KeyframePointers = {}
---@type {[integer]: EasingData}
local KeyframeEasingData = {}
---@type {[integer]: integer}
local KeyframeIDs = {}
---@type FramePointerDictionary
local SelectedPointers = {}
local OffsetPointers = {}
local LocalIDs = 0

local AudioClipPointers = {}

local LastSelectedKeyframe = nil
local KeyColor = Color(0, 200, 0)

local ClickerEntity = {}

---@param pointer SMHFramePointer
local function DeleteEmptyKeyframe(pointer)
    for id, kpointer in pairs(KeyframePointers) do
        if pointer == kpointer then
            if KeyframePointers[id] == LastSelectedKeyframe then LastSelectedKeyframe = nil end
            SelectedPointers[id] = nil
            WorldClicker.MainMenu.FramePanel:DeleteFramePointer(kpointer)
            KeyframePointers[id] = nil
            KeyframeEasingData[id] = nil

            for frame, kid in pairs(FrameToKeyframe) do
                if kid == id then
                    FrameToKeyframe[frame] = nil
                    break
                end
            end
            break
        end
    end
end

---@param keyframeId integer
local function CreateCopyPointer(keyframeId)
    OffsetPointers = {}
    local KeysToDelete, KeysToCopy, FramesToSend = {}, {}, {}
    local originFrame = KeyframePointers[keyframeId]:GetFrame()

    local counter = 1

    for id, kpointer in pairs(SelectedPointers) do
        if id == keyframeId then continue end
        local difference = kpointer:GetFrame() - originFrame

        kpointer:SetSelected(false)
        SelectedPointers[id] = nil

        local pointer = WorldClicker.MainMenu.FramePanel:CreateFramePointer(
        KeyColor,
        WorldClicker.MainMenu.FramePanel:GetTall() / 4 * 2.2,
        false
        )

        table.insert(OffsetPointers, pointer)
        pointer:SetFrame(originFrame + difference)
        pointer:SetSelected(true)
        pointer.NewID = LocalIDs + counter
        pointer.keyframeId = id

        counter = counter + 1
    end

    local pointer = WorldClicker.MainMenu.FramePanel:CreateFramePointer(
        KeyColor,
        WorldClicker.MainMenu.FramePanel:GetTall() / 4 * 2.2,
        false
    )

    pointer:SetFrame(originFrame)
    local minimum, maximum = 0, 0
    for _, kpointer in ipairs(OffsetPointers) do
        kpointer:SetParentPointer(pointer)
        local difference = kpointer:GetFrame() - pointer:GetFrame()
        if minimum > difference then
            minimum = difference
        elseif maximum < difference then
            maximum = difference
        end
    end

    pointer:OnMousePressed(MOUSE_LEFT)
    pointer:SetOffsets(minimum, maximum)
    pointer.NewID = LocalIDs + counter

    local function ProcessCopyKey(pointer, NewID, frame, keyframeId)
        WorldClicker.MainMenu.FramePanel:DeleteFramePointer(pointer)
        if frame < 0 then return end

        for id, _ in pairs(KeyframePointers[keyframeId]:GetIDs()) do
            table.insert(KeysToCopy, id)
            table.insert(FramesToSend, frame)
        end

        for id, pointer in pairs(KeyframePointers) do
            if id == NewID then continue end
            if pointer:GetFrame() == frame then

                for ent, id in pairs(pointer:GetEnts()) do
                    if not KeyframePointers[keyframeId]:GetEnts()[ent] then
                        table.insert(KeysToCopy, id)
                        table.insert(FramesToSend, frame)
                    end
                end

                table.insert(KeysToDelete, pointer)
            end
        end
    end

    pointer.OnPointerReleased = function(_, frame)
        for _, kpointer in ipairs(OffsetPointers) do
            ProcessCopyKey(kpointer, kpointer.NewID, kpointer:GetFrame(), kpointer.keyframeId)
        end
        OffsetPointers = {}
        ProcessCopyKey(pointer, pointer.NewID, frame, keyframeId)

        SMH.Controller.CopyKeyframe(KeysToCopy, FramesToSend)

        for _, dpointer in ipairs(KeysToDelete) do
            DeleteEmptyKeyframe(dpointer)
        end
    end
end

---@param keyframeId integer
---@return SMHFramePointer
local function NewKeyframePointer(keyframeId)

    local pointer = WorldClicker.MainMenu.FramePanel:CreateFramePointer(
        KeyColor,
        WorldClicker.MainMenu.FramePanel:GetTall() / 4 * 2.2,
        false
    )

    pointer.OnPointerReleased = function(_, frame)
        local KeysToDelete, KeysToUpdate, UpdateStuff = {}, {}, {}

        local function ReleaseAction(pointer, keyframeId, frame)
            if frame < 0 then
                for id, _ in pairs(pointer:GetIDs()) do
                    table.insert(KeysToDelete, id)
                end
                return
            end

            for id, _ in pairs(pointer:GetIDs()) do
                table.insert(KeysToUpdate, id)
                table.insert(UpdateStuff, { Frame = frame })
            end

            for id, kpointer in pairs(KeyframePointers) do
                if id == keyframeId then continue end

                if kpointer:GetFrame() == frame then
                    for ent, id in pairs(kpointer:GetEnts()) do
                        if not pointer:GetEnts()[ent] then
                            pointer:AddID(id, ent) -- gonna leave this logic in for the future stuff
                            KeyframeIDs[id] = KeyframeIDs[keyframeId]
                            kpointer:RemoveID(id)
                        end
                    end
                    DeleteEmptyKeyframe(kpointer)
                end
            end
        end

        for id, pointer in pairs(SelectedPointers) do
            ReleaseAction(pointer, id, pointer:GetFrame())
        end

        ReleaseAction(pointer, keyframeId, frame)

        if next(KeysToDelete) then
            SMH.Controller.DeleteKeyframe(KeysToDelete)
        end
        if next(KeysToUpdate) then
            SMH.Controller.UpdateKeyframe(KeysToUpdate, UpdateStuff)
        end
    end

    pointer.OnCustomMousePressed = function(_, mousecode)
        local frame = pointer:GetFrame()
        local KeysToDelete = {}

        if SelectedPointers[keyframeId] then
            pointer:SetSelected(false)
            if pointer == LastSelectedKeyframe then LastSelectedKeyframe = nil end
            SelectedPointers[keyframeId] = nil
        end

        if mousecode == MOUSE_RIGHT and not input.IsKeyDown(KEY_LCONTROL) then
            for id, kpointer in pairs(SelectedPointers) do
                if kpointer == LastSelectedKeyframe then LastSelectedKeyframe = nil end
                for id, _ in pairs(kpointer:GetIDs()) do
                    table.insert(KeysToDelete, id)
                end
            end
            for id, _ in pairs(pointer:GetIDs()) do
                table.insert(KeysToDelete, id)
            end
        elseif mousecode == MOUSE_MIDDLE or (mousecode == MOUSE_RIGHT and input.IsKeyDown(KEY_LCONTROL)) then
            CreateCopyPointer(keyframeId)
        end

        if next(KeysToDelete) then
            SMH.Controller.DeleteKeyframe(KeysToDelete)
        end
    end

    return pointer
end

-- AUDIO ===========================================
local function NewAudioClipPointer(audioClip)

    local pointer = WorldClicker.MainMenu.FramePanel:CreateAudioClipPointer(audioClip)
	pointer.OnPointerReleased = function(_, frame)
		--update start frame
		audioClip.Frame = frame
		SMH.Controller.UpdateServerAudio()
	end
	
	return pointer
end
-- =================================================

local function AddCallbacks()

    local lastEntity = NULL
    local entityCount = 1
    WorldClicker.OnEntitySelected = function(_, entity, multiselect)
        if entity:GetNW2Bool("SMHGhost") and entity:GetNW2Entity("Entity") then entity = entity:GetNW2Entity("Entity") end
        
        -- Cycle through an entity's bonemerged items with the WorldClicker
        if lastEntity == entity then
            local n = #entity:GetChildren() + 1
            local newEntity = entity:GetChildren()[entityCount]
            entityCount = n > 0 and (entityCount + 1) % n or 1
            entity = newEntity and newEntity:GetModel() and newEntity or entity
        else
            entityCount = 1
            lastEntity = entity
        end

        local enttable = table.Copy(SMH.State.Entity)
        if multiselect == 1 then
            enttable[entity] = true
        elseif multiselect == 2 then
            enttable[entity] = nil
            entity = nil
        else
            enttable = {}
            enttable[entity] = true
        end
        SMH.Controller.SelectEntity(entity, enttable)
    end

    WorldClicker.OnVisibilityChange = function(_, visible)
        Tooltip:SetVisible(visible)
    end

    WorldClicker.OnEntityHovered = function(_, entity)
        Tooltip:SetTooltip(entity and not entity:GetNW2Bool("SMHGhost") and PropertiesMenu:GetEntityName(entity) or "")
        Tooltip:SetPos(input.GetCursorPos())
    end

    WorldClicker.MainMenu.OnRequestStateUpdate = function(_, newState)
        SMH.Controller.UpdateState(newState)
		WorldClicker.MainMenu.FramePanel:RefreshFrames()
    end
    WorldClicker.MainMenu.OnRequestKeyframeUpdate = function(_, newKeyframeData)
        local keyframes = {}
        for id, pointer in pairs(KeyframePointers) do
            if pointer:GetFrame() == SMH.State.Frame then
                for id, ent in pairs(pointer:GetIDs()) do
                    table.insert(keyframes, id)
                end
                SMH.Controller.UpdateKeyframe(keyframes, newKeyframeData, true)
                break
            end
        end
    end
    WorldClicker.MainMenu.OnRequestOpenPropertiesMenu = function()
        local frame = SMH.State.Frame

        PropertiesMenu:SetVisible(true)
        PropertiesMenu:UpdateTimelineSettings()
        SMH.Controller.GetServerEntities()

        if FrameToKeyframe[frame] ~= nil and PropertiesMenu:GetUsingWorld() then
            SMH.Controller.RequestWorldData(frame)
        else
            PropertiesMenu:HideWorldSettings()
        end
    end
    WorldClicker.MainMenu.OnRequestRecord = function()
        SMH.Controller.Record()
    end
	
	-- AUDIO MENUS =======================================================
	WorldClicker.MainMenu.OnRequestInsertAudioMenu = function()
		InsertAudioMenu:SetVisible(true)
    end
	
	InsertAudioMenu.OnInsertAudioRequested = function(_, path)
		SMH.Controller.AddAudio(path)
	end
	
	WorldClicker.MainMenu.OnRequestEditAudioTrack = function()
		local bool = WorldClicker.MainMenu.EditAudioTrack:GetChecked()
		WorldClicker.MainMenu:UpdateAudioTrackEditMode(bool)
		WorldClicker.AudioClipToolsMenu:SetEnabled(bool)
		SMH.State.EditAudioTrack = bool
    end
	
	WorldClicker.MainMenu.OnRequestAudioClipTools = function()
		if WorldClicker.AudioClipToolsMenu:IsVisible() then
			WorldClicker.AudioClipToolsMenu:SetVis(false)
		else
			WorldClicker.AudioClipToolsMenu:SetVis(true)
		end
	end
	
	-- AUDIO TOOLS =======================================================
	WorldClicker.AudioClipToolsMenu.OnRequestAudioClipDelete = function()
		local pointer = WorldClicker.MainMenu.FramePanel:GetAudioClipPointerAtFrame(SMH.State.Frame)
		if pointer then
			SMH.Controller.DeleteAudio(pointer:GetID(), pointer)
		end
	end
	WorldClicker.AudioClipToolsMenu.OnRequestAudioClipDeleteAll = function()
		SMH.Controller.DeleteAllAudio()
	end
	
	-- AUDIO SAVE ========================================================
	WorldClicker.MainMenu.OnRequestOpenSaveAudioMenu = function()
        SaveAudioMenu:SetVisible(true)
        SaveAudioMenu:SetSaves(SMH.AudioSeqSaves.ListFiles())
    end
    WorldClicker.MainMenu.OnRequestOpenLoadAudioMenu = function()
        LoadAudioMenu:SetVisible(true)
        LoadAudioMenu:SetSaves(SMH.AudioSeqSaves.ListFiles())
    end
	-- ===================================================================
	
	WorldClicker.MainMenu.OnRequestOpenSaveMenu = function()
        SaveMenu:SetVisible(true)
        SMH.Controller.GetServerSaves()
    end
    WorldClicker.MainMenu.OnRequestOpenLoadMenu = function()
        LoadMenu:SetVisible(true)
        SMH.Controller.GetServerSaves()
    end
	
    WorldClicker.MainMenu.OnRequestOpenSettings = function()
        WorldClicker.Settings:ApplySettings(SMH.Settings.GetAll())
        WorldClicker.Settings:SetVisible(true)
    end

    WorldClicker.MainMenu.FramePanel.OnFramePressed = function(_, frame)
        SMH.Controller.SetFrame(frame)
    end

    WorldClicker.MainMenu.FramePointer.OnFrameChanged = function(_, newFrame)
        SMH.Controller.SetFrame(newFrame)
    end

    WorldClicker.KeyframeSettings.OnRequestSelectFrames = function(_, increment)
        local start = increment == 0 and 0 or SMH.State.Frame
        local checkLeft = increment < 0
        for _, kpointer in pairs(KeyframePointers) do
            if Either(checkLeft, start >= kpointer:GetFrame(), start <= kpointer:GetFrame()) then
                SMH.UI.ToggleSelect(kpointer)
                -- HACK: ToggleSelect does not finalize the timeline placement of keyframes 
                -- during offsetting, which results in "ghost" keyframes 
                -- (EaseIn and EaseOut UI appear when no keyframes are present). 
                -- This workaround fixes that issue.
                if not kpointer:GetSelected() then
                    kpointer:OnPointerReleased(kpointer:GetFrame())
                end
            end
        end
    end

    WorldClicker.KeyframeSettings.OnRequestSmooth = function(_)
        RunConsoleCommand("smh_smooth", tostring(WorldClicker.KeyframeSettings.Smoothing))
    end

    WorldClicker.Settings.OnSettingsUpdated = function(_, newSettings)
        SMH.Controller.UpdateSettings(newSettings)
        local ghoststuff = {
            GhostPrevFrame = true,
            GhostNextFrame = true,
            OnionSkin = true,
            GhostAllEntities = true,
            GhostTransparency = true,
        }
        for name, value in pairs(newSettings) do
            if ghoststuff[name] then
                SMH.Controller.UpdateGhostState()
                break
            end
        end
    end
    WorldClicker.Settings.OnRequestOpenPhysRecorder = function()
        WorldClicker.PhysRecorder:SetVisible(true)
    end
    WorldClicker.Settings.OnRequestOpenMotionPaths = function()
        WorldClicker.MotionPaths:SetVisible(true)
    end
    WorldClicker.Settings.OnRequestOpenHelp = function()
        SMH.Controller.OpenHelp()
    end

    SaveMenu.OnSaveRequested = function(_, path, saveToClient)
        SMH.Controller.RequestSave(path, saveToClient, false)
    end
    SaveMenu.OnOverwriteSave = function(_, path)
        SMH.Controller.Save(path)
    end
    SaveMenu.OnAppendRequested = function(_, path)
        SMH.Controller.RequestAppend(path)
    end
    SaveMenu.OnAppend = function(_, path, savenames, gamenames)
        SMH.Controller.Append(path, savenames, gamenames)
    end
    SaveMenu.OnFolderRequested = function(_, path, saveToClient)
        SMH.Controller.RequestSave(path, saveToClient, true)
    end
    SaveMenu.OnGoToFolderRequested = function(_, path, toClient)
        SMH.Controller.RequestGoToFolder(path, toClient)
    end
    SaveMenu.OnPackRequested = function()
        SMH.Controller.RequestPack()
    end
    SaveMenu.OnDeleteRequested = function(_, path, isFolder, deleteFromClient)
        SMH.Controller.DeleteSave(path, isFolder, deleteFromClient)
    end

    LoadMenu.OnModelListRequested = function(_, path, loadFromClient)
        SMH.Controller.GetModelList(path, loadFromClient)
        SMH.Controller.SpawnReset()
        WorldClicker.SpawnMenu:SetSaveFile(path)
    end
    LoadMenu.OnLoadRequested = function(_, path, modelName, loadFromClient)
        SMH.Controller.Load(path, modelName, loadFromClient)
    end
    LoadMenu.OnGoToFolderRequested = function (_, path, toClient) 
        SMH.Controller.RequestGoToFolder(path, toClient)
        SMH.Controller.SetSpawnGhost(false)
        WorldClicker.SpawnMenu:SetSaveFile(nil)
    end
    LoadMenu.OnModelInfoRequested = function(_, path, modelName, loadFromClient)
        SMH.Controller.GetModelInfo(path, modelName, loadFromClient)
    end
    LoadMenu.OpenSpawnMenu = function()
        LoadMenu:Close()
        WorldClicker.SpawnMenu:SetVisible(true)
        SMH.Controller.SetSpawnGhost(true)
    end
	
	-- AUDIO =============================================
	SaveAudioMenu.OnSaveRequested = function(_, path)
        SMH.Controller.SaveAudioSeq(path)
		SaveAudioMenu:AddSave(path)
    end
    SaveAudioMenu.OnDeleteRequested = function(_, path)
        SMH.Controller.DeleteAudioSeq(path)
		SaveAudioMenu:RemoveSave(path)
    end

    LoadAudioMenu.OnLoadRequested = function(_, path, setFrameRate)
        SMH.Controller.LoadAudioSeq(path, setFrameRate)
    end
	-- ===================================================

    WorldClicker.SpawnMenu.OnClose = function()
        SMH.Controller.SetSpawnGhost(false)
    end
    WorldClicker.SpawnMenu.OnOriginRequested = function(_, path, model, loadFromClient)
        SMH.Controller.SetSpawnOrigin(path, model, loadFromClient)
    end
    WorldClicker.SpawnMenu.OnModelRequested = function(_, path, model, loadFromClient)
        SMH.Controller.SetPreviewEntity(path, model, loadFromClient)
        SMH.Controller.SetSpawnGhost(true)
    end
    WorldClicker.SpawnMenu.OnSpawnRequested = function(_, path, model, loadFromClient)
        SMH.Controller.SpawnEntity(path, model, loadFromClient)
    end
    WorldClicker.SpawnMenu.SetOffsetMode = function(_, set)
        SMH.Controller.SetSpawnOffsetMode(set)
    end

    PropertiesMenu.ApplyName = function(_, ent, name)
        SMH.Controller.ApplyEntityName(ent, name)
    end
    PropertiesMenu.SelectEntity = function(_, ent)
        local enttable = {}
        enttable[ent] = true
        SMH.Controller.SelectEntity(ent, enttable)
    end
    PropertiesMenu.OnAddTimelineRequested = function()
        SMH.Controller.AddTimeline()
    end
    PropertiesMenu.OnRemoveTimelineRequested = function()
        SMH.Controller.RemoveTimeline()
    end
    PropertiesMenu.OnUpdateModifierRequested = function(_, i, mod, check)
        SMH.Controller.UpdateModifier(i, mod, check)
    end
    PropertiesMenu.OnUpdateKeyframeColorRequested = function(_, color, timeline)
        SMH.Controller.UpdateKeyframeColor(color, timeline)
    end
    PropertiesMenu.SelectWorld = function()
        local enttable = {}
        enttable[LocalPlayer()] = true
        SMH.Controller.SelectEntity(LocalPlayer(), enttable)
    end
    PropertiesMenu.SetData = function(_, str, key)
        SMH.Controller.UpdateWorld(str, key)
    end
    PropertiesMenu.SetSettings = function(_, settings, presetname)
        SMH.Controller.SetTimeline(settings, presetname)
    end
    PropertiesMenu.SaveSettingsPreset = function(_, name)
        SMH.Controller.RequestTimelineInfo(name)
    end

end


local function setupUI()
    Tooltip = vgui.Create("SMHTooltip")
    WorldClicker = vgui.Create("SMHWorldClicker")

    WorldClicker.MainMenu = vgui.Create("SMHMenu", WorldClicker)

    WorldClicker.KeyframeSettings = vgui.Create("SMHKeyframeSettings", WorldClicker)
    WorldClicker.KeyframeSettings:SetPos(ScrW() * 0.5 - WorldClicker.KeyframeSettings.Width * 0.5, ScrH() - 90 - WorldClicker.KeyframeSettings.Height)

    WorldClicker.Settings = vgui.Create("SMHSettings", WorldClicker)
    WorldClicker.Settings:SetPos(ScrW() - WorldClicker.Settings.Width, ScrH() - 90 - WorldClicker.Settings.Height)
    WorldClicker.Settings:SetVisible(false)

    WorldClicker.PhysRecorder = vgui.Create("SMHPhysRecord", WorldClicker)
    WorldClicker.PhysRecorder:SetPos(ScrW() - 250 - 250, ScrH() - 90 - 170)
    WorldClicker.PhysRecorder:SetVisible(false)

    WorldClicker.MotionPaths = vgui.Create("SMHMotionPaths", WorldClicker)
    WorldClicker.MotionPaths:SetPos(ScrW() - 250 - WorldClicker.MotionPaths.Width, ScrH() - 90 - WorldClicker.MotionPaths.Height)
    WorldClicker.MotionPaths:SetVisible(false)

    SaveMenu = vgui.Create("SMHSave")
    SaveMenu:MakePopup()
    SaveMenu:SetVisible(false)

    LoadMenu = vgui.Create("SMHLoad")
    LoadMenu:MakePopup()
    LoadMenu:SetVisible(false)
	
	-- AUDIO =====================================
	SaveAudioMenu = vgui.Create("SMHSaveAudio")
    SaveAudioMenu:MakePopup()
    SaveAudioMenu:SetVisible(false)
	
	LoadAudioMenu = vgui.Create("SMHLoadAudio")
    LoadAudioMenu:MakePopup()
    LoadAudioMenu:SetVisible(false)
	
	InsertAudioMenu = vgui.Create("SMHInsertAudio", WorldClicker)
    InsertAudioMenu:SetVisible(false)
	
	WorldClicker.AudioClipToolsMenu = vgui.Create("SMHAudioClipTools", WorldClicker)
    WorldClicker.AudioClipToolsMenu:SetPos(ScrW() - 458, ScrH() - 220)
	-- ===========================================

    WorldClicker.SpawnMenu = vgui.Create("SMHSpawn", WorldClicker)
    WorldClicker.SpawnMenu:SetPos(0, ScrH() - 405 - 90)
    WorldClicker.SpawnMenu:SetVisible(false)

    PropertiesMenu = vgui.Create("SMHProperties")
    PropertiesMenu:MakePopup()
    PropertiesMenu:SetVisible(false)

    AddCallbacks()

    SMH.Controller.RequestModifiers() -- needed to initialize properties menu
    PropertiesMenu:InitTimelineSettings()

    WorldClicker.MainMenu:SetInitialState(SMH.State)
end

hook.Add("EntityRemoved", "SMHWorldClickerEntityRemoved", function(entity)

    for centity, _ in pairs(ClickerEntity) do
        if entity == centity then
            SMH.State.Entity[entity] = nil
            SMH.State.TimeStamp = RealTime()
            WorldClicker:OnEntitySelected(entity, 2)
        end
    end

end)

hook.Add("InitPostEntity", "SMHMenuSetup", function()
    setupUI()
end)

local MGR = {}

function MGR.IsOpen()
    return WorldClicker:IsVisible()
end

function MGR.Open()
    if not WorldClicker then
        setupUI()
    end

    WorldClicker:SetVisible(true)
end

function MGR.Close()
    WorldClicker:SetVisible(false)
end

function MGR.ScrubAudio(frame, lastFrame, sampleTime)
    for _, audioClip in pairs(SMH.AudioClipData.AudioClips) do
        local totalFrames = audioClip.Duration * SMH.State.PlaybackRate
        if audioClip.Frame <= frame and math.abs(audioClip.Frame - frame) < totalFrames then            
            local oldRate = audioClip.AudioChannel:GetPlaybackRate()
            local frameDifference = math.abs(frame - lastFrame)
            local totalTime = (1 / SMH.State.PlaybackRate + math.abs(sampleTime / frameDifference)) * frameDifference
            local sign = (frame - lastFrame) >= 0 and 1 or -1
            if audioClip.AudioChannel:GetState() ~= GMOD_CHANNEL_PLAYING then
                SMH.AudioClip.Play(audioClip.ID, (frame - audioClip.Frame) / totalFrames * audioClip.Duration)
            end
            audioClip.AudioChannel:SetPlaybackRate(sign)
            timer.Simple(totalTime, function()
                SMH.AudioClip.Stop(audioClip.ID)
                audioClip.AudioChannel:SetPlaybackRate(oldRate)
            end)
        end
    end
end

local lastFrame = nil
function MGR.SetFrame(frame)
    lastFrame = lastFrame or frame
    local sampleTime = 0.1
    if not WorldClicker.MainMenu.FramePointer:IsDragging() then
        WorldClicker.MainMenu.FramePointer:SetFrame(frame)
    else
        MGR.ScrubAudio(frame, lastFrame, sampleTime)
    end
    timer.Simple(sampleTime, function()
        lastFrame = frame
    end)
    
    WorldClicker.MainMenu:UpdatePositionLabel(frame, SMH.State.PlaybackLength)

    if not PropertiesMenu:GetUsingWorld() then
        if FrameToKeyframe[frame] ~= nil then
            local data = KeyframeEasingData[FrameToKeyframe[frame]]
            if data then
                WorldClicker.MainMenu:ShowEasingControls(data.EaseIn, data.EaseOut)
            else
                WorldClicker.MainMenu:ShowEasingControls(0, 0)
            end
        else
            WorldClicker.MainMenu:HideEasingControls()
        end
    end
end

---@param frame integer
---@return any?
function MGR.IsFrameKeyframe(frame)
	if FrameToKeyframe[frame] then
		return KeyframeEasingData[FrameToKeyframe[frame]]		
	end
end

function MGR.SetKeyframes(keyframes, isreceiving)
    local propertymods = PropertiesMenu:GetCurrentModifiers()

    if not isreceiving then
        for _, pointer in pairs(KeyframePointers) do
            WorldClicker.MainMenu.FramePanel:DeleteFramePointer(pointer)
        end

        if not propertymods.KeyColor then
            KeyColor = Color(0, 200, 0)
        else
            KeyColor = propertymods.KeyColor
        end

        KeyframePointers = {}
        FrameToKeyframe = {}
        SelectedPointers = {}
        KeyframeIDs = {}
        LastSelectedKeyframe = nil
    end

    local Modifiers = {}
    for _, name in ipairs(propertymods) do
        Modifiers[name] = true
    end

    if not PropertiesMenu:GetUsingWorld() then
        for _, keyframe in pairs(keyframes) do
            for name, _ in pairs(keyframe.Modifiers) do
                if Modifiers[name] then
                    if not FrameToKeyframe[keyframe.Frame] then
                        KeyframePointers[LocalIDs] = NewKeyframePointer(LocalIDs)
                        KeyframePointers[LocalIDs]:SetFrame(keyframe.Frame)
                        KeyframePointers[LocalIDs]:AddID(keyframe.ID, keyframe.Entity)
                        FrameToKeyframe[keyframe.Frame] = LocalIDs
                        KeyframeEasingData[LocalIDs] = {
                            EaseIn = keyframe.EaseIn[name],
                            EaseOut = keyframe.EaseOut[name],
                        }
                        KeyframeIDs[keyframe.ID] = LocalIDs
                        LocalIDs = LocalIDs + 1
                    else
                        local pointer = KeyframePointers[FrameToKeyframe[keyframe.Frame]]
                        pointer:AddID(keyframe.ID, keyframe.Entity)
                        KeyframeIDs[keyframe.ID] = FrameToKeyframe[keyframe.Frame]
                    end
                    break
                end
            end
        end

        if FrameToKeyframe[SMH.State.Frame] ~= nil then
            local data = KeyframeEasingData[FrameToKeyframe[SMH.State.Frame]]
            if data then
                WorldClicker.MainMenu:ShowEasingControls(data.EaseIn, data.EaseOut)
            else
                WorldClicker.MainMenu:ShowEasingControls(0, 0)
            end
        else
            WorldClicker.MainMenu:HideEasingControls()
        end

    else
        for _, keyframe in pairs(keyframes) do
            if not FrameToKeyframe[keyframe.Frame] then
                KeyframePointers[LocalIDs] = NewKeyframePointer(LocalIDs)
                KeyframePointers[LocalIDs]:SetFrame(keyframe.Frame)
                KeyframePointers[LocalIDs]:AddID(keyframe.ID, keyframe.Entity)
                FrameToKeyframe[keyframe.Frame] = LocalIDs
                KeyframeEasingData[LocalIDs] = {
                    EaseIn = keyframe.EaseIn["world"],
                    EaseOut = keyframe.EaseOut["world"],
                }
                KeyframeIDs[keyframe.ID] = LocalIDs
                LocalIDs = LocalIDs + 1
            else
                local pointer = KeyframePointers[FrameToKeyframe[keyframe.Frame]]
                pointer:AddID(keyframe.ID, keyframe.Entity)
                KeyframeIDs[keyframe.ID] = FrameToKeyframe[keyframe.Frame]
            end
        end
    end
end

---@param keyframe FrameData
function MGR.UpdateKeyframe(keyframe)
    if not KeyframeIDs[keyframe.ID] then
        if not FrameToKeyframe[keyframe.Frame] then
            KeyframePointers[LocalIDs] = NewKeyframePointer(LocalIDs)
            KeyframePointers[LocalIDs]:AddID(keyframe.ID, keyframe.Entity)
            KeyframeIDs[keyframe.ID] = LocalIDs
            LocalIDs = LocalIDs + 1
        else
            local pointer = KeyframePointers[FrameToKeyframe[keyframe.Frame]]
            pointer:AddID(keyframe.ID, keyframe.Entity)
            KeyframeIDs[keyframe.ID] = FrameToKeyframe[keyframe.Frame]
        end
        -- TODO should this logic exist? Where should it be?
        -- if FrameToKeyframe[keyframe.Frame] and KeyframePointers[FrameToKeyframe[keyframe.Frame]] then
        --     local pointer = KeyframePointers[FrameToKeyframe[keyframe.Frame]]
        --     KeyframePointers[FrameToKeyframe[keyframe.Frame]] = nil
        --     WorldClicker.MainMenu.FramePanel:DeleteFramePointer(pointer)
        -- end
    end
    local _, name = next(PropertiesMenu:GetCurrentModifiers())

    KeyframeEasingData[KeyframeIDs[keyframe.ID]] = {
        EaseIn = keyframe.EaseIn[name],
        EaseOut = keyframe.EaseOut[name],
    }

    KeyframePointers[KeyframeIDs[keyframe.ID]]:SetFrame(keyframe.Frame)

    for frame, kid in pairs(FrameToKeyframe) do
        if kid == KeyframeIDs[keyframe.ID] then
            FrameToKeyframe[frame] = nil
            break
        end
    end
    FrameToKeyframe[keyframe.Frame] = KeyframeIDs[keyframe.ID]
    if keyframe.Frame == SMH.State.Frame then
        WorldClicker.MainMenu:ShowEasingControls(keyframe.EaseIn[name], keyframe.EaseOut[name])
    end
end

---@param keyframeId integer
function MGR.DeleteKeyframe(keyframeId)
    if not KeyframeIDs[keyframeId] then return end

    KeyframePointers[KeyframeIDs[keyframeId]]:RemoveID(keyframeId)

    if not next(KeyframePointers[KeyframeIDs[keyframeId]]:GetIDs()) then
        if KeyframePointers[KeyframeIDs[keyframeId]] == LastSelectedKeyframe then LastSelectedKeyframe = nil end
        SelectedPointers[KeyframeIDs[keyframeId]] = nil
        WorldClicker.MainMenu.FramePanel:DeleteFramePointer(KeyframePointers[KeyframeIDs[keyframeId]])
        KeyframePointers[KeyframeIDs[keyframeId]] = nil
        KeyframeEasingData[KeyframeIDs[keyframeId]] = nil

        for frame, kid in pairs(FrameToKeyframe) do
            if kid == KeyframeIDs[keyframeId] then
                if frame == SMH.State.Frame then
                    WorldClicker.MainMenu:HideEasingControls()
                end
                FrameToKeyframe[frame] = nil
                break
            end
        end
    end

    KeyframeIDs[keyframeId] = nil
end

function MGR.SetOffsets(pointer)
    local minimum, maximum = 0, 0
    for id, kpointer in pairs(KeyframePointers) do
        if SelectedPointers[id] then
            local difference = kpointer:GetFrame() - pointer:GetFrame()
            if minimum > difference then
                minimum = difference
            elseif maximum < difference then
                maximum = difference
            end
        end
    end
    pointer:SetOffsets(minimum, maximum)
end

---@param pointer any
---@param frame integer
function MGR.MoveChildren(pointer, frame)
    if next(OffsetPointers) then
        for _, kpointer in ipairs(OffsetPointers) do
            local difference = kpointer:GetFrame() - pointer:GetFrame()
            kpointer:SetFrame(frame + difference)
        end
    else
        for id, kpointer in pairs(KeyframePointers) do
            if kpointer:GetParentKeyframe() == pointer then -- obsolete but i'm keeping this in here for future
                kpointer:SetFrame(frame)
            end
            if kpointer == pointer then continue end
            if SelectedPointers[id] then
                local difference = kpointer:GetFrame() - pointer:GetFrame()
                kpointer:SetFrame(frame + difference)
            end
        end
    end
end

function MGR.ClearFrames(pointer) -- i don't think i need this
    for id, kpointer in pairs(KeyframePointers) do
        if kpointer:GetParentKeyframe() == pointer then
            kpointer:OnPointerReleased(kpointer:GetFrame())
            kpointer:ClearParentPointer()
        end
        if kpointer == pointer then continue end
        if SelectedPointers[id] then
            kpointer:OnPointerReleased(kpointer:GetFrame())
        end
    end
end

function MGR.ClearAllSelected()
    for id, pointer in pairs(SelectedPointers) do
        pointer:SetSelected(false)
    end
    LastSelectedKeyframe = nil
    SelectedPointers = {}
end

---@param pointer SMHFramePointer
function MGR.ShiftSelect(pointer)
    if not LastSelectedKeyframe then 
        MGR.ToggleSelect(pointer) 
        return
    end

    local minimum, maximum = 0, 0
    if pointer:GetFrame() > LastSelectedKeyframe:GetFrame() then
        minimum, maximum = LastSelectedKeyframe:GetFrame(), pointer:GetFrame()
    else
        minimum, maximum = pointer:GetFrame(), LastSelectedKeyframe:GetFrame()
    end

    for id, kpointer in pairs(KeyframePointers) do
        if kpointer:GetFrame() >= minimum and kpointer:GetFrame() <= maximum then
            SelectedPointers[id] = kpointer
            kpointer:SetSelected(true)
        end
    end

    LastSelectedKeyframe = pointer
end

function MGR.SelectAll()
    for id, kpointer in pairs(KeyframePointers) do
        kpointer:SetSelected(not kpointer:GetSelected())
        SelectedPointers[id] = kpointer:GetSelected() and kpointer or nil
    end
end

---@param pointer SMHFramePointer
function MGR.ToggleSelect(pointer)
    local selected = not pointer:GetSelected()
    local frame = pointer:GetFrame()
    for id, kpointer in pairs(KeyframePointers) do
        if kpointer ~= pointer then continue end
        if selected then
            LastSelectedKeyframe = kpointer
            for id, kpointer in pairs(KeyframePointers) do
                if kpointer:GetFrame() == frame then
                    SelectedPointers[id] = kpointer
                    kpointer:SetSelected(selected)
                end
            end
        else
            if kpointer == LastSelectedKeyframe then LastSelectedKeyframe = nil end
            for id, kpointer in pairs(KeyframePointers) do
                if kpointer:GetFrame() == frame then
                    SelectedPointers[id] = nil
                    kpointer:SetSelected(selected)
                end
            end
        end
        break
    end
    for id, kpointer in pairs(KeyframePointers) do
        if kpointer == pointer then continue end
        if kpointer == LastSelectedKeyframe then LastSelectedKeyframe = nil end
    end
end

function MGR.GetSelected()
    return SelectedPointers
end

---@param entities Entities
function MGR.SetSelectedEntity(entities)
    local entity = next(entities)
    LoadMenu:UpdateSelectedEnt(entity)
    PropertiesMenu:UpdateSelectedEnt(entity)
    WorldClicker.PhysRecorder:UpdateSelectedEnt(entity)
    ClickerEntity = entities
end

---@param folders string[]
---@param saves string[]
---@param path string
function MGR.SetServerSaves(folders, saves, path)
    LoadMenu:SetSaves(folders, saves, path)
    SaveMenu:SetSaves(folders, saves, path)
end

---@param models string[]
---@param map string?
function MGR.SetModelList(models, map)
    LoadMenu:SetEntities(models, map)
    WorldClicker.SpawnMenu:SetEntities(models)
end

---@param entities Entities
function MGR.SetEntityList(entities)
    PropertiesMenu:SetEntities(entities)
end

---@param name string
---@param class string
function MGR.SetModelName(name, class)
    LoadMenu:SetModelName(name, class)
end

---@param name string
function MGR.UpdateName(name)
    PropertiesMenu:SetName(name)
end

---@param names string[]
function MGR.SaveExistsWarning(names)
    SaveMenu:SaveExists(names)
end

---@param savenames string[]
---@param gamenames string[]
function MGR.AppendWindow(savenames, gamenames)
    SaveMenu:AppendWindow(savenames, gamenames)
end

---@param path string
function MGR.AddSaveFile(path)
    SaveMenu:AddSave(path)
end

---@param path string
---@param isFolder boolean
function MGR.RemoveSaveFile(path, isFolder)
    SaveMenu:RemoveSave(path, isFolder)
end

---@param list any
function MGR.InitModifiers(list)
    PropertiesMenu:InitModifiers(list)
end

function MGR.RefreshTimelineSettings()
    PropertiesMenu:UpdateTimelineSettings()
end

---@param setting string
---@param value any
function MGR.UpdateUISetting(setting, value)
    local settings = {}
    settings[setting] = value
    WorldClicker.Settings:ApplySettings(settings)
end

---@param timeline TimelineSetting
function MGR.SetTimeline(timeline)
    WorldClicker.MainMenu:UpdateTimelines(timeline)
    PropertiesMenu:UpdateTimelineInfo(timeline)
    if next(SMH.State.Entity) then
        SMH.Controller.UpdateTimeline()
    end
end

---modified for loading playback length and rate from audio sequence save
---@param newState State
---@param updatePlaybackControls boolean?
function MGR.UpdateState(newState, updatePlaybackControls)
	local updatePlaybackControls = updatePlaybackControls or false
	
    WorldClicker.MainMenu:UpdatePositionLabel(newState.Frame, newState.PlaybackLength)
    WorldClicker.MainMenu.FramePanel:UpdateFrameCount(newState.PlaybackLength)
	
	if updatePlaybackControls then
		WorldClicker.MainMenu:SetInitialState(newState)
	end
end

---@param timelineinfo TimelineSetting
---@param changed string
function MGR.UpdateModifier(timelineinfo, changed)
    PropertiesMenu:UpdateModifiersInfo(timelineinfo, changed)
end

---@param timelineinfo TimelineSetting
function MGR.UpdateKeyColor(timelineinfo)
    PropertiesMenu:UpdateColor(timelineinfo)
end

---@param color Color
function MGR.PaintKeyframes(color)
    KeyColor = color

    for _, pointer in pairs(KeyframePointers) do
        pointer.Color = KeyColor
    end
end

function MGR.GetModifiers()
    return PropertiesMenu:GetModifiers()
end

---@param set any
function MGR.SetUsingWorld(set)
    PropertiesMenu:SetUsingWorld(set)
    if set then
        WorldClicker.MainMenu:HideEasingControls()
    else
        PropertiesMenu:HideWorldSettings()
    end
end

---@param console string
---@param push string
---@param release string
function MGR.SetWorldData(console, push, release)
    PropertiesMenu:ShowWorldSettings(console, push, release)
end

---@param frame integer
---@return table?
function MGR.GetKeyframesOnFrame(frame)
	if not FrameToKeyframe[frame] then return nil end
	local ids = {}

	for id, mod in pairs(KeyframePointers[FrameToKeyframe[frame]]:GetIDs()) do
		table.insert(ids, id)
	end

	return ids
end

-- AUDIO =========================================
function MGR.CreateAudioClipPointer(audioClip)
	table.insert(AudioClipPointers, NewAudioClipPointer(audioClip))
end

function MGR.DeleteAudioClipPointer(pointer)
	WorldClicker.MainMenu.FramePanel:DeleteAudioClipPointer(pointer)
end

function MGR.DeleteAllAudioClipPointers()
	WorldClicker.MainMenu.FramePanel:DeleteAllAudioClipPointers()
end
-- ===============================================

SMH.UI = MGR
