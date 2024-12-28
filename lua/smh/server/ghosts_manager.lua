---@type GhostData
local GhostData = {}
local LastFrame = 0
local LastTimeline = 1
local SpawnGhost, SpawnGhostData, GhostSettings = {}, {}, {}
local SpawnOffsetOn, SpawnOriginData, OffsetPos, OffsetAng = {}, {}, {}, {}
---@type PoseTrees
local DefaultPoseTrees = {}

---@param player Player
---@param entity SMHEntity
---@param color Color
---@param frame integer
---@param ghostable SMHEntity[]
---@param xray boolean
---@return SMHEntity
local function CreateGhost(player, entity, color, frame, ghostable, xray)
    for _, ghost in ipairs(GhostData[player].Ghosts) do
        if ghost.Entity == entity and ghost.Frame == frame then return ghost end -- we already have a ghost on this entity for this frame, just return it.
    end

    local class = entity:GetClass()
    local model = entity:GetModel()

    local g
    if class == "prop_ragdoll" then
        g = ents.Create("prop_ragdoll")

        local flags = entity:GetSaveTable(false).spawnflags or 0
        if flags % (2 * 32768) >= 32768 then
            g:SetKeyValue("spawnflags", "32768")
            g:SetSaveValue("m_ragdoll.allowStretch", true)
        end
    else
        g = ents.Create("prop_dynamic")

        if class == "prop_effect" and IsValid(entity.AttachedEntity) then
            model = entity.AttachedEntity:GetModel()
        end
    end

    ---@cast g SMHEntity

    g:SetModel(model)
    g:SetRenderMode(RENDERMODE_TRANSCOLOR)
    g:SetCollisionGroup(COLLISION_GROUP_NONE)
    g:SetNotSolid(true)
    g:SetColor(color)
    g:Spawn()

    g:SetPos(entity:GetPos())
    g:SetAngles(entity:GetAngles())

    if xray then
        g:SetMaterial("!SMH_XRay")
    end

    g.SMHGhost = true
    g.Entity = entity
    g.Frame = frame
    g.Physbones = false
    g:SetNW2Bool("SMHGhost", true)
    g:SetNW2Entity("Entity", entity)

    if entity.RagdollWeightData and class == "prop_ragdoll" then
        timer.Simple(0, function()
            for i = 0, g:GetPhysicsObjectCount() - 1 do
                g:GetPhysicsObjectNum(i):SetMass(entity.RagdollWeightData[i])
            end
        end)
    end

    table.insert(ghostable, g)

    return g
end

local function SetGhostFrame(entity, ghost, modifiers, modname)
    if modifiers[modname] ~= nil then
        SMH.Modifiers[modname]:LoadGhost(entity, ghost, modifiers[modname])
        if modname == "physbones" then ghost.Physbones = true end
    end
end

local function SetGhostBetween(entity, ghost, data1, data2, modname, percentage)
    if data1[modname] ~= nil then
        SMH.Modifiers[modname]:LoadGhostBetween(entity, ghost, data1[modname], data2[modname], percentage)
        if modname == "physbones" then ghost.Physbones = true end
    end
end

local function ClearNoPhysGhosts(ghosts)
    for _, g in ipairs(ghosts) do
        if g:GetClass() == "prop_ragdoll" and not g.Physbones and IsValid(g) then
            g:Remove()
        end
    end
end

local MGR = {}

MGR.IsRendering = false

function MGR.SelectEntity(player, entities)
    if not GhostData[player] then
        GhostData[player] = {
            Entity = {},
            Ghosts = {},
            Nodes = {},
            PreviousName = "",
            LastEntity = NULL,
            Updated = false
        }
    end

    GhostData[player].Entity = table.Copy(entities)
end

---@param player Player
---@param frame integer
---@param settings Settings
---@param timeline Properties
---@param settimeline integer
function MGR.UpdateState(player, frame, settings, timeline, settimeline)
    LastFrame = frame
    LastTimeline = settimeline

    if not GhostData[player] then
        return
    end

    local ghosts = GhostData[player].Ghosts

    for _, ghost in pairs(ghosts) do
        if IsValid(ghost) then
            ghost:Remove()
        end
    end
    table.Empty(ghosts)

    if not settings.GhostPrevFrame and not settings.GhostNextFrame and not settings.OnionSkin or MGR.IsRendering then
        return
    end

    if not SMH.KeyframeData.Players[player] then
        return
    end

    local entities = SMH.KeyframeData.Players[player].Entities
    local _, gentity = next(GhostData[player].Entity)
    if not settings.GhostAllEntities and IsValid(gentity) and entities[gentity] then
        local oldentities = table.Copy(entities)
        entities = {}
        for _, entity in pairs(GhostData[player].Entity) do
            entities[entity] = oldentities[entity]
        end
    elseif not settings.GhostAllEntities then
        return
    end

    local alpha = settings.GhostTransparency * 255
    local xray = settings.GhostXRay
    local selectedtime  = settimeline
    if selectedtime > timeline.Timelines then -- this shouldn't really happen?
        selectedtime = 1
    end

    local filtermods = {}

    for _, name in ipairs(timeline.TimelineMods[selectedtime]) do
        filtermods[name] = true
    end

    for entity, keyframes in pairs(entities) do

        for name, _ in pairs(filtermods) do -- gonna apply used modifiers
            local prevKeyframe, nextKeyframe, lerpMultiplier = SMH.GetClosestKeyframes(keyframes, frame, true, name)
            if not prevKeyframe and not nextKeyframe then
                continue
            end
            ---@cast prevKeyframe FrameData
            ---@cast nextKeyframe FrameData
            ---@cast entity SMHEntity

            if lerpMultiplier == 0 then
                if settings.GhostPrevFrame and prevKeyframe.Frame < frame then
                    local g = CreateGhost(player, entity, Color(200, 0, 0, alpha), prevKeyframe.Frame, ghosts, xray)
                    SetGhostFrame(entity, g, prevKeyframe.Modifiers, name)
                elseif settings.GhostNextFrame and nextKeyframe.Frame > frame then
                    local g = CreateGhost(player, entity, Color(0, 200, 0, alpha), nextKeyframe.Frame, ghosts, xray)
                    SetGhostFrame(entity, g, nextKeyframe.Modifiers, name)
                end
            else
                if settings.GhostPrevFrame then
                    local g = CreateGhost(player, entity, Color(200, 0, 0, alpha), prevKeyframe.Frame, ghosts, xray)
                    SetGhostFrame(entity, g, prevKeyframe.Modifiers, name)
                end
                if settings.GhostNextFrame then
                    local g = CreateGhost(player, entity, Color(0, 200, 0, alpha), nextKeyframe.Frame, ghosts, xray)
                    SetGhostFrame(entity, g, nextKeyframe.Modifiers, name)
                end
            end

            if settings.OnionSkin then
                for _, keyframe in pairs(keyframes) do
                    if keyframe.Modifiers[name] then
                        local g = CreateGhost(player, entity, Color(255, 255, 255, alpha), keyframe.Frame, ghosts, xray)
                        SetGhostFrame(entity, g, keyframe.Modifiers, name)
                    end
                end
            end
        end

        for _, g in ipairs(ghosts) do

            if not (g.Entity == entity) then continue end

            for name, mod in pairs(SMH.Modifiers) do
                if filtermods[name] then continue end -- we used these modifiers already
                local IsSet = false
                for _, keyframe in pairs(keyframes) do
                    if keyframe.Frame == g.Frame and keyframe.Modifiers[name] then
                        SetGhostFrame(entity, g, keyframe.Modifiers, name)
                        IsSet = true
                        break
                    end
                end

                if not IsSet then
                    local prevKeyframe, nextKeyframe, lerpMultiplier = SMH.GetClosestKeyframes(keyframes, g.Frame, true, name)
                    if not prevKeyframe then
                        continue
                    end
                    ---@cast prevKeyframe FrameData
                    ---@cast nextKeyframe FrameData

                    if lerpMultiplier <= 0 or settings.TweenDisable then
                        SetGhostFrame(entity, g, prevKeyframe.Modifiers, name)
                    elseif lerpMultiplier >= 1 then
                        SetGhostFrame(entity, g, nextKeyframe.Modifiers, name)
                    else
                        SetGhostBetween(entity, g, prevKeyframe.Modifiers, nextKeyframe.Modifiers, name, lerpMultiplier)
                    end
                end
            end
        end

        ClearNoPhysGhosts(ghosts) -- need to delete ragdoll ghosts that don't have physbone modifier, or else they'll just keep falling through ground.
    end
end

---@param player Player
---@param timeline Properties
---@param settings Settings
function MGR.UpdateSettings(player, timeline, settings)
    MGR.UpdateState(player, LastFrame, settings, timeline, LastTimeline)
end

---@param modelName string
---@param tree PoseTree
function MGR.SetTree(modelName, tree)
    DefaultPoseTrees[modelName] = tree
end

function MGR.GetTree(modelName)
    return DefaultPoseTrees[modelName]
end

---@param class string
---@param modelpath string
---@param data any
---@param settings Settings
---@param player Player
function MGR.SetSpawnPreview(class, modelpath, data, settings, player)
    if IsValid(SpawnGhost[player]) then
        SpawnGhost[player]:Remove()
    end
    SpawnGhost[player] = nil
    SpawnGhostData[player] = nil

    if class == "prop_ragdoll" and not data["physbones"] then
        player:ChatPrint("Stop Motion Helper: Can't set preview for the ragdoll as the save doesn't have Physical Bones modifier!")
        return
    end
    if not data["physbones"] and not data["position"] then
        player:ChatPrint("Stop Motion Helper: Can't set preview for the entity as the save doesn't have Physical Bones or Position and Rotation modifiers!")
        return
    end

    SpawnGhostData[player] = data
    GhostSettings[player] = settings

    if class == "prop_ragdoll" then
        SpawnGhost[player] = ents.Create("prop_ragdoll")
    else
        SpawnGhost[player] = ents.Create("prop_dynamic")
    end
    local alpha = settings.GhostTransparency * 255

    SpawnGhost[player]:SetModel(modelpath)
    SpawnGhost[player]:SetRenderMode(RENDERMODE_TRANSCOLOR)
    SpawnGhost[player]:SetCollisionGroup(COLLISION_GROUP_NONE)
    SpawnGhost[player]:SetNotSolid(true)
    SpawnGhost[player]:SetColor(Color(255, 255, 255, alpha))
    SpawnGhost[player]:Spawn()

    for name, mod in pairs(SMH.Modifiers) do
        if name == "color" then continue end
        if name == "physbones" or name == "position" then
            local offsetpos = OffsetPos[player] or Vector(0, 0, 0)
            local offsetang = OffsetAng[player] or Angle(0, 0, 0)

            local offsetdata = mod:Offset(data[name].Modifiers, SpawnOriginData[player][name].Modifiers, offsetpos, offsetang, nil)
            mod:Load(SpawnGhost[player], offsetdata, GhostSettings[player])
        elseif data[name] then
            mod:Load(SpawnGhost[player], data[name].Modifiers, settings)
        end
    end
end

---@param player Player
---@param offseton any
function MGR.RefreshSpawnPreview(player, offseton)
    SpawnOffsetOn[player] = offseton
    if not IsValid(SpawnGhost[player]) then return end

    for name, mod in pairs(SMH.Modifiers) do
        if name == "color" then continue end
        if name == "physbones" or name == "position" then
            local offsetpos = OffsetPos[player] or Vector(0, 0, 0)
            local offsetang = OffsetAng[player] or Angle(0, 0, 0)

            local offsetdata = mod:Offset(SpawnGhostData[player][name].Modifiers, SpawnOriginData[player][name].Modifiers, offsetpos, offsetang, nil)
            mod:Load(SpawnGhost[player], offsetdata, GhostSettings[player])
        elseif SpawnGhostData[player][name] then
            mod:Load(SpawnGhost[player], SpawnGhostData[player][name].Modifiers, GhostSettings[player])
        end
    end
end

---@param player Player
function MGR.SpawnClear(player)
    if IsValid(SpawnGhost[player]) then
        SpawnGhost[player]:Remove()
        SpawnGhost[player] = nil
    end
end

---@param data any
---@param player Player
function MGR.SetSpawnOrigin(data, player)
    SpawnOriginData[player] = data
end

---@param player Player
function MGR.ClearSpawnOrigin(player)
    SpawnOriginData[player] = nil
end

---@param pos Vector
---@param player Player
function MGR.SetPosOffset(pos, player)
    OffsetPos[player] = pos
    MGR.RefreshSpawnPreview(player, SpawnOffsetOn[player])
end

---@param ang Angle
---@param player Player
function MGR.SetAngleOffset(ang, player)
    OffsetAng[player] = ang
    MGR.RefreshSpawnPreview(player, SpawnOffsetOn[player])
end

---@param player Player
function MGR.UpdateKeyframe(player)
    if not GhostData[player] then return end

    GhostData[player].Updated = true
end

---@param player Player
---@return table?
function MGR.RequestNodes(player)
    if not GhostData[player] then return end

    local nodes = GhostData[player].Nodes
    local selectedEntities = GhostData[player].Entity
    local previousName = GhostData[player].PreviousName
    local lastEntity = GhostData[player].LastEntity
    local updated = GhostData[player].Updated

    local entities = SMH.KeyframeData.Players[player] and SMH.KeyframeData.Players[player].Entities

    if not nodes or not entities or not selectedEntities or #selectedEntities == 0 then return {} end

    local entity = selectedEntities[1]
    local keyframes = entities[entity]
    local boneName = player:GetInfo("smh_motionpathbone")

    if entity:GetClass() == "prop_effect" and IsValid(entity.AttachedEntity) then
        entity = entity.AttachedEntity
    end

    GhostData[player].LastEntity = entity

    if not keyframes then return {} end
    if #boneName == 0 then return {} end

    local sameKeyframeCount = #keyframes == #nodes
    local sameBoneName = previousName == boneName
    local sameEntity = lastEntity == entity

    -- Don't send any data back if the number of keyframes, the motion path bone, or the selected entity hasn't changed at all
    if sameKeyframeCount and sameBoneName and sameEntity and not updated then
        return
    end

    GhostData[player].Updated = false

    table.Empty(nodes)

    local bone = entity:LookupBone(boneName)
    local physBone = bone and entity:TranslateBoneToPhysBone(bone)
    local isPhysBone = bone and (bone == entity:TranslatePhysBoneToBone(physBone))

    for _, keyframe in pairs(keyframes) do
        local pos = vector_origin
        local ang = angle_zero
        if isPhysBone and keyframe.Modifiers.physbones and keyframe.Modifiers.physbones[physBone] then
            pos = keyframe.Modifiers.physbones[physBone].Pos 
            ang = keyframe.Modifiers.physbones[physBone].Ang 
        elseif bone and keyframe.Modifiers.bones and keyframe.Modifiers.bones[bone] and DefaultPoseTrees[entity:GetModel()] then
            local defaultPoseTree = DefaultPoseTrees[entity:GetModel()]
            local branch = {}
            do
                local id = bone
                local pose = defaultPoseTree[bone]
                while pose and not pose.IsPhysBone do
                    table.insert(branch, id)
                    id = pose.Parent
                    pose = defaultPoseTree[id]
                end
            end

            for i = 1, #branch do
                local lPos, lAng = defaultPoseTree[branch[i]].LocalPos, defaultPoseTree[branch[i]].LocalAng
                local dataPos, dataAng = keyframe.Modifiers.bones[branch[i]].Pos, keyframe.Modifiers.bones[branch[i]].Ang
                local finalPos, finalAng = LocalToWorld(dataPos, dataAng, lPos, lAng)
                pos, ang = LocalToWorld(pos, ang, finalPos, finalAng)
            end
            
            if keyframe.Modifiers.physbones then
                pos = LocalToWorld(pos, ang, keyframe.Modifiers.physbones[physBone].Pos, keyframe.Modifiers.physbones[physBone].Ang)
            elseif keyframe.Modifiers.position then
                pos = LocalToWorld(pos, ang, keyframe.Modifiers.position.Pos, angle_zero)
            end
        elseif keyframe.Modifiers.position and keyframe.Modifiers.position.Pos then
            pos = keyframe.Modifiers.position.Pos
            ang = keyframe.Modifiers.position.Ang
        end

        table.insert(nodes, {keyframe.Frame, pos, ang})
    end

    GhostData[player].PreviousName = boneName

    return nodes
end

SMH.GhostsManager = MGR

hook.Add("Think", "SMHGhostSpawnOffsetPreview", function()
    for player, data in pairs(SpawnOriginData) do
        if SpawnOffsetOn[player] and IsValid(SpawnGhost[player]) then
            for name, mod in pairs(SMH.Modifiers) do
                if name == "color" then continue end
                if SpawnGhostData[player][name] and data[name] and (name == "physbones" or name == "position") then
                    local offsetpos = OffsetPos[player] or Vector(0, 0, 0)
                    local offsetang = OffsetAng[player] or Angle(0, 0, 0)

                    local offsetdata = mod:Offset(SpawnGhostData[player][name].Modifiers, data[name].Modifiers, offsetpos, offsetang, player:GetEyeTraceNoCursor().HitPos)
                    mod:Load(SpawnGhost[player], offsetdata, GhostSettings[player])
                end
            end
        end
    end
end)
