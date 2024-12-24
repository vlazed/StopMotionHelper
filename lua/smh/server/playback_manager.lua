local ActivePlaybacks = {}

local MGR = {}

allFrames_actualFrame = 0

local function lerpmult(frames, frame)
    n = #frames
    local lerpMultiplier = 0
    local band = frames[n] - frames[1]
    --print("keyexportframes= ", keyframesexport[1].Frame, keyframesexport[#keyframesexport].Frame, band)
    if band ~= 0 then
        lerpMultiplier = (frame - frames[1]) / (frames[n] - frames[1])
        --lerpMultiplier = math.EaseInOut(lerpMultiplier, keyframesexport[1].EaseOut[modname], keyframesexport[#keyframesexport].EaseIn[modname])
    else 
        lerpMultiplier = 0
    end

    return lerpMultiplier
end

function printTable(tbl, indent)
    if not tbl then return "tbl null" end
    indent = indent or 0
    local indentStr = string.rep("  ", indent)

    for key, value in pairs(tbl) do
        if type(key) == "number" then
            key = "[" .. key .. "]"
        end
        if type(value) == "table" then
            print(indentStr .. tostring(key) .. " = {")
            printTable(value, indent + 1)  -- Recursión para tablas anidadas
            print(indentStr .. "}")
        else
            if type(value) == "string" then
                print(indentStr .. key .. ' = "' .. value .. '"')
            else
                print(indentStr .. key .. " = " .. tostring(value))
            end
        end
    end
end


local function PlaybackSmooth(player, playback, settings)
    if not SMH.KeyframeData.Players[player] then
        return
    end
    if SMH.GLOBAL_isOrgKeysNeeded then
        SMH.KeyframeManager.OrganizeKeyframes(player)
        SMH.GLOBAL_isOrgKeysNeeded = false
        print("OrgKeysbool activado")
    end

    

    playback.Timer = playback.Timer + FrameTime()
    local timePerFrame = 1 / playback.PlaybackRate

    playback.CurrentFrame = playback.Timer / timePerFrame + playback.StartFrame
    if playback.CurrentFrame > playback.EndFrame then
        playback.CurrentFrame = 0
        playback.StartFrame = 0
        playback.Timer = 0
    end

    for entity, keyframes in pairs(SMH.KeyframeData.Players[player].Entities) do
        if entity ~= player then

            local allFrames = {}
            for k, v in pairs(keyframes) do
                table.insert(allFrames, v.Frame)
            end
            table.sort(allFrames)

            for name, mod in pairs(SMH.Modifiers) do
                local prevKeyframe, nextKeyframe, _ = SMH.GetClosestKeyframes(keyframes, playback.CurrentFrame, false, name)

                if not prevKeyframe then continue end

                local modkeys = {}
                modkeys["Keydata"] = SMH.KeyframeData.Players[player].Modkeys.Entities[entity].ModData[name]
                modkeys["Frames"] = SMH.KeyframeData.Players[player].Modkeys.Entities[entity].ModFrames[name]
                local lerpxd = lerpmult(allFrames, playback.CurrentFrame)
                allFrames_actualFrame = playback.CurrentFrame

                --print("lerpxd = " , lerpxd)
                --print("current frame = " , playback.CurrentFrame)


                if (next(modkeys.Frames) == nil or next(modkeys.Keydata) == nil) then
                    continue
                end




                

                mod:LoadBetween(entity, prevKeyframe.Modifiers[name], modkeys, lerpxd, settings);
                --print("hola")
                --[[
                if prevKeyframe.Frame == nextKeyframe.Frame then
                    if prevKeyframe.Modifiers[name] and nextKeyframe.Modifiers[name] then
                        mod:Load(entity, prevKeyframe.Modifiers[name], settings);
                    end
                else
                    local lerpMultiplier = ((playback.Timer + playback.StartFrame * timePerFrame) - prevKeyframe.Frame * timePerFrame) / ((nextKeyframe.Frame - prevKeyframe.Frame) * timePerFrame)
                    lerpMultiplier = math.EaseInOut(lerpMultiplier, prevKeyframe.EaseOut[name], nextKeyframe.EaseIn[name])

                    if prevKeyframe.Modifiers[name] and nextKeyframe.Modifiers[name] then
                        --mod:LoadBetween(entity, prevKeyframe.Modifiers[name], nextKeyframe.Modifiers[name], lerpMultiplier, settings);
                        
                        local modkeys = {}
                        modkeys["Keydata"] = SMH.KeyframeData.Players[player].Modkeys.Entities[entity].ModData[name]
                        modkeys["Frames"] = SMH.KeyframeData.Players[player].Modkeys.Entities[entity].ModFrames[name]
                        local lerpxd = lerpmult(allFrames, playback.CurrentFrame)

                        --print("lerpxd = " , lerpxd)
                        --print("current frame = " , playback.CurrentFrame)


                        if (next(modkeys.Frames) == nil or next(modkeys.Keydata) == nil) then
                            continue
                        end

                        mod:LoadBetween(entity, prevKeyframe.Modifiers[name], modkeys, lerpxd, settings);
                    end
                end
                ]]
            end
        else
            if settings.EnableWorld then
                SMH.WorldKeyframesManager.Load(player, math.Round(playback.CurrentFrame), keyframes)
            end
        end
    end
end
--[[]]
function tprintxd (tbl, indent)
    if not indent then indent = 0 end
    local toprint = string.rep(" ", indent) .. "{\r\n"
    indent = indent + 2 
    for k, v in pairs(tbl) do
      toprint = toprint .. string.rep(" ", indent)
      if (type(k) == "number") then
        toprint = toprint .. "[" .. k .. "] = "
      elseif (type(k) == "string") then
        toprint = toprint  .. k ..  "= "   
      end
      if (type(v) == "number") then
        toprint = toprint .. v .. ",\r\n"
      elseif (type(v) == "string") then
        toprint = toprint .. "\"" .. v .. "\",\r\n"
      elseif (type(v) == "table") then
        toprint = toprint .. tprint(v, indent + 2) .. ",\r\n"
      else
        toprint = toprint .. "\"" .. tostring(v) .. "\",\r\n"
      end
    end
    toprint = toprint .. string.rep(" ", indent-2) .. "}"
    return toprint
end



function printTablepedorro(tbl)
    --hacer un bucle que imprima solo los indices de la tabla
    local pp = ""
    if tbl[0] then
        pp = "0,"
    end
    for key, value in pairs(tbl) do
        --print(key)
        pp = pp .. key .. ","
    end
    print(pp)
end

function keyframesmodprint(frames, modname)

    if frames[0] then print("si hay 0 ") end
    
    for k, v in pairs(frames) do
        print("[" .. k .. "]")
        if v.ID then print("    ID = " .. v.ID) end
        if v.Frame then print("    Frame = " .. v.Frame) end
        if v.Modifiers[modname] then
            
            if type(v.Modifiers[modname]) == "table" then
                print("    " .. modname .. " = ")
                for keyx, valuex in pairs(v.Modifiers[modname]) do
                    print("     " , keyx , " = " , valuex)
                end
            else
                print("    " .. modname .. " = ".. v.Modifiers[modname])
            end

        else
            -- modifiers
            print("    Modifiers = ")
            for keyz, valuez in pairs(v.Modifiers) do

                if type(valuez) == "table" then
                    print("     " , keyz , " = " , valuez, "size = " , #valuez)
                else
                    print("     " , keyz , " = " , valuez)
                end

                --print("     " , keyz , " = " , printTable(valuez))
            end
        end
    end
end

-- Ejemplo de uso
local exampleTable = {
    name = "ChatGPT",
    age = 2024,
    skills = {
        programming = "Lua",
        ai = "Conversational AI",
        hobbies = {"Reading", "Coding", "Music"}
    }
}

printTable(exampleTable)





function MGR.SetFrame(player, newFrame, settings)
    if not SMH.KeyframeData.Players[player] then
        return
    end
    if SMH.GLOBAL_isOrgKeysNeeded then
        SMH.KeyframeManager.OrganizeKeyframes(player)
        SMH.GLOBAL_isOrgKeysNeeded = false
        print("OrgKeysbool activado")
    end

    for entity, keyframes in pairs(SMH.KeyframeData.Players[player].Entities) do
        if entity ~= player then
            --print(tprint())
            local allFrames = {}

            for k, v in pairs(keyframes) do
                table.insert(allFrames, v.Frame)
            end

            table.sort(allFrames)

            --allFrames_lastFrame = allFrames[#allFrames]
            allFrames_actualFrame = newFrame


            for name, mod in pairs(SMH.Modifiers) do
                --local prevKeyframe, allKeyframes, lerpMultiplier = SMH.GetClosestKeyframes(keyframes, newFrame, false, name)
                local modKeyframes = {}
                local modkeys = {}
                local framez = {}
                local kfcopia = {}
                local lerpMultiplier = 0

                --print("LE NAME = " , name)



                modkeys["Keydata"] = SMH.KeyframeData.Players[player].Modkeys.Entities[entity].ModData[name]
                modkeys["Frames"] = SMH.KeyframeData.Players[player].Modkeys.Entities[entity].ModFrames[name]

                --print("NAME = " , name)
                --print(" ")
                -- print tabla modkeys
                --print(printTable(modkeys))

                if (next(modkeys.Frames) == nil or next(modkeys.Keydata) == nil) then
                    continue
                end

                --lerpMultiplier = lerpmult(modkeys.Frames, newFrame)
                lerpMultiplier = lerpmult(allFrames, newFrame)

                local frames = modkeys.Frames
                local fn = #frames
                local scaledT = allFrames_actualFrame
                local index
                local localT
                local t = lerpMultiplier

                --scaledT = t * (frames[#frames] - frames[1])

                
                --[[ 
                index = 1
                local fn = #frames

                for i = 1, fn do
                    
                   
                    if i == fn then
                        --bi = #frames
                        index = fn
                        break
                    end
                    


                    if scaledT >= frames[i] and scaledT < frames[i+1] then
                        index = i  -- Restar 1 para compensar el inicio desde 0
                        break
                    end
                    
                    print("frames[i] = " , frames[i])
                    if scaledT == frames[i] then
                        index = i - 1  -- Restar 1 para compensar el inicio desde 0
                        break
                    end

                    if scaledT > frames[i] then
                        index = i - 2  -- Restar 1 para compensar el inicio desde 0
                        break
                    end
                    
                end
                ]]
                --print(printTable(modkeys.Keydata))


                --print("mod = ", mod)
                
                
                --print("lerpMultiplier = " , lerpMultiplier)

                --print(printTablepedorro(keyframes))

                --//FOR NUEVO COSAS NUEVAS
                --[[ ]]
                kfcopia = keyframes

                table.sort(kfcopia, function(a, b) return a.Frame < b.Frame end)

                --[[
                for i=1, #kfcopia do
                    if kfcopia[i].Modifiers[name] then
                        --print("keyframe modname = " , name)
                        --print("frame = " , kfcopia[i].Frame)
                        table.insert(modKeyframes, kfcopia[i].Modifiers[name])
                        --table.insert(framez, keyframes[i].Frame)
                    end
                end
                ]]

                --local prev1 = modKeyframes[1]
                --local last1 = modKeyframes[#modKeyframes]
                
                local prev1
                local last1 

                if kfcopia[1].Modifiers[name] then
                    prev1 = kfcopia[1].Modifiers[name]
                else 
                    prev1 = kfcopia[2].Modifiers[name]
                end

                if kfcopia[#kfcopia].Modifiers[name] then
                    last1 = kfcopia[#kfcopia].Modifiers[name]
                else 
                    last1 = kfcopia[#kfcopia-1].Modifiers[name]
                end

                local lerpbool1 = true
                local lerpbool2 = false
                local keysolo = prev1


                if (lerpMultiplier <= 0 or settings.TweenDisable) and lerpbool1 then
                    --[[
                    if prev1 ~= nil then
                        mod:Load(entity, prev1, settings);
                    else
                        mod:Load(entity, last1, settings);
                    end  
                    ]]

                    prev1, _ , _ = SMH.GetClosestKeyframes(keyframes, newFrame, false, name)
                    --[[
                    index = 0
                    for i = 1, fn - 1 do
                        if scaledT >= frames[i] and scaledT <= frames[i + 1] then
                            index = i  -- Restar 1 para compensar el inicio desde 0
                            --firstFrame = frames[i]
                            --lastFrame = frames[i + 1]
                            
                            break
                        end
                    end

                    prev1 = kfcopia[index].Modifiers[name]
                    ]]
                    --print("previo = " , previo)
                    --print(printTable(previo))

                    mod:Load(entity, prev1.Modifiers[name], settings);
                    
                    
                    
                elseif (lerpMultiplier >= 1) and lerpbool2 then       
                    if last1 ~= nil then
                        mod:Load(entity, last1, settings);
                    else
                        mod:Load(entity, prev1, settings);
                        --mod:Load(entity, last1, settings);
                    end 
                    
                
                else

                    if prev1 == nil then
                        keysolo = last1
                    end

                    if last1 == nil then
                        keysolo = prev1
                    end

                    mod:LoadBetween(entity, keysolo, modkeys, lerpMultiplier, settings);
                end
            end
        else
            if settings.EnableWorld then
                SMH.WorldKeyframesManager.Load(player, newFrame, keyframes)
            end
        end
    end
end

function MGR.SetFrameIgnore(player, newFrame, settings, ignored)
    if not SMH.KeyframeData.Players[player] then
        return
    end


    for entity, keyframes in pairs(SMH.KeyframeData.Players[player].Entities) do
        if ignored[entity] then continue end


        local allFrames = {}

        for k, v in pairs(keyframes) do
            table.insert(allFrames, v.Frame)
        end

        table.sort(allFrames)
        allFrames_actualFrame = newFrame


        for name, mod in pairs(SMH.Modifiers) do

            local prevKeyframe, _ , _ = SMH.GetClosestKeyframes(keyframes, newFrame, false, name)
            local modkeys = {}
            local lerpMultiplier = 0

            modkeys["Keydata"] = SMH.KeyframeData.Players[player].Modkeys.Entities[entity].ModData[name]
            modkeys["Frames"] = SMH.KeyframeData.Players[player].Modkeys.Entities[entity].ModFrames[name]

            if (next(modkeys.Frames) == nil or next(modkeys.Keydata) == nil) then
                continue
            end

            lerpMultiplier = lerpmult(allFrames, newFrame)

            mod:LoadBetween(entity, prevKeyframe.Modifiers[name], modkeys, lerpMultiplier, settings);

        end
    end
end


function MGR.StartPlayback(player, startFrame, endFrame, playbackRate, settings)
    ActivePlaybacks[player] = {
        StartFrame = startFrame,
        EndFrame = endFrame,
        PlaybackRate = playbackRate,
        CurrentFrame = startFrame,
        PrevFrame = startFrame - 1,
        Timer = 0,
        Settings = settings,
    }

    print("Playback Started!")
    MGR.SetFrame(player, startFrame, settings)
end

function MGR.StopPlayback(player)
    ActivePlaybacks[player] = nil
end

hook.Add("Think", "SMHPlaybackManagerThink", function()
    for player, playback in pairs(ActivePlaybacks) do
        if not playback.Settings.SmoothPlayback or playback.Settings.TweenDisable then

            playback.Timer = playback.Timer + FrameTime()
            local timePerFrame = 1 / playback.PlaybackRate

            if playback.Timer >= timePerFrame then

                playback.CurrentFrame = math.floor(playback.Timer / timePerFrame) + playback.StartFrame
                if playback.CurrentFrame > playback.EndFrame then
                    playback.CurrentFrame = 0
                    playback.StartFrame = 0
                    playback.Timer = 0
                end

                if playback.CurrentFrame ~= playback.PrevFrame then
                    playback.PrevFrame = playback.CurrentFrame
                    MGR.SetFrame(player, playback.CurrentFrame, playback.Settings)
                end

            end
        else
            PlaybackSmooth(player, playback, playback.Settings)
        end
    end
end)

SMH.PlaybackManager = MGR
