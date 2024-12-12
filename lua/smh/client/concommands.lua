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

concommand.Add("+smh_playback", function()
    SMH.Controller.StartPlayback()
end, nil, "Start SMH playback relative to the playhead at the framerate specified by the user. Note that this does not move the playhead")

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
            startframe = args[1] - GetConVar("smh_startatone"):GetInt()
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
            startframe = args[1] - GetConVar("smh_startatone"):GetInt()
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

CreateClientConVar("smh_startatone", "0", true, false, "Whether the starting frame should start at 0 or 1", 0, 1)
CreateClientConVar("smh_currentpreset", "default", true, false, "Use the timeline setting that defines the number of timelines and what modifier each timeline controls")
CreateClientConVar("smh_motionpathbone", "", true, true, "Set the bone that the motion path will track")
CreateClientConVar("smh_motionpathrange", "0", true, true, "Set how many nodes to show around the current frame. 1 means show 2 nodes on the left and right of the current frame.", 0)
CreateClientConVar("smh_motionpathsize", "1", true, true, "Set the size of the nodes in the motion path", 0)
