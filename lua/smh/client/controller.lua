local INT_BITCOUNT = 32
local KFRAMES_PER_MSG = 250

local function ReceiveKeyframes()
    local framecount = net.ReadUInt(INT_BITCOUNT)
    for i = 1, framecount do
        local ID, entity, Frame, ModCount = net.ReadUInt(INT_BITCOUNT), net.ReadEntity(), net.ReadUInt(INT_BITCOUNT), net.ReadUInt(INT_BITCOUNT)
        ---@cast entity SMHEntity
        local Modifiers, In, Out = {}, {}, {}
        for j = 1, ModCount do
            local name = net.ReadString()
            Modifiers[name] = true
            In[name] = net.ReadFloat()
            Out[name] = net.ReadFloat()
        end
        SMH.TableSplit.AKeyframes(ID, entity, Frame, In, Out, Modifiers)
    end
    return SMH.TableSplit.GetKeyframes()
end

---@param Timelines integer
---@param KeyColor Color[]
---@param ModCount integer[]
---@param Modifiers table
local function SendProperties(Timelines, KeyColor, ModCount, Modifiers)
    net.WriteUInt(Timelines, INT_BITCOUNT)
    for i=1, Timelines do
        net.WriteColor(KeyColor[i])
        net.WriteUInt(ModCount[i], INT_BITCOUNT)
        for j=1, ModCount[i] do
            net.WriteString(Modifiers[i][j])
        end
    end
end

local function ReceiveProperties()
    local Timelines = SMH.TableSplit.StartAProperties(net.ReadUInt(INT_BITCOUNT))
    for i=1, Timelines do
        SMH.TableSplit.AProperties(i, nil, net.ReadColor())
        for j=1, net.ReadUInt(INT_BITCOUNT) do
            SMH.TableSplit.AProperties(i, net.ReadString())
        end
    end
    return SMH.TableSplit.GetProperties()
end

local function RequestNodes()
    net.Start(SMH.MessageTypes.RequestNodes)
    net.SendToServer()
end

---Source: https://github.com/NO-LOAFING/AnimpropOverhaul/blob/a3a6268a5d57655611a8b8ed43dcf43051ecd93a/lua/entities/prop_animated.lua#L3550
---@param ent Entity Entity in reference pose
---@return table defaultPose Array consisting of a bones offsets from the entity, and offsets from its parent bones
function GetDefaultPoseTree(ent)
	local defaultPose = {}
	local entPos = ent:GetPos()
	local entAngles = ent:GetAngles()
	for b = 0, ent:GetBoneCount() - 1 do
		local parent = ent:GetBoneParent(b)
        local isPhysBone = b == ent:TranslatePhysBoneToBone(ent:TranslateBoneToPhysBone(b))
		local bMatrix = ent:GetBoneMatrix(b)
		if bMatrix then
			local pos1, ang1 = WorldToLocal(bMatrix:GetTranslation(), bMatrix:GetAngles(), entPos, entAngles)
			local pos2, ang2 = pos1 * 1, ang1 * 1
			if parent > -1 then
				local pMatrix = ent:GetBoneMatrix(parent)
				pos2, ang2 = WorldToLocal(
					bMatrix:GetTranslation(),
					bMatrix:GetAngles(),
					pMatrix:GetTranslation(),
					pMatrix:GetAngles()
				)
			end

			defaultPose[b + 1] = { pos1, ang1, pos2, ang2, parent, isPhysBone }
		else
			defaultPose[b + 1] = { vector_origin, angle_zero, vector_origin, angle_zero, -1, false }
		end
	end

	return defaultPose
end

local function RequestDefaultPose()
    local entity = net.ReadEntity()
    ---@cast entity SMHEntity

    if entity:GetClass() == "prop_effect" and IsValid(entity.AttachedEntity) then
        entity = entity.AttachedEntity
    end

    local csModel = ClientsideModel(entity:GetModel())
    csModel:DrawModel()
	csModel:SetupBones()
	csModel:InvalidateBoneCache()
    local tree = GetDefaultPoseTree(csModel)
    csModel:Remove()

    net.Start(SMH.MessageTypes.RequestDefaultPoseResponse)
    net.WriteString(entity:GetModel())
    net.WriteUInt(#tree, 8)
    for i = 1, #tree do
        net.WriteVector(tree[i][1])
        net.WriteAngle(tree[i][2])
        net.WriteVector(tree[i][3])
        net.WriteAngle(tree[i][4])
        net.WriteInt(tree[i][5], 9)
        net.WriteBool(tree[i][6])
    end
    net.SendToServer()
end

local CTRL = {}

---@param frame integer
function CTRL.SetFrame(frame)
    if SMH.PhysRecord.IsActive() then return end

    local settings = SMH.Settings.GetAll()
    net.Start(SMH.MessageTypes.SetFrame)
    net.WriteUInt(frame, INT_BITCOUNT)
    net.WriteTable(settings)
    net.WriteUInt(SMH.State.Timeline, INT_BITCOUNT)
    net.SendToServer()

    RequestNodes()
end

---@param entity SMHEntity|Player
---@param enttable Set<Entity>
function CTRL.SelectEntity(entity, enttable)
    if SMH.PhysRecord.IsActive() then return end
    local count = 0

    for ent, _ in pairs(enttable) do
        count = count + 1
    end

    net.Start(SMH.MessageTypes.SelectEntity)
    net.WriteEntity(entity)
    net.WriteUInt(count, INT_BITCOUNT)
    for tentity, _ in pairs(enttable) do
        net.WriteEntity(tentity)
    end
    net.SendToServer()
end

-- AUDIO =========================
function CTRL.AddAudio(path)
	local frame = SMH.State.Frame

	print(path, frame)
	
	local audioclips = SMH.AudioClipManager.Create(path, frame)
end

function CTRL.DeleteAudio(id, pointer)
	SMH.AudioClipData:Delete(id)
	if pointer ~= nil then
		SMH.UI.DeleteAudioClipPointer(pointer)
	end
	CTRL.UpdateServerAudio()
end

function CTRL.DeleteAllAudio()
	SMH.AudioClipData:DeleteAll()
	SMH.UI.DeleteAllAudioClipPointers()
	CTRL.UpdateServerAudio()
end

function CTRL.UpdateServerAudio()
	local audioTable = {}
	for i,clip in pairs(SMH.AudioClipData.AudioClips) do
		if audioTable[clip.Frame] == nil then
			audioTable[clip.Frame] = {}
		end
		table.insert(audioTable[clip.Frame], {
			ID = clip.ID,
			Duration = clip.Duration
		})
	end
	
	net.Start(SMH.MessageTypes.UpdateServerAudio)
	net.WriteTable(audioTable)
	net.SendToServer()
end
-- ===============================

---@param frame integer?
function CTRL.Record(frame)
    if not next(SMH.State.Entity) or SMH.State.Frame < 0 or SMH.State.Timeline < 1 or SMH.PhysRecord.IsActive() or (frame and frame < 0) then
        return
    end
    SMH.State.TimeStamp = RealTime()
    local count = 0

    for ent, _ in pairs(SMH.State.Entity) do
        count = count + 1
    end

    net.Start(SMH.MessageTypes.CreateKeyframe)
    net.WriteUInt(count, INT_BITCOUNT)
    for entity, _ in pairs(SMH.State.Entity) do
        net.WriteEntity(entity)
    end
    net.WriteUInt(frame or SMH.State.Frame, INT_BITCOUNT)
    net.WriteUInt(SMH.State.Timeline, INT_BITCOUNT)
    net.SendToServer()
end

---@param frames integer[]
---@param maxPasses integer
function CTRL.Smooth(frames, maxPasses)
    local done = false
    local co = coroutine.wrap(function()
        for p = 1, maxPasses do
            local smoothingFrames = {}

            for i, keyframe in ipairs(frames) do
                if keyframe >= 0 and not smoothingFrames[keyframe] and SMH.UI.IsFrameKeyframe(keyframe) then
                    SMH.Controller.SetFrame(keyframe-1)
                    coroutine.wait(0)
                    SMH.Controller.Record(keyframe-1)
                    coroutine.wait(0)
                    SMH.Controller.SetFrame(keyframe+1)
                    coroutine.wait(0)
                    SMH.Controller.Record(keyframe+1)
                    coroutine.wait(0)

                    local exists = SMH.UI.GetKeyframesOnFrame(keyframe)
                    if not exists then continue end
                    SMH.Controller.DeleteKeyframe(exists)
                    smoothingFrames[keyframe-1] = keyframe-1
                    smoothingFrames[keyframe+1] = keyframe+1

                    table.insert(frames, keyframe-1)
                    table.insert(frames, keyframe+1)
                    table.remove(frames, i)
                end
                table.sort(frames)
            end

            coroutine.yield()
        end
        done = true
    end)
    timer.Remove("SMH_Smoothing_Timer")
    timer.Create("SMH_Smoothing_Timer", 0, -1, function()
        if done then
            chat.AddText("SMH Smoothing stopped.")
            timer.Remove("SMH_Smoothing_Timer")
        else
            co()
        end
    end)

    timer.Start("SMH_Smoothing_Timer")
end

---@param keyframeId integer[]
---@param updateData any
---@param singledata any
function CTRL.UpdateKeyframe(keyframeId, updateData, singledata)
    local keyframeAmount = #keyframeId

    for i = 1, math.ceil(keyframeAmount / KFRAMES_PER_MSG) do
        local keyframesToSend = keyframeAmount - KFRAMES_PER_MSG * (i - 1) > KFRAMES_PER_MSG and KFRAMES_PER_MSG or keyframeAmount - KFRAMES_PER_MSG * (i - 1)

        net.Start(SMH.MessageTypes.UpdateKeyframe)
        net.WriteUInt(keyframesToSend, INT_BITCOUNT)

        for ids = 1 + KFRAMES_PER_MSG * (i - 1), keyframesToSend + KFRAMES_PER_MSG * (i - 1) do
            net.WriteUInt(keyframeId[ids], INT_BITCOUNT)

            if singledata then
                for data, value in pairs(updateData) do
                    net.WriteString(data)
                    if data == "Frame" then
                        net.WriteUInt(value, INT_BITCOUNT)
                    else
                        net.WriteFloat(value)
                    end
                end
            else
                for data, value in pairs(updateData[ids]) do
                    net.WriteString(data)
                    if data == "Frame" then
                        net.WriteUInt(value, INT_BITCOUNT)
                    else
                        net.WriteFloat(value)
                    end
                end
            end
        end
        net.WriteUInt(SMH.State.Timeline, INT_BITCOUNT)
        net.SendToServer()
    end

    net.Start(SMH.MessageTypes.UpdateKeyframeExecute)
    net.SendToServer()
end

---@param keyframeId integer[]
---@param frame table
function CTRL.CopyKeyframe(keyframeId, frame)
    local keyframeAmount = #keyframeId

    for i = 1, math.ceil(keyframeAmount / KFRAMES_PER_MSG) do
        local keyframesToSend = keyframeAmount - KFRAMES_PER_MSG * (i - 1) > KFRAMES_PER_MSG and KFRAMES_PER_MSG or keyframeAmount - KFRAMES_PER_MSG * (i - 1)

        net.Start(SMH.MessageTypes.CopyKeyframe)
        net.WriteUInt(keyframesToSend, INT_BITCOUNT)

        for ids = 1 + KFRAMES_PER_MSG * (i - 1), keyframesToSend + KFRAMES_PER_MSG * (i - 1) do
            net.WriteUInt(keyframeId[ids], INT_BITCOUNT)
            net.WriteUInt(frame[ids], INT_BITCOUNT)
        end
        net.WriteUInt(SMH.State.Timeline, INT_BITCOUNT)
        net.SendToServer()
    end

    net.Start(SMH.MessageTypes.CopyKeyframeExecute)
    net.SendToServer()
end

---@param keyframeId integer[]
function CTRL.DeleteKeyframe(keyframeId)
    local keyframeAmount = #keyframeId

    for i = 1, math.ceil(keyframeAmount / KFRAMES_PER_MSG) do
        local keyframesToSend = keyframeAmount - KFRAMES_PER_MSG * (i - 1) > KFRAMES_PER_MSG and KFRAMES_PER_MSG or keyframeAmount - KFRAMES_PER_MSG * (i - 1)

        net.Start(SMH.MessageTypes.DeleteKeyframe)
        net.WriteUInt(keyframesToSend, INT_BITCOUNT)
        net.WriteUInt(SMH.State.Timeline, INT_BITCOUNT)

        for ids = 1 + KFRAMES_PER_MSG * (i - 1), keyframesToSend + KFRAMES_PER_MSG * (i - 1) do
            net.WriteUInt(keyframeId[ids], INT_BITCOUNT)
        end

        net.SendToServer()
    end
end

---@param startFrame integer
function CTRL.StartPlayback(startFrame)
    if SMH.PhysRecord.IsActive() then return end

    net.Start(SMH.MessageTypes.StartPlayback)
    net.WriteUInt(startFrame, INT_BITCOUNT)
    net.WriteUInt(SMH.State.PlaybackLength - 1, INT_BITCOUNT)
    net.WriteUInt(SMH.State.PlaybackRate, INT_BITCOUNT)
    net.WriteTable(SMH.Settings.GetAll())
    net.SendToServer()
	
	-- AUDIO =========================
	//check for any clips that are partway through and play them from that point
	for i,clip in pairs(SMH.AudioClipData.AudioClips) do
		//calculate end frame
		local endFrame = math.ceil(SMH.State.Frame + SMH.State.PlaybackRate * clip.Duration)
		if SMH.State.Frame > clip.Frame and SMH.State.Frame < endFrame then
			//calculate start point
			local startTime = ((SMH.State.Frame-clip.Frame-0.5)/SMH.State.PlaybackRate)+clip.StartTime
			SMH.AudioClip.Play(clip.ID, startTime)
		end
	end
	-- AUDIO =========================
end

function CTRL.StopPlayback()
    net.Start(SMH.MessageTypes.StopPlayback)
    net.SendToServer()
	
	-- AUDIO
	SMH.AudioClip.StopAll()
end

function CTRL.GetServerSaves()
    net.Start(SMH.MessageTypes.GetServerSaves)
    net.SendToServer()
end

---@param path string
---@param loadFromClient boolean?
function CTRL.GetModelList(path, loadFromClient)
    if loadFromClient then
        local models = SMH.Saves.ListModels(path, LocalPlayer())
        SMH.UI.SetModelList(models)
    else
        net.Start(SMH.MessageTypes.GetModelList)
        net.WriteString(path)
        net.SendToServer()
    end
end

function CTRL.GetServerEntities()
    net.Start(SMH.MessageTypes.GetServerEntities)
    net.SendToServer()
end

---@param path string
---@param modelName string
---@param loadFromClient boolean
function CTRL.Load(path, modelName, loadFromClient)
    if not next(SMH.State.Entity) then
        return
    end
    local entity = next(SMH.State.Entity)

    net.Start(SMH.MessageTypes.Load)

    net.WriteEntity(entity)
    net.WriteBool(loadFromClient)

    if loadFromClient then
        local serializedKeyframes = SMH.Saves.LoadForEntity(path, modelName, LocalPlayer())
        ---@cast serializedKeyframes SMHFile
        net.WriteTable(serializedKeyframes)
    else
        net.WriteString(path)
        net.WriteString(modelName)
    end

    net.SendToServer()
end

---@param path string
---@param modelName string
---@param loadFromClient boolean
function CTRL.GetModelInfo(path, modelName, loadFromClient)
    net.Start(SMH.MessageTypes.GetModelInfo)
    net.WriteString(path)
    net.WriteString(modelName)
    net.SendToServer()
end

---@param path string
---@param saveToClient boolean
---@param isFolder boolean
function CTRL.RequestSave(path, saveToClient, isFolder)
    net.Start(SMH.MessageTypes.RequestSave)
    net.WriteBool(saveToClient)
    net.WriteBool(isFolder)
    net.WriteString(path)
    net.SendToServer()
end

---@param path string
---@param isAutoSave boolean?
function CTRL.Save(path, isAutoSave)
    net.Start(SMH.MessageTypes.Save)
    net.WriteString(path)
    net.WriteBool(isAutoSave ~= nil and true or false)
    net.SendToServer()
end

---@param path string
---@param toClient boolean
function CTRL.RequestGoToFolder(path, toClient)
    net.Start(SMH.MessageTypes.RequestGoToFolder)
    net.WriteBool(toClient)
    net.WriteString(path)
    net.SendToServer()
end

---@param path string
function CTRL.RequestAppend(path)
    net.Start(SMH.MessageTypes.RequestAppend)
    net.WriteString(path)
    net.SendToServer()
end

---@param path string
---@param savenames string[]
---@param gamenames string[]
function CTRL.Append(path, savenames, gamenames)
    net.Start(SMH.MessageTypes.Append)
    local count = #savenames

    net.WriteString(path)
    net.WriteUInt(count, INT_BITCOUNT)
    for _, name in ipairs(savenames) do
        net.WriteString(name)
    end

    count = #gamenames
    net.WriteUInt(count, INT_BITCOUNT)
    for _, name in ipairs(gamenames) do
        net.WriteString(name)
    end
    net.SendToServer()
end

function CTRL.QuickSave()
    local nick = LocalPlayer():Nick()
    local qs1 = "quicksave_" .. nick
    local qs2 = "quicksave_" .. nick .. "_backup"

    SMH.Saves.CopyIfExists(qs1, qs2, LocalPlayer())
    CTRL.Save(qs1)
end

function CTRL.RequestPack()
    net.Start(SMH.MessageTypes.RequestPack)
    net.SendToServer()
end

---@param path string
---@param isFolder boolean
---@param deleteFromClient boolean
function CTRL.DeleteSave(path, isFolder, deleteFromClient)
    if deleteFromClient then
        SMH.Saves.Delete(path, LocalPlayer())
    else
        net.Start(SMH.MessageTypes.DeleteSave)
        net.WriteBool(isFolder)
        net.WriteString(path)
        net.SendToServer()
    end
end

-- AUDIO SAVES ====================================================
function CTRL.SaveAudioSeq(path)
	//all clientside
	local keyframes = SMH.AudioClipData.AudioClips
	local serializedClips = SMH.AudioSeqSaves.Serialize(keyframes)
	SMH.AudioSeqSaves.Save(path, serializedClips)
end

function CTRL.DeleteAudioSeq(path)
	SMH.AudioSeqSaves.Delete(path)
end

function CTRL.LoadAudioSeq(path, setFrameRate)
	local setFrameRate = setFrameRate or false
	
	// Clear audio clips
	CTRL.DeleteAllAudio()
	
	// Create new clips
	local loadFile = SMH.AudioSeqSaves.Load(path)
	local audioClipLoad = loadFile.Clips
	for k,v in pairs(audioClipLoad) do
		if v.Path and v.Frame and v.StartTime and v.Duration then
			SMH.AudioClipManager.Create(v.Path, v.Frame, v.StartTime, v.Duration)
		else
			print("SMH Audio: Sequence file contains errors!")
		end
	end
	
	//Set frame rate if required
	if setFrameRate then
		local newState = {
			Frame = SMH.State.Frame,
			PlaybackRate = loadFile.PlaybackRate,
			PlaybackLength = loadFile.PlaybackLength
		}
		CTRL.UpdateState(newState, true)
	end
end
-- ================================================================

function CTRL.ShouldHighlight()
    return SMH.UI.IsOpen()
end

---@param useScreenshot boolean
---@param StartFrame integer
function CTRL.ToggleRendering(useScreenshot, StartFrame)
    if SMH.PhysRecord.IsActive() then return end

    if SMH.Renderer.IsRendering() then
        SMH.Renderer.Stop()
    else
        SMH.Renderer.Start(useScreenshot, StartFrame)
    end
end

function CTRL.OpenMenu()
    SMH.UI.Open()
end

function CTRL.CloseMenu()
    SMH.UI.Close()
end

---@param newState NewState
---@param updatePlaybackControls any
function CTRL.UpdateState(newState, updatePlaybackControls)
	local updatePlaybackControls = updatePlaybackControls or false
	
    local allowedKeys = {
        Frame = true,
        Timeline = true,
        PlaybackRate = true,
        PlaybackLength = true,
    }

    for k, v in pairs(newState) do
        if not allowedKeys[k] then
            error("Key not allowed: " .. k)
        end
        SMH.State[k] = v
    end

    SMH.UI.UpdateState(SMH.State, updatePlaybackControls)
end

---@param newSettings any
function CTRL.UpdateSettings(newSettings)
    SMH.Settings.Update(newSettings)
end

function CTRL.UpdateUISetting(setting, value)
    SMH.UI.UpdateUISetting(setting, value)
end

function CTRL.OpenHelp()
    gui.OpenURL("https://github.com/Winded/StopMotionHelper/blob/master/TUTORIAL.md")
end

---@param rendering boolean
function CTRL.SetRendering(rendering)
    net.Start(SMH.MessageTypes.SetRendering)
    net.WriteBool(rendering)
    net.SendToServer()
end

function CTRL.UpdateGhostState()
    net.Start(SMH.MessageTypes.UpdateGhostState)
    net.WriteTable(SMH.Settings.GetAll())
    net.SendToServer()
end

---@param ent Entity
---@param name string
function CTRL.ApplyEntityName(ent, name)
    net.Start(SMH.MessageTypes.ApplyEntityName)
    net.WriteEntity(ent)
    net.WriteString(name)
    net.SendToServer()
end

function CTRL.UpdateTimeline()
    local count = 0

    for ent, _ in pairs(SMH.State.Entity) do
        count = count + 1
    end

    net.Start(SMH.MessageTypes.UpdateTimeline)
    net.WriteUInt(count, INT_BITCOUNT)
    for entity, _ in pairs(SMH.State.Entity) do
        net.WriteEntity(entity)
    end
    net.SendToServer()
end

function CTRL.RequestModifiers()
    net.Start(SMH.MessageTypes.RequestModifiers)
    net.SendToServer()
end

function CTRL.AddTimeline()
    net.Start(SMH.MessageTypes.AddTimeline)
    net.SendToServer()
end

function CTRL.RemoveTimeline()
    net.Start(SMH.MessageTypes.RemoveTimeline)
    net.SendToServer()
end

---@param i integer
---@param mod string
---@param check boolean
function CTRL.UpdateModifier(i, mod, check)
    net.Start(SMH.MessageTypes.UpdateModifier)
    net.WriteUInt(i, INT_BITCOUNT)
    net.WriteString(mod)
    net.WriteBool(check)
    net.SendToServer()
end

---@param color Color
---@param timeline integer
function CTRL.UpdateKeyframeColor(color, timeline)
    net.Start(SMH.MessageTypes.UpdateKeyframeColor)
    net.WriteUInt(timeline, INT_BITCOUNT)
    net.WriteColor(color)
    net.SendToServer()
end

---@param path string
---@param model string
---@param loadFromClient boolean
function CTRL.SetPreviewEntity(path, model, loadFromClient)
    net.Start(SMH.MessageTypes.SetPreviewEntity)
    net.WriteString(path)
    net.WriteString(model)
    net.WriteTable(SMH.Settings.GetAll())
    net.SendToServer()
end

---@param state boolean
function CTRL.SetSpawnGhost(state)
    net.Start(SMH.MessageTypes.SetSpawnGhost)
    net.WriteBool(state)
    net.SendToServer()
end

---@param path string
---@param model string
---@param loadFromClient boolean
function CTRL.SpawnEntity(path, model, loadFromClient)
    if SMH.PhysRecord.IsActive() then return end

    net.Start(SMH.MessageTypes.SpawnEntity)
    net.WriteString(path)
    net.WriteString(model)
    net.WriteTable(SMH.Settings.GetAll())
    net.SendToServer()
end

function CTRL.SpawnReset()
    net.Start(SMH.MessageTypes.SpawnReset)
    net.SendToServer()
end

---@param set boolean
function CTRL.SetSpawnOffsetMode(set)
    net.Start(SMH.MessageTypes.SetSpawnOffsetMode)
    net.WriteBool(set)
    net.SendToServer()
end

---@param path string
---@param model string
---@param loadFromClient boolean
function CTRL.SetSpawnOrigin(path, model, loadFromClient)
    net.Start(SMH.MessageTypes.SetSpawnOrigin)
    net.WriteString(path)
    net.WriteString(model)
    net.SendToServer()
end

---@param Pos Vector
function CTRL.OffsetPos(Pos)
    net.Start(SMH.MessageTypes.OffsetPos)
    net.WriteVector(Pos)
    net.SendToServer()
end

---@param Ang Angle
function CTRL.OffsetAng(Ang)
    net.Start(SMH.MessageTypes.OffsetAng)
    net.WriteAngle(Ang)
    net.SendToServer()
end

---@param settings Properties
---@param presetname string
function CTRL.SetTimeline(settings, presetname)
    net.Start(SMH.MessageTypes.SetTimeline)
    net.WriteBool(presetname == "default")
    if not (presetname == "default") then
        local Timelines, KeyColor, ModCount, Modifiers = SMH.TableSplit.DProperties(settings)
        ---@cast Timelines integer
        ---@cast KeyColor Color
        ---@cast ModCount integer[]
        ---@cast Modifiers table
        SendProperties(Timelines, KeyColor, ModCount, Modifiers)
    end
    net.SendToServer()
end

---@param name string
function CTRL.RequestTimelineInfo(name)
    net.Start(SMH.MessageTypes.RequestTimelineInfo)
    net.WriteString(name)
    net.SendToServer()
end

---@param frame integer
function CTRL.RequestWorldData(frame)
    net.Start(SMH.MessageTypes.RequestWorldData)
    net.WriteUInt(frame, INT_BITCOUNT)
    net.SendToServer()
end

---@param str string
---@param key string
function CTRL.UpdateWorld(str, key)
    net.Start(SMH.MessageTypes.UpdateWorld)
    net.WriteString(str)
    net.WriteString(key)
    net.WriteUInt(SMH.State.Frame, INT_BITCOUNT)
    net.SendToServer()
end

---@param framecount integer
---@param interval integer
---@param entities table<Entity, integer>
function CTRL.StartPhysicsRecord(framecount, interval, entities)
    if not next(entities) or SMH.State.Frame < 0 or SMH.State.Timeline < 1 then
        return
    end

    net.Start(SMH.MessageTypes.StartPhysicsRecord)
    net.WriteUInt(framecount, INT_BITCOUNT)
    net.WriteUInt(interval, INT_BITCOUNT)
    net.WriteUInt(SMH.State.Frame, INT_BITCOUNT)
    net.WriteUInt(SMH.State.PlaybackRate, INT_BITCOUNT)
    net.WriteUInt(SMH.State.PlaybackLength, INT_BITCOUNT)
    net.WriteUInt(table.Count(entities), INT_BITCOUNT)
    for entity, timeline in pairs(entities) do
        net.WriteEntity(entity)
        net.WriteUInt(timeline, INT_BITCOUNT)
    end
    net.WriteTable(SMH.Settings.GetAll())
    net.SendToServer()
end

function CTRL.StopPhysicsRecord()
    net.Start(SMH.MessageTypes.StopPhysicsRecord)
    net.SendToServer()
end

SMH.Controller = CTRL

---@type Receiver
local function SetFrameResponse(msgLength)
    local frame = net.ReadUInt(INT_BITCOUNT)
    SMH.State.Frame = frame
    SMH.State.TimeStamp = RealTime()
    SMH.UI.SetFrame(frame)
end

---@type Receiver
local function SelectEntityResponse(msgLength)
    local keyframes = ReceiveKeyframes()
    local entities = {}
    for i = 1, net.ReadUInt(INT_BITCOUNT) do
        entities[net.ReadEntity()] = true
    end

    local entity = next(entities)

    SMH.State.Entity = entities
    SMH.State.TimeStamp = RealTime()
    SMH.UI.SetSelectedEntity(entities)
    SMH.UI.SetUsingWorld(entity == LocalPlayer())
    SMH.UI.SetKeyframes(keyframes)
end

---@type Receiver
local function UpdateKeyframeResponse(msgLength)
    local keyframes = ReceiveKeyframes()

    for num, keyframe in ipairs(keyframes) do
        if SMH.State.Entity[keyframe.Entity] then
            SMH.UI.UpdateKeyframe(keyframe)
        end
    end
end

---@type Receiver
local function DeleteKeyframeResponse(msgLength)
    local keyframeId = net.ReadUInt(INT_BITCOUNT)
    SMH.UI.DeleteKeyframe(keyframeId)
end

---@type Receiver
local function GetAllKeyframes(msgLength)
    local keyframes = ReceiveKeyframes()

    SMH.UI.SetKeyframes(keyframes, true)
end

---@type Receiver
local function GetServerSavesResponse(msgLength)
    for i=1, net.ReadUInt(INT_BITCOUNT) do
        SMH.TableSplit.ATable(i, net.ReadString())
    end
    local folders = SMH.TableSplit.GetTable()

    for i=1, net.ReadUInt(INT_BITCOUNT) do
        SMH.TableSplit.ATable(i, net.ReadString())
    end
    local saves = SMH.TableSplit.GetTable()
    local path = net.ReadString()

    SMH.UI.SetServerSaves(folders, saves, path)
end

---@type Receiver
local function GetModelListResponse(msgLength)
    for i=1, net.ReadUInt(INT_BITCOUNT) do
        SMH.TableSplit.ATable(i, net.ReadString())
    end
    local models = SMH.TableSplit.GetTable()
    local map = net.ReadString()
    SMH.UI.SetModelList(models, map)
end

---@type Receiver
local function GetServerEntitiesResponse(msgLength)
    for i=1, net.ReadUInt(INT_BITCOUNT) do
        SMH.TableSplit.ATable(net.ReadEntity(), {Name = net.ReadString()})
    end
    local entities = SMH.TableSplit.GetTable()
    SMH.UI.SetEntityList(entities)
end

---@type Receiver
local function LoadResponse(msgLength)
    local keyframes = ReceiveKeyframes()
    local entity = net.ReadEntity()

    if SMH.State.Entity[entity] then
        SMH.UI.SetKeyframes(keyframes)
    end
end

---@type Receiver
local function GetModelInfoResponse(msgLength)
    local name, class = net.ReadString(), net.ReadString()
    SMH.UI.SetModelName(name, class)
end

---@type Receiver
local function SaveExists(msgLength)
    local names = {}

    for i = 1, net.ReadUInt(INT_BITCOUNT) do
        table.insert(names, net.ReadString())
    end

    SMH.UI.SaveExistsWarning(names)
end

---@type Receiver
local function SaveResponse(msgLength)
    local saveToClient = net.ReadBool()
    local path = net.ReadString()
    if not saveToClient then
        CTRL.GetServerSaves() -- Refresh server saves
        return
    end

    local serializedKeyframes = net.ReadTable()
    SMH.Saves.Save(path, serializedKeyframes, LocalPlayer())
    SMH.UI.AddSaveFile(path)
end

---@type Receiver
local function AddFolderResponse(msgLength)
    local saveToClient = net.ReadBool()
    local folder = net.ReadString()
    if not saveToClient then
        CTRL.GetServerSaves()
        return
    end

    SMH.UI.AddFolder(folder, LocalPlayer())
end

---@type Receiver
local function RequestAppendResponse(msgLength)
    local savenames, gamenames = {}, {}

    for i = 1, net.ReadUInt(INT_BITCOUNT) do
        table.insert(savenames, net.ReadString())
    end
    for i = 1, net.ReadUInt(INT_BITCOUNT) do
        table.insert(gamenames, net.ReadString())
    end

    SMH.UI.AppendWindow(savenames, gamenames)
end

---@type Receiver
local function DeleteSaveResponse(msgLength)
    local isFolder = net.ReadBool()
    local path = net.ReadString()

    SMH.UI.RemoveSaveFile(path, isFolder)
end

---@type Receiver
local function ApplyEntityNameResponse(msgLength)
    local name = net.ReadString()

    SMH.UI.UpdateName(name)
end

---@type Receiver
local function UpdateTimelineResponse(msgLength)
    local keyframes = ReceiveKeyframes()

    SMH.UI.SetKeyframes(keyframes)
end

---@type Receiver
local function RequestModifiersResponse(msgLength)
    local list = net.ReadTable()

    SMH.UI.InitModifiers(list)
end

---@type Receiver
local function UpdateTimelineInfoResponse(msgLength)
    local timeline = ReceiveProperties()

    SMH.UI.SetTimeline(timeline)
end

---@type Receiver
local function UpdateModifierResponse(msgLength)
    local changed = net.ReadString()
    local timeline = ReceiveProperties()

    SMH.UI.UpdateModifier(timeline, changed)
end

---@type Receiver
local function UpdateKeyframeColorResponse(msgLength)
    local timelineinfo = ReceiveProperties()

    SMH.UI.UpdateKeyColor(timelineinfo)
end

---@type Receiver
local function RequestTimelineInfoResponse(msgLength)
    local name = net.ReadString()
    local timeline = ReceiveProperties()

    SMH.Saves.SaveProperties(timeline, name)
    SMH.UI.RefreshTimelineSettings()
end

---@type Receiver
local function RequestWorldDataResponse(msgLength)
    local console = net.ReadString()
    local push = net.ReadString()
    local release = net.ReadString()

    SMH.UI.SetWorldData(console, push, release)
end

---@type Receiver
local function StopPhysicsRecordResponse(msgLength)
    SMH.PhysRecord.Stop()
end

local function RequestNodesResponse(msgLength)
    local nodes = {}
    local len = net.ReadUInt(14)
    for i = 1, len do 
        nodes[i] = {net.ReadUInt(14), net.ReadVector(), net.ReadAngle()}
    end

    SMH.Renderer.SetNodes(nodes)
end

-- AUDIO CONTROL =================
local function PlayAudio()
	//print("play audio")
	local id = net.ReadUInt(INT_BITCOUNT)
	SMH.AudioClip.Play(id)
end

local function StopAudio()
	//print("stop audio")
	local id = net.ReadUInt(INT_BITCOUNT)
	SMH.AudioClip.Stop(id)
end

local function StopAllAudio()
	//print("stop all audio")
	SMH.AudioClip.StopAll()
end
-- ===============================

local function Setup()
    net.Receive(SMH.MessageTypes.SetFrameResponse, SetFrameResponse)

    net.Receive(SMH.MessageTypes.SelectEntityResponse, SelectEntityResponse)

    net.Receive(SMH.MessageTypes.UpdateKeyframeResponse, UpdateKeyframeResponse)
    net.Receive(SMH.MessageTypes.DeleteKeyframeResponse, DeleteKeyframeResponse)
    net.Receive(SMH.MessageTypes.GetAllKeyframes, GetAllKeyframes)

    net.Receive(SMH.MessageTypes.GetServerSavesResponse, GetServerSavesResponse)
    net.Receive(SMH.MessageTypes.GetModelListResponse, GetModelListResponse)
    net.Receive(SMH.MessageTypes.GetServerEntitiesResponse, GetServerEntitiesResponse)
    net.Receive(SMH.MessageTypes.LoadResponse, LoadResponse)
    net.Receive(SMH.MessageTypes.GetModelInfoResponse, GetModelInfoResponse)
    net.Receive(SMH.MessageTypes.SaveExists, SaveExists)
    net.Receive(SMH.MessageTypes.SaveResponse, SaveResponse)
    net.Receive(SMH.MessageTypes.AddFolderResponse, AddFolderResponse)
    net.Receive(SMH.MessageTypes.RequestAppendResponse, RequestAppendResponse)
    net.Receive(SMH.MessageTypes.DeleteSaveResponse, DeleteSaveResponse)

    net.Receive(SMH.MessageTypes.ApplyEntityNameResponse, ApplyEntityNameResponse)
    net.Receive(SMH.MessageTypes.UpdateTimelineResponse, UpdateTimelineResponse)
    net.Receive(SMH.MessageTypes.RequestModifiersResponse, RequestModifiersResponse)
    net.Receive(SMH.MessageTypes.UpdateTimelineInfoResponse, UpdateTimelineInfoResponse)
    net.Receive(SMH.MessageTypes.UpdateModifierResponse, UpdateModifierResponse)
    net.Receive(SMH.MessageTypes.UpdateKeyframeColorResponse, UpdateKeyframeColorResponse)

    net.Receive(SMH.MessageTypes.RequestTimelineInfoResponse, RequestTimelineInfoResponse)

    net.Receive(SMH.MessageTypes.RequestWorldDataResponse, RequestWorldDataResponse)

    net.Receive(SMH.MessageTypes.StopPhysicsRecordResponse, StopPhysicsRecordResponse)

    net.Receive(SMH.MessageTypes.RequestNodesResponse, RequestNodesResponse)
	
	net.Receive(SMH.MessageTypes.PlayAudio, PlayAudio)
	net.Receive(SMH.MessageTypes.StopAudio, StopAudio)
	net.Receive(SMH.MessageTypes.StopAllAudio, StopAllAudio)

    net.Receive(SMH.MessageTypes.RequestDefaultPose, RequestDefaultPose)

    if game.SinglePlayer() then
        local lastUpdate = SMH.State.TimeStamp
        local interval = GetConVar("smh_autosavetime")
        timer.Remove("SMH_Autosave_Timer")
        timer.Create("SMH_Autosave_Timer", interval:GetFloat() * 60, -1, function()
            -- Only autosave when the user is active (i.e. he changes the state).
            -- Otherwise, we would be performing unnecessary saving when nothing has changed
            if lastUpdate == SMH.State.TimeStamp then return end

            local nick = LocalPlayer():Nick():gsub(" ", "")
            local root = "smh/"
            local prefix = ("auto_save_%s"):format(nick)
            local suffix = "_00"
            local search = root .. prefix .. suffix .. "*.txt"
            local autosaves = file.Find(search, "DATA", "dateasc") or {}
            for _, autosave in ipairs(autosaves) do
                local name = autosave:gsub(".txt", "")
                local index = name:sub(-1)
                if index + 1 > 5 then
                    file.Delete(root .. autosave, "DATA")
                else
                    file.Rename(root .. autosave, root .. name:sub(1, #name-1) .. tostring(index + 1) .. ".txt")
                end
            end
            CTRL.Save(prefix .. suffix .. "1", true)
            print(("SMH: Autosaved to %s..."):format(prefix))
            print(("SMH: Next autosave will be in %.2f minutes"):format(interval:GetFloat()))
            lastUpdate = SMH.State.TimeStamp
        end)
        timer.Start("SMH_Autosave_Timer")
    end
end

Setup()
