-- Helper functions for incrementing the playhead position on the timeline
local function nextFrame(n)
	n = n or 1
	local pos = SMH.State.Frame + n
    if pos >= SMH.State.PlaybackLength then
        pos = 0
    end
    SMH.Controller.SetFrame(pos)
end

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

concommand.Add("smh_record", function()
    SMH.Controller.Record()
end, nil, "Record a keyframe on the SMH timeline")

do
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
            SMH.UI.SetFrame(i)
            return
        end
    end
end, nil, "Jumps the playhead to the next, immediate keyframe on the timeline, relative to the playhead")

concommand.Add("smh_previousframe", function()
    local pos = SMH.State.Frame
    for i=pos-1, 0, -1 do
        if SMH.UI.IsFrameKeyframe(i) then
            SMH.UI.SetFrame(i)
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

CreateClientConVar("smh_startatone", 0, true, false, nil, 0, 1)
CreateClientConVar("smh_currentpreset", "default", true, false)
