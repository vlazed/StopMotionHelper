---@type GhostData
local GhostData = {}
local LastFrame = 0
local LastTimeline = 1
---@type SpawnGhost, SpawnGhostData, GhostSettings
local SpawnGhost, SpawnGhostData, GhostSettings = {}, {}, {}
local SpawnOffsetOn, SpawnOriginData, OffsetPos, OffsetAng = {}, {}, {}, {}
---@type PoseTrees
local DefaultPoseTrees = {}

local check = SMH.SettingsManager.CheckSetting
local getSetting = SMH.SettingsManager.GetSetting

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
            for boneid, weight in pairs(entity.RagdollWeightData) do
                if isstring(boneid) then
                    ---@diagnostic disable-next-line
                    boneid = BoneToPhysBone(entity, entity:LookupBone(boneid))
                    local po = g:GetPhysicsObjectNum(boneid)
                    if po then
                        po:SetMass(weight)
                    end
                else
                    local po = g:GetPhysicsObjectNum(boneid)
                    if po then
                        po:SetMass(weight)
                    end
                end
            end
        end)
    end

    table.insert(ghostable, g)

    return g
end

local function SetGhostFrame(entity, ghost, modifiers, modname)
    if modifiers[modname] ~= nil then
        SMH.Modifiers[modname]:LoadGhost(entity, ghost, modifiers[modname])
        if SMH.Modifiers[modname].Ghost then ghost.Physbones = true end
    end
end

local function SetGhostBetween(entity, ghost, data1, data2, modname, percentage)
    if data1[modname] ~= nil then
        SMH.Modifiers[modname]:LoadGhostBetween(entity, ghost, data1[modname], data2[modname], percentage)
        if SMH.Modifiers[modname].Ghost then ghost.Physbones = true end
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

    local _, gentity = next(GhostData[player].Entity)

    for _, ghost in pairs(ghosts) do
        if IsValid(ghost) then
            ghost:Remove()
        end
    end
    table.Empty(ghosts)

    if not check(settings, "GhostPrevFrame", gentity) and not check(settings, "GhostNextFrame", gentity) and not check(settings, "OnionSkin", gentity) or MGR.IsRendering then
        return
    end

    if not SMH.KeyframeData.Players[player] then
        return
    end

    local entities = SMH.KeyframeData.Players[player].Entities
    local _, gentity = next(GhostData[player].Entity)
    if not check(settings, "GhostAllEntities", gentity) and IsValid(gentity) and entities[gentity] then
        local oldentities = table.Copy(entities)
        entities = {}
        for _, entity in pairs(GhostData[player].Entity) do
            entities[entity] = oldentities[entity]
        end
    elseif not check(settings, "GhostAllEntities", gentity) then
        return
    end

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

            local alpha = check(settings, "GhostTransparency", entity) * 255
            local xray = check(settings, "GhostXRay", entity)

            if lerpMultiplier == 0 then
                if check(settings, "GhostPrevFrame", entity) and prevKeyframe.Frame < frame then
                    local g = CreateGhost(player, entity, Color(200, 0, 0, alpha), prevKeyframe.Frame, ghosts, xray)
                    SetGhostFrame(entity, g, prevKeyframe.Modifiers, name)
                elseif check(settings, "GhostNextFrame", entity) and nextKeyframe.Frame > frame then
                    local g = CreateGhost(player, entity, Color(0, 200, 0, alpha), nextKeyframe.Frame, ghosts, xray)
                    SetGhostFrame(entity, g, nextKeyframe.Modifiers, name)
                end
            else
                if check(settings, "GhostPrevFrame", entity) then
                    local g = CreateGhost(player, entity, Color(200, 0, 0, alpha), prevKeyframe.Frame, ghosts, xray)
                    SetGhostFrame(entity, g, prevKeyframe.Modifiers, name)
                end
                if check(settings, "GhostNextFrame", entity) then
                    local g = CreateGhost(player, entity, Color(0, 200, 0, alpha), nextKeyframe.Frame, ghosts, xray)
                    SetGhostFrame(entity, g, nextKeyframe.Modifiers, name)
                end
            end

            if check(settings, "OnionSkin", entity) then
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

                    if lerpMultiplier <= 0 or check(settings, "TweenDisable", g.Entity) then
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

---@param keyframes FrameData[]
---@param frame integer
---@param modifier string
---@param tweening boolean
---@param index integer?
---@return Vector
---@return Angle
local function lerpTransform(keyframes, frame, modifier, tweening, index)
    local pos, ang = vector_origin, angle_zero
    local prevFrame, nextFrame, lerp = SMH.GetClosestKeyframes(keyframes, frame, true, modifier)
    if prevFrame and nextFrame then
        local prevData, nextData
        if index then
            prevData, nextData = prevFrame.Modifiers[modifier][index], nextFrame.Modifiers[modifier][index]
        else
            prevData, nextData = prevFrame.Modifiers[modifier], nextFrame.Modifiers[modifier]
        end
        if prevData and nextData then
            pos = SMH.LerpLinearVector(prevData.Pos, nextData.Pos, tweening and lerp or 0)
            ang = SMH.LerpLinearAngle(prevData.Ang, nextData.Ang, tweening and lerp or 0)
        end
    end
    return pos, ang
end

---@param player Player
---@return table?
function MGR.RequestNode(player)
    if not GhostData[player] then return end

    local nodes = GhostData[player].Nodes
    local selectedEntities = GhostData[player].Entity
    local entities = SMH.KeyframeData.Players[player] and SMH.KeyframeData.Players[player].Entities

    if not nodes or not entities or not selectedEntities or #selectedEntities == 0 then return end

    local entity = selectedEntities[1]
    local boneName = player:GetInfo("smh_motionpathbone")

    if entity:GetClass() == "prop_effect" and IsValid(entity.AttachedEntity) then
        entity = entity.AttachedEntity
    end

    local bone = entity:LookupBone(boneName)
    local physBone = bone and BoneToPhysBone(entity, bone)
    local physBoneParent = bone and GetPhysBoneParentFromBone(entity, bone)
    local isPhysBone = bone and physBone >= 0
    
    local pos, ang = vector_origin, angle_zero
    if isPhysBone and physBone then
        local physObj = entity:GetPhysicsObjectNum(physBone)
        pos, ang = physObj:GetPos(), physObj:GetAngles()
    elseif bone and DefaultPoseTrees[entity:GetModel()] then
        local defaultPoseTree = DefaultPoseTrees[entity:GetModel()]
        local branch = {}
        do
            local id = bone
            local pose = defaultPoseTree[bone]
            local boneParent = PhysBoneToBone(entity, physBoneParent)
            while pose and id ~= boneParent do
                table.insert(branch, id)
                id = pose.Parent
                pose = defaultPoseTree[id]
            end
        end

        for i = 1, #branch do
            local lPos, lAng = defaultPoseTree[branch[i]].LocalPos, defaultPoseTree[branch[i]].LocalAng
            local dataPos, dataAng = entity:GetManipulateBonePosition(branch[i]), entity:GetManipulateBoneAngles(branch[i])
            local finalPos, finalAng = LocalToWorld(dataPos, dataAng, lPos, lAng)
            pos, ang = LocalToWorld(pos, ang, finalPos, finalAng)
        end

        local parentPos, parentAng = vector_origin, angle_zero
        if physBoneParent then
            local physObj = entity:GetPhysicsObjectNum(physBoneParent)
            parentPos, parentAng = physObj:GetPos(), physObj:GetAngles()
        else
            parentPos, parentAng = entity:GetPos(), entity:GetAngles()
        end
        pos = LocalToWorld(pos, ang, parentPos, parentAng)
    else
        pos, ang = entity:GetPos(), entity:GetAngles()
    end
    return {pos, ang}
end

---@param modifierArray FramePose[]
---@return boolean
local function isPhysBoneModifier(modifierArray)
    if not istable(modifierArray) then return false end
    
    for _, pose in pairs(modifierArray) do
        if istable(pose) and pose.Moveable ~= nil then return true end
    end

    return false
end

---@param player Player
---@param settings Settings
---@return table?
function MGR.RequestNodes(player, settings)
    if not GhostData[player] then return end

    local nodes = GhostData[player].Nodes
    local selectedEntities = GhostData[player].Entity
    local previousName = GhostData[player].PreviousName
    local lastEntity = GhostData[player].LastEntity
    local updated = GhostData[player].Updated
    local tweening = not settings.TweenDisable

    local entities = SMH.KeyframeData.Players[player] and SMH.KeyframeData.Players[player].Entities

    if not nodes or not entities or not selectedEntities or #selectedEntities == 0 then return {} end

    local entity = selectedEntities[1]
    local keyframes = entities[entity]
    local boneName = player:GetInfo("smh_motionpathbone")

    if not IsValid(entity) then return {} end

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
    local physBone = bone and BoneToPhysBone(entity, bone)
    local physBoneParent = bone and GetPhysBoneParentFromBone(entity, bone)
    local isPhysBone = bone and physBone >= 0

    for _, keyframe in pairs(keyframes) do
        local pos, ang = vector_origin, angle_zero
        if isPhysBone then
            local calc = false
            for name, modifier in pairs(keyframe.Modifiers) do
                if istable(modifier) and modifier[physBone] and modifier[physBone].Moveable ~= nil then
                    pos = modifier[physBone].Pos
                    ang = modifier[physBone].Ang
                    calc = true
                elseif isPhysBoneModifier(modifier) then
                    local newPos, newAng = lerpTransform(keyframes, keyframe.Frame, name, tweening, physBone)
                    calc = pos ~= newPos and ang ~= newAng
                end
                if calc then
                    break
                end
            end
        elseif bone and DefaultPoseTrees[entity:GetModel()] then
            local defaultPoseTree = DefaultPoseTrees[entity:GetModel()]
            local branch = {}
            do
                local id = bone
                local pose = defaultPoseTree[bone]
                local boneParent = PhysBoneToBone(entity, physBoneParent)
                while pose and id ~= boneParent do
                    table.insert(branch, id)
                    id = pose.Parent
                    pose = defaultPoseTree[id]
                end
            end

            pos, ang = vector_origin, angle_zero
            for i = 1, #branch do
                local lPos, lAng = defaultPoseTree[branch[i]].LocalPos, defaultPoseTree[branch[i]].LocalAng
                local dataPos, dataAng = vector_origin, angle_zero
                if keyframe.Modifiers.bones then
                    dataPos, dataAng = keyframe.Modifiers.bones[branch[i]].Pos, keyframe.Modifiers.bones[branch[i]].Ang
                else
                    dataPos, dataAng = lerpTransform(keyframes, keyframe.Frame, "bones", tweening, bone)
                end
                local finalPos, finalAng = LocalToWorld(dataPos, dataAng, lPos, lAng)
                pos, ang = LocalToWorld(pos, ang, finalPos, finalAng)
            end

            local parentPos, parentAng = vector_origin, angle_zero
            local calc = false
            for name, modifier in pairs(keyframe.Modifiers) do
                if istable(modifier) and modifier[physBoneParent] and modifier[physBoneParent].Moveable ~= nil then
                    parentPos, parentAng = modifier[physBoneParent].Pos, modifier[physBoneParent].Ang
                    calc = true
                elseif physBoneParent and isPhysBoneModifier(modifier) then
                    local newPos, newAng = lerpTransform(keyframes, keyframe.Frame, name, tweening, physBoneParent)
                    calc = parentPos ~= newPos and parentAng ~= newAng
                else
                    if name == "position" then
                        parentPos, parentAng = modifier.Pos or parentPos, modifier.Ang or parentAng
                        break
                    end
                end
                if calc then
                    break
                end
            end
            pos = LocalToWorld(pos, ang, parentPos, parentAng)
        else
            if keyframe.Modifiers.position then
                pos = keyframe.Modifiers.position.Pos
                ang = keyframe.Modifiers.position.Ang
            else
                pos, ang = lerpTransform(keyframes, keyframe.Frame, "position", tweening)
            end
        end

        if pos and ang then
            table.insert(nodes, {keyframe.Frame, pos, ang})
        end
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
