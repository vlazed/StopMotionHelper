local function GetExistingKeyframe(player, entity, frame, modnames)
    if not SMH.KeyframeData.Players[player] or not SMH.KeyframeData.Players[player].Entities[entity] then
        return nil
    end
    if not modnames then
        modnames = { "world" }
        for name, mod in pairs(SMH.Modifiers) do
            table.insert(modnames, name)
        end
    end

    local keyframes = SMH.KeyframeData.Players[player].Entities[entity]
    for _, keyframe in pairs(keyframes) do
        for _, name in ipairs(modnames) do
            if keyframe.Frame == frame and keyframe.Modifiers[name] then
                return keyframe
            end
        end
    end

    return nil
end

local function Record(keyframe, player, entity, modnames)
    local recorded = false
    for _, name in ipairs(modnames) do
        if not SMH.Modifiers[name] then continue end
        local data = SMH.Modifiers[name]:Save(entity)
        if not data then continue end
        recorded = true
        keyframe.Modifiers[name] = data
        keyframe.EaseIn[name] = keyframe.EaseIn[name] and keyframe.EaseIn[name] or 0
        keyframe.EaseOut[name] = keyframe.EaseOut[name] and keyframe.EaseOut[name] or 0
    end

    return recorded
end

local function ClearModifier(keyframe, modname)
    keyframe.Modifiers[modname] = nil
    keyframe.EaseIn[modname] = nil
    keyframe.EaseOut[modname] = nil
end


hook.Add("EntityRemoved", "SMHKeyframesEntityRemoved", function(entity)

    for _, player in pairs(player.GetAll()) do
        if SMH.KeyframeData.Players[player] and SMH.KeyframeData.Players[player].Entities[entity] then
            local keyframesToDelete = {}
            for _, keyframe in pairs(SMH.KeyframeData.Players[player].Entities[entity]) do
                table.insert(keyframesToDelete, keyframe.ID)
            end

            SMH.KeyframeData.Players[player].Entities[entity] = nil

            for _, keyframeId in pairs(keyframesToDelete) do
                SMH.KeyframeData:Delete(player, keyframeId)
            end
        end
    end

end)

local MGR = {}

-- This function gathers all keyframes data and frames in a table for each modifier.
--
-- Modkeys = {
-- ██ Entities[entity] = {
-- ████ ModData[modifier] = {...}
-- ████ ModFrames[modifier] = {...}
-- ██ }
-- }
-- 
function MGR.OrganizeKeyframes(player)
    if not SMH.KeyframeData.Players[player] then
        return
    end

    for entity, keyframes in pairs(SMH.KeyframeData.Players[player].Entities) do
        if player == entity then
            continue
        end

        table.sort(keyframes, function(a, b) return a.Frame < b.Frame end)
        
        for name, mod in pairs(SMH.Modifiers) do

            local keyframesmod = {}
            local frames = {}

            for k=1, #keyframes do
                if keyframes[k].Modifiers[name] and keyframes[k].Entity == entity then
                    table.insert(keyframesmod, keyframes[k].Modifiers[name])
                    table.insert(frames, keyframes[k].Frame)
                end
            end

            mod.OrganizeData = mod.OrganizeData or function(params) 
                return params.data  
            end

            keyframesmod = mod:OrganizeData({entity = entity, data = keyframesmod, frames = frames})
            table.sort(frames) --just in case
   
            SMH.KeyframeData.Players[player].Modkeys.Entities[entity].ModData[name] = keyframesmod
            SMH.KeyframeData.Players[player].Modkeys.Entities[entity].ModFrames[name] = frames

        end
        
    end
    --print("██ OrganizeKeyframes ejecutado con exito! ██")
end

function MGR.GetAll(player)
    if not SMH.KeyframeData.Players[player] then
        return {}
    end
    local keyframes = SMH.KeyframeData.Players[player].Keyframes

    local result = {}
    for _, keyframe in pairs(keyframes) do
        table.insert(result, table.Copy(keyframe))
    end
    return result
end

function MGR.GetAllForEntity(player, entities)
    local keyframes = {}

    for _, entity in ipairs(entities) do
        if not SMH.KeyframeData.Players[player] or not SMH.KeyframeData.Players[player].Entities[entity] then
            continue
        end

        for k, keyframe in pairs(SMH.KeyframeData.Players[player].Entities[entity]) do
            table.insert(keyframes, keyframe)
        end
    end

    return keyframes
end

function MGR.Create(player, entities, frame, timeline)
    local keyframes = {}
    SMH.GLOBAL_isOrgKeysNeeded = true --global keyframe organizer bool

    for _, entity in ipairs(entities) do
        if player ~= entity then
            local modnames = SMH.Properties.Players[player].TimelineSetting.TimelineMods[timeline]
            local keyframe = GetExistingKeyframe(player, entity, frame)

            if keyframe ~= nil then
                local check = Record(keyframe, player, entity, modnames)
                if check then
                    table.insert(keyframes, keyframe)
                    --KEYFRAME CREATE nil
                    --print("keyframe not nil in " .. frame .. " created")
                end
            else
                keyframe = SMH.KeyframeData:New(player, entity)
                keyframe.Frame = frame
                local check = Record(keyframe, player, entity, modnames)
                if check then
                    table.insert(keyframes, keyframe)
                    --KEYFRAME CREATE 
                    --print("keyframe " .. frame .. " created")
                end
            end
        else
            local keyframe = GetExistingKeyframe(player, entity, frame, {"world"})

            if keyframe ~= nil then return {keyframe} end

            keyframe = SMH.KeyframeData:New(player, entity)
            keyframe.Frame = frame
            keyframe.EaseIn["world"] = 0
            keyframe.EaseOut["world"] = 0
            keyframe.Modifiers["world"] = {
                Console = "",
                Push = "",
                Release = "",
            }
            table.insert(keyframes, keyframe)
            --KEYFRAME CREATE 
            --print("keyframe WORLD " .. frame .. " created")
        end
    end

    return keyframes
end

function MGR.Update(player, keyframeIds, updateData, timeline)
    local keyframes, movingkeyframes = {}, {}
    SMH.GLOBAL_isOrgKeysNeeded = true --global keyframe organizer bool

    for id, keyframeId in ipairs(keyframeIds) do
        if not SMH.KeyframeData.Players[player] or not SMH.KeyframeData.Players[player].Keyframes[keyframeId] then
            error("Invalid keyframe ID")
        end

        local keyframe = SMH.KeyframeData.Players[player].Keyframes[keyframeId]
        local modnames = player == keyframe.Entity and {"world"} or SMH.Properties.Players[player].TimelineSetting.TimelineMods[timeline]
        local updateableFields = {
            "Frame",
            "EaseIn",
            "EaseOut",
        }
        for _, field in pairs(updateableFields) do
            if updateData[id][field] then
                if field == "Frame" then
                    if updateData[id][field] == keyframe.Frame then continue end
                    local remainmods, EaseIn, EaseOut, frame = table.Copy(keyframe.Modifiers), table.Copy(keyframe.EaseIn), table.Copy(keyframe.EaseOut), updateData[id][field]
                    for _, name in ipairs(modnames) do
                        remainmods[name] = nil
                        EaseIn[name] = nil
                        EaseOut[name] = nil
                    end

                    if next(remainmods) then -- if there are any modifiers remaining, then we create another keyframe that will stay there
                        local remainkeyframe = SMH.KeyframeData:New(player, keyframe.Entity)

                        for name, _ in pairs(remainmods) do
                            ClearModifier(keyframe, name)
                        end
                        remainkeyframe.Frame = keyframe.Frame
                        remainkeyframe.Modifiers = remainmods
                        remainkeyframe.EaseIn = EaseIn
                        remainkeyframe.EaseOut = EaseOut
                    end

                    movingkeyframes[keyframe] = frame
                else
                    for _, name in ipairs(modnames) do
                        if not keyframe[field][name] then continue end
                        keyframe[field][name] = updateData[id][field]
                    end
                    table.insert(keyframes, keyframe)
                    
                end
            end
        end
    end

    for keyframe, frame in pairs(movingkeyframes) do
        local replacekey = GetExistingKeyframe(player, keyframe.Entity, frame)

        if replacekey ~= nil and not movingkeyframes[replacekey] then
            for name, data in pairs(replacekey.Modifiers) do

                if not keyframe.Modifiers[name] then
                    keyframe.Modifiers[name] = data
                    keyframe.EaseIn[name] = replacekey.EaseIn[name]
                    keyframe.EaseOut[name] = replacekey.EaseOut[name]
                end
            end
            SMH.KeyframeData:Delete(player, replacekey.ID)
        end
        keyframe.Frame = frame
        table.insert(keyframes, keyframe)
        --KEYFRAME UPDATE
        --print("keyframe " .. frame .. " updated")
    end

    return keyframes
end

function MGR.Copy(player, keyframeIds, frame, timeline)
    SMH.GLOBAL_isOrgKeysNeeded = true --global keyframe organizer bool
    local copiedKeyframes, movingkeyframes = {}, {}

    for id, keyframeId in ipairs(keyframeIds) do
        if not SMH.KeyframeData.Players[player] or not SMH.KeyframeData.Players[player].Keyframes[keyframeId] then
            error("Invalid keyframe ID")
        end

        local keyframe = SMH.KeyframeData.Players[player].Keyframes[keyframeId]
        local modnames = player == keyframe.Entity and {"world"} or SMH.Properties.Players[player].TimelineSetting.TimelineMods[timeline]

        local EaseIn, EaseOut, Mods = {}, {}, {}
        for _, name in ipairs(modnames) do
            if not keyframe.Modifiers[name] then continue end
            EaseIn[name] = keyframe.EaseIn[name]
            EaseOut[name] = keyframe.EaseOut[name]
            if istable(keyframe.Modifiers[name]) then
                Mods[name] = table.Copy(keyframe.Modifiers[name]) -- in case if we copy things like world keyframes
            else
                Mods[name] = keyframe.Modifiers[name]
            end
        end

        local copiedKeyframe = SMH.KeyframeData:New(player, keyframe.Entity)
        copiedKeyframe.EaseIn = EaseIn
        copiedKeyframe.EaseOut = EaseOut
        copiedKeyframe.Modifiers = Mods

        movingkeyframes[copiedKeyframe] = frame[id]
    end

    for keyframe, frame in pairs(movingkeyframes) do
        local replacekey = GetExistingKeyframe(player, keyframe.Entity, frame)

        if replacekey ~= nil and not movingkeyframes[replacekey] then
            for name, data in pairs(replacekey.Modifiers) do
                if not keyframe.Modifiers[name] then
                    keyframe.Modifiers[name] = data
                    keyframe.EaseIn[name] = replacekey.EaseIn[name]
                    keyframe.EaseOut[name] = replacekey.EaseOut[name]
                end
            end
            SMH.KeyframeData:Delete(player, replacekey.ID)
        end

        keyframe.Frame = frame
        table.insert(copiedKeyframes, keyframe)
        --KEYFRAME COPY
        --print("keyframe " .. frame .. " copied")
    end

    return copiedKeyframes
end

function MGR.Delete(player, keyframeId, timeline)

    SMH.GLOBAL_isOrgKeysNeeded = true --global keyframe organizer bool

    if not SMH.KeyframeData.Players[player] or not SMH.KeyframeData.Players[player].Keyframes[keyframeId] then
        error("Invalid keyframe ID")
    end

    local entity = SMH.KeyframeData.Players[player].Keyframes[keyframeId].Entity

    local keyframe = SMH.KeyframeData.Players[player].Keyframes[keyframeId]
    local modnames = player == keyframe.Entity and {"world"} or SMH.Properties.Players[player].TimelineSetting.TimelineMods[timeline]

    for _, name in ipairs(modnames) do
        ClearModifier(keyframe, name)
    end

    if not next(keyframe.Modifiers) then
        SMH.KeyframeData:Delete(player, keyframeId)
        --KEYFRAME DELETE
        --print("keyframe " .. keyframe.Frame .. " deleted")
    end
    return entity
end

function MGR.ImportSave(player, entity, serializedKeyframes, entityProperties)

    SMH.GLOBAL_isOrgKeysNeeded = true

    if SMH.KeyframeData.Players[player] and SMH.KeyframeData.Players[player].Entities[entity] then
        local deletethis = table.Copy(SMH.KeyframeData.Players[player].Entities[entity])
        for _, keyframe in pairs(deletethis) do
            SMH.KeyframeData:Delete(player, keyframe.ID)
        end
    end

    SMH.PropertiesManager.SetProperties(player, entity, entityProperties)

    for _, skf in pairs(serializedKeyframes) do
        local keyframe = GetExistingKeyframe(player, entity, skf.Position) -- check for SMH 3.0 save stuff as it has a system with multiple keyframes occupying same frame

        if keyframe ~= nil then
            for name, _ in pairs(skf.EntityData) do
                keyframe.EaseIn[name] = type(skf.EaseIn) == "table" and skf.EaseIn[name] or skf.EaseIn
                keyframe.EaseOut[name] = type(skf.EaseOut) == "table" and skf.EaseOut[name] or skf.EaseOut
                keyframe.Modifiers[name] = skf.EntityData[name]
                --KEYFRAME IMPORT
                --print("keyframe NOT NIL in " .. skf.Position .. " imported")
            end
        else
            local keyframe = SMH.KeyframeData:New(player, entity)
            keyframe.Frame = skf.Position
            for name, _ in pairs(skf.EntityData) do
                keyframe.EaseIn[name] = type(skf.EaseIn) == "table" and skf.EaseIn[name] or skf.EaseIn
                keyframe.EaseOut[name] = type(skf.EaseOut) == "table" and skf.EaseOut[name] or skf.EaseOut
                keyframe.Modifiers[name] = skf.EntityData[name]
                --KEYFRAME IMPORT
                --print("keyframe in " .. skf.Position .. " imported")
                
            end
        end
    end
end

function MGR.GetWorldData(player, frame)
    local keyframe = GetExistingKeyframe(player, player, frame, {"world"})
    local modifiers = keyframe.Modifiers["world"]

    return modifiers.Console, modifiers.Push, modifiers.Release
end

function MGR.UpdateWorldKeyframe(player, frame, str, key)
    local keyframe = GetExistingKeyframe(player, player, frame, {"world"})
    if not keyframe then return end
    keyframe.Modifiers["world"][key] = str
end





SMH.KeyframeManager = MGR
