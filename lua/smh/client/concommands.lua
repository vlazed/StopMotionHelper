local smh_startatone = CreateClientConVar("smh_startatone", "0", true, false, nil, 0, 1)
CreateClientConVar("smh_currentpreset", "default", true, false)
CreateClientConVar("smh_motionpathbone", "", true, true, "Set the bone that the motion path will track")
CreateClientConVar("smh_motionpathrange", "0", true, false, "Set how many nodes to show around the current frame. 1 means show 2 nodes on the left and right of the current frame.", 0)
CreateClientConVar("smh_motionpathsize", "1", true, false, "Set the size of the nodes in the motion path", 0)
CreateClientConVar("smh_motionpathoffset", "0 0 0", true, false, "Set the size of the nodes in the motion path")
CreateClientConVar("smh_majortickinterval", "10", true, false, "Set the interval for the ticks on the frame panel", 4, 16)
local autosaveTime = CreateClientConVar("smh_autosavetime", "5", true, false, "Set the autosave interval in minutes. Set to 0 to disable", 0)
cvars.AddChangeCallback("smh_autosavetime", function (convar, oldValue, newValue)
    newValue = tonumber(newValue)
    if not newValue or not isnumber(newValue) then
        local val = tonumber(oldValue)
        ---@cast val number
        autosaveTime:SetFloat(val)
        return
    end

    if timer.Exists("SMH_Autosave_Timer") then
        timer.Pause("SMH_Autosave_Timer")
        if newValue > 0 then
            timer.Adjust("SMH_Autosave_Timer", newValue * 60)
            timer.UnPause("SMH_Autosave_Timer")
        end
    end
end)

concommand.Add("+smh_menu", function()
    SMH.Controller.OpenMenu()
end)

-- Helper functions for incrementing the playhead position on the timeline

---@param n Falsy<integer>?
local function nextFrame(n)
	n = n or 1
	local pos = SMH.State.Frame + n
    if pos >= SMH.State.PlaybackLength then
        pos = 0
    end
    SMH.Controller.SetFrame(pos)
end

---@param n Falsy<integer>?
local function previousFrame(n)
	n = n or 1
	local pos = SMH.State.Frame - n
    if pos < 0 then
        pos = SMH.State.PlaybackLength - n
    end
    SMH.Controller.SetFrame(pos)
end


concommand.Add("+smh_menu", function()
    SMH.Controller.OpenMenu()
end, nil, "Open the SMH Timeline")

concommand.Add("-smh_menu", function()
    SMH.Controller.CloseMenu()
end, nil, "Close the SMH Timeline")

concommand.Add("smh_record", function(_, _, args)
    local frame = tonumber(args[1]) or SMH.State.Frame
    SMH.Controller.Record(frame)
end, nil, "Record a keyframe on the SMH timeline")

concommand.Add("smh_delete", function()
	local frame = SMH.State.Frame
	local ids = SMH.UI.GetKeyframesOnFrame(frame)
	if not ids then return end
    SMH.Controller.DeleteKeyframe(ids)
end)

do
    ---@param command string
    ---@return string[]
    local function suggestFrames(command)
        local options = {
            command
        }
        for i = 2, 4 do
            table.insert(options, command .. ' ' .. tostring(i))
        end
        return options
    end

    concommand.Add("smh_next", function(_, _, _, argStr) 
        local n = tonumber(argStr)
        nextFrame(isnumber(n) and math.Round(math.abs(n)))
    end, suggestFrames, "Increment the playhead by n, where n is a whole number. If not specified, increment by 1")

    concommand.Add("smh_previous", function(_, _, _, argStr) 
        local n = tonumber(argStr)
        previousFrame(isnumber(n) and math.Round(math.abs(n)))
    end, suggestFrames, "Decrement the playhead by n, where n is a whole number. If not specified, decrement by 1")
end

concommand.Add("smh_nextframe", function()
    local pos = SMH.State.Frame
    for i=pos+1, SMH.State.PlaybackLength, 1 do
        if SMH.UI.IsFrameKeyframe(i) then
            SMH.Controller.SetFrame(i)
            return
        end
    end
end, nil, "Jumps the playhead to the next, immediate keyframe on the timeline, relative to the playhead")

concommand.Add("smh_previousframe", function()
    local pos = SMH.State.Frame
    for i=pos-1, 0, -1 do
        if SMH.UI.IsFrameKeyframe(i) then
            SMH.Controller.SetFrame(i)
            return
        end
    end
end, nil, "Jumps the playhead to the previous, immediate keyframe on the timeline, relative to the playhead")

concommand.Add("+smh_playback", function(_, _, args)
    local start = #args > 1 and tonumber(args[1]) or SMH.State.Frame
    SMH.Controller.StartPlayback(math.floor(start))
end, nil, "Start SMH playback relative to the playhead at the framerate specified by the user. Note that this does not move the playhead. If a number is specified, it will start playback at that frame")

concommand.Add("-smh_playback", function()
    SMH.Controller.StopPlayback()
end, nil, "Stop SMH playback")

concommand.Add("smh_quicksave", function()
    SMH.Controller.QuickSave()
end)

concommand.Add("smh_smooth", function(_, _, args)
    local passes = tonumber(args[1]) or 1

    local selected = SMH.UI.GetSelected()
    local frames = {}
    if next(selected) then
        for _, panel in pairs(selected) do
            table.insert(frames, panel:GetFrame())
            SMH.UI.ToggleSelect(panel)
        end
        table.sort(frames)
    elseif SMH.UI.IsFrameKeyframe(SMH.State.Frame) then
        frames = {SMH.State.Frame}
    end

    SMH.Controller.Smooth(frames, passes)
    
end, nil, "Apply additional keyframes to produce a smoother result", nil)

concommand.Add("smh_smoothall", function(_, _, args)
    local passes = tonumber(args[1]) or 1
    local keyframes = {}
    for i = 0, SMH.State.PlaybackLength, 1 do
        if SMH.UI.IsFrameKeyframe(i) then
            table.insert(keyframes, i)
        end
    end
    SMH.Controller.Smooth(keyframes, passes)
end, nil, "Apply smoothing to all keyframes", nil)

do
    local function suggestStartingFrame(command)
        return {
            command,
            command .. ' ' .. tostring(SMH.State.Frame)
        }
    end

    concommand.Add("smh_makejpeg", function(pl, cmd, args)
        local startframe
        if args[1] then
            startframe = args[1] - smh_startatone:GetInt()
        else
            startframe = 0
        end
        if startframe < 0 then startframe = 0 end
        if startframe < SMH.State.PlaybackLength then
            SMH.Controller.ToggleRendering(false, startframe)
        else
            print("Specified starting frame is outside of the current Frame Count!")
        end
    end, suggestStartingFrame, "Generate a jpeg sequence containing all the frames in the SMH Timeline. Accepts a whole number between 0 and the current frame count to offset the jpeg sequence")
    
    concommand.Add("smh_makescreenshot", function(pl, cmd, args)
        local startframe
        if args[1] then
            startframe = args[1] - smh_startatone:GetInt()
        else
            startframe = 0
        end
        if startframe < 0 then startframe = 0 end
        if startframe < SMH.State.PlaybackLength then
            SMH.Controller.ToggleRendering(true, startframe)
        else
            print("Specified starting frame is outside of the current Frame Count!")
        end
    end, suggestStartingFrame, "Generate a tga sequence containing all the frames in the SMH Timeline. Accepts a whole number between 0 and the current frame count to offset the jpeg sequence")
end
