local SMHRecorderID = "SMH_Recording_Timer"

local MGR = {}

---@param player Player
---@param entities Entities
---@param timelines any
---@param frame integer
local function RecordPhys(player, entities, timelines, frame)
    SMH.PropertiesManager.AddEntity(player, entities)

    for _, entity in ipairs(entities) do
        local totaltimelines = SMH.PropertiesManager.GetTimelines(player)
        if timelines[entity] > totaltimelines then timelines[entity] = 1 end

        SMH.KeyframeManager.Create(player, {entity}, frame, timelines[entity])
    end
end

---@param player Player
---@param framecount integer
---@param interval integer
---@param frame integer
---@param playbackrate integer
---@param endframe integer
---@param entities Entities
---@param timelines any
---@param settings Settings
function MGR.RecordStart(player, framecount, interval, frame, playbackrate, endframe, entities, timelines, settings)
    if framecount < 3 then framecount = 3 end
    if interval < 0 then interval = 0 end
    local counter = -1
    RecordPhys(player, entities, timelines, frame)

    timer.Create(SMHRecorderID .. player:EntIndex(), 1 / playbackrate , framecount, function()
        counter = counter + 1

        if interval == 0 or (counter / interval) == math.Round(counter / interval)  then 
            RecordPhys(player, entities, timelines, frame)
        end

        if counter >= framecount - 1 or frame + 1 > endframe - 1  then
            RecordPhys(player, entities, timelines, frame)
            timer.Remove(SMHRecorderID .. player:EntIndex())
            player:ChatPrint( "SMH Physics Recorder stopped.")
            SMH.Controller.StopPhysicsRecordResponse(player)
        else
            frame = frame + 1
            SMH.PlaybackManager.SetFrameIgnore(player, frame, settings, timelines)
        end
    end)

end

---@param player Player
function MGR.RecordStop(player)
    timer.Remove(SMHRecorderID .. player:EntIndex())
    player:ChatPrint( "SMH Physics Recorder stopped.")
end

SMH.PhysRecord = MGR
