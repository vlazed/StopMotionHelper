local Active = {}
local MGR = {}

MGR.OffsetPos, MGR.OffsetAng, MGR.OffsetMode = {}, {}, {}

MGR.OriginData = {}

---@param serializedKeyframes SMHFile
---@param model any
---@return string?
---@return string?
---@return table?
local function GetPosData(serializedKeyframes, model)
    for i, sEntity in pairs(serializedKeyframes.Entities) do
        local listname
        if not sEntity.Properties then -- in case if we load an old save without properties entities
            return
        else
            listname = sEntity.Properties.Name
        end

        if listname == model then
            if not sEntity.Properties.Class then return end
            local class, modelpath = sEntity.Properties.Class, sEntity.Properties.Model
            local data = {}

            for _, kframe in pairs(serializedKeyframes.Entities[i].Frames) do
                for name, mod in pairs(kframe.EntityData) do
                    if not data[name] or data[name].Frame > kframe.Position then
                        data[name] = {Modifiers = mod, Frame = kframe.Position}
                    end
                end
            end

            return class, modelpath, data
        end
    end
end

---@param serializedKeyframes SMHFile
---@return FrameData
local function GetDupeData(serializedKeyframes)
    local data = {}
    for _, kframe in ipairs(serializedKeyframes.Entities[1].Frames) do
        for name, mod in pairs(kframe.EntityData) do
            if not data[name] or data[name].Frame > kframe.Position then
                data[name] = {Modifiers = mod, Frame = kframe.Position}
            end
        end
    end

    return data
end

---@param player Player
---@param modname string
---@param keyframe FrameData
---@param pos Vector
local function SetOffset(player, modname, keyframe, pos)
    local mod = SMH.Modifiers[modname]

    local offsetpos = MGR.OffsetPos[player] or Vector(0, 0, 0)
    local offsetang = MGR.OffsetAng[player] or Angle(0, 0, 0)

    keyframe.Modifiers[modname] = mod:Offset(keyframe.Modifiers[modname], MGR.OriginData[player][modname].Modifiers, offsetpos, offsetang, pos)
end

---@param entity Entity
---@param modname string
---@param keyframe FrameData
---@param firstkey FrameData
local function SetDupeOffset(entity, modname, keyframe, firstkey)
    local mod = SMH.Modifiers[modname]

    keyframe.Modifiers[modname] = mod:OffsetDupe(entity, keyframe.Modifiers[modname], firstkey[modname].Modifiers)
end

---@param path string
---@param model string
---@param player Player
---@param serializedKeyframes SMHFile
---@return string?
---@return string?
---@return table?
---@return boolean?
function MGR.SetPreviewEntity(path, model, player, serializedKeyframes)
    if not Active[player] then return nil end
    local class, modelpath, data = GetPosData(serializedKeyframes, model)
    local neworigin = false
    if not class then
        player:ChatPrint("Stop Motion Helper: Failed to get entity info. Probably you're trying to load world entity, or the save is from older SMH version!")
        return nil
    end

    local origindata = nil

    if not MGR.OriginData[player] or not MGR.OffsetMode[player] then
        MGR.SetOrigin(model, player, serializedKeyframes)
        neworigin = true
    end

    return class, modelpath, data, neworigin
end

---@param state any
---@param player Player
function MGR.SetGhost(state, player)
    Active[player] = state
end

---@param model string
---@param settings Settings
---@param player Player
---@param serializedKeyframes SMHFile
---@return SMHEntity?
---@return Vector?
function MGR.Spawn(model, settings, player, serializedKeyframes)
    if not Active[player] then return end
    local class, modelpath, data = GetPosData(serializedKeyframes, model)
    if not class then
        player:ChatPrint("Stop Motion Helper: Failed to get entity info. Probably you're trying to load world entity, or the save is from older SMH version!")
        return
    end

    ---@cast modelpath string
    ---@cast data any

    if IsValid(player) and not player:CheckLimit("smhentity") then return end

    if class == "prop_ragdoll" and not data["physbones"] then
        player:ChatPrint("Stop Motion Helper: Can't spawn the ragdoll as the save doesn't have Physical Bones modifier!")
        return
    end
    if not data["physbones"] and not data["position"] then
        player:ChatPrint("Stop Motion Helper: Can't spawn the entity as the save doesn't have Physical Bones or Position and Rotation modifiers!")
        return
    end

    local entity = ents.Create(class)
    local tracepos = nil
    if MGR.OffsetMode[player] then
        tracepos = player:GetEyeTraceNoCursor().HitPos
    end

    entity:SetModel(modelpath)
    entity:Spawn()

    player:AddCount("smhentity", entity)
    player:AddCleanup("smhentity", entity)

    undo.Create("SMH Spawned entity")
        undo.AddEntity(entity)
        undo.SetPlayer(player)
    undo.Finish()

    for name, mod in pairs(SMH.Modifiers) do
        if not data[name] then continue end
        if data[name] and MGR.OriginData[player][name] and (name == "physbones" or name == "position") then
            local offsetpos = MGR.OffsetPos[player] or Vector(0, 0, 0)
            local offsetang = MGR.OffsetAng[player] or Angle(0, 0, 0)

            local offsetdata = mod:Offset(data[name].Modifiers, MGR.OriginData[player][name].Modifiers, offsetpos, offsetang, tracepos)
            mod:Load(entity, offsetdata, settings)
        else
            mod:Load(entity, data[name].Modifiers, settings)
        end
    end

    ---@cast entity SMHEntity

    return entity, tracepos
end

---@param player Player
---@param entity Entity
---@param offsetpos Vector
function MGR.OffsetKeyframes(player, entity, offsetpos)
    for id, keyframe in pairs(SMH.KeyframeData.Players[player].Entities[entity]) do
        local hasphysics = keyframe.Modifiers["physbones"] and true or false
        local hasposition = keyframe.Modifiers["position"] and true or false

        if not hasphysics and not hasposition then continue end

        if hasphysics then
            SetOffset(player, "physbones", keyframe, offsetpos)
        end

        if hasposition then
            SetOffset(player, "position", keyframe, offsetpos)
        end
    end
end

---@param player Player
---@param entity Entity
---@param serializedKeyframes SMHFile
function MGR.DupeOffsetKeyframes(player, entity, serializedKeyframes)
    local originData = GetDupeData(serializedKeyframes)

    for id, keyframe in pairs(SMH.KeyframeData.Players[player].Entities[entity]) do
        local hasphysics = keyframe.Modifiers["physbones"] and true or false
        local hasposition = keyframe.Modifiers["position"] and true or false

        if not hasphysics and not hasposition then continue end

        if hasphysics then
            SetDupeOffset(entity, "physbones", keyframe, originData)
        end

        if hasposition then
            SetDupeOffset(entity, "position", keyframe, originData)
        end
    end
end

---@param model string
---@param player Player
---@param serializedKeyframes SMHFile
---@return nil
function MGR.SetOrigin(model, player, serializedKeyframes)
    local class, modelpath, data = GetPosData(serializedKeyframes, model)
    if not class then
        player:ChatPrint("Stop Motion Helper: Failed to get entity info. Probably you're trying to load world entity, or the save is from older SMH version!")
        return nil
    end

    MGR.OriginData[player] = data
    return data
end

---@param player Player
function MGR.SpawnReset(player)
    MGR.OriginData[player] = nil
end

---@param set any
---@param player Player
function MGR.SetOffsetMode(set, player)
    MGR.OffsetMode[player] = set
end

---@param pos Vector
---@param player Player
function MGR.SetPosOffset(pos, player)
    MGR.OffsetPos[player] = pos
end

---@param ang Angle
---@param player Player
function MGR.SetAngleOffset(ang, player)
    MGR.OffsetAng[player] = ang
end

---@param entities {[string]: Entity}
---@param serializedKeyframes SMHFile
---@param savePath string
function MGR.Pack(entities, serializedKeyframes, savePath)
    local hasDupes = false
    for _,  data in ipairs(serializedKeyframes.Entities) do
        local entity = entities[data.Properties.Name]
        if not IsValid(entity) or entity:IsPlayer() then continue end
        ---@cast entity Entity

        if entity.smh_IsDupe then
            hasDupes = true
        end
        duplicator.ClearEntityModifier(entity, "SMHPackage")
        duplicator.StoreEntityModifier(entity, "SMHPackage", {
            name = data.Properties.Name,
            save = savePath,
            isDupe = entity.smh_IsDupe ---@diagnostic disable-line
        })
        -- Only apply the dupe thing once, so that it only carries over once per packing operation.
        entity.smh_IsDupe = nil
    end

    return hasDupes
end

SMH.Spawner = MGR
