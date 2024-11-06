local MGR = {}



function MGR.Create(path, frame, startTime, duration)
	
    local audioclips = {}
	
	sound.PlayFile( path, "noplay noblock", function( station, errCode, errStr )
		if ( IsValid( station ) ) then
			local startTime = startTime or 0
			local duration = duration or station:GetLength()-startTime
			
			local audioclip = SMH.AudioClipData:New(station, path)
			audioclip.Frame = frame
			audioclip.Duration = duration
			audioclip.StartTime = startTime
			
			station:SetTime(startTime)
			station:EnableLooping(false)
			
			print( "SMH Audio: Loaded from '"..path.."'")
			
			SMH.Controller.UpdateServerAudio()
			SMH.UI.CreateAudioClipPointer(audioclip)
		else
			print( "SMH Audio: Error loading file!", errCode, errStr )
		end
	end )

	table.insert(audioclips, audioclip)
    return audioclips
end

function MGR.TrimStart(id, frame)
	//get time between start frame and target frame
	//set start time
	//subtract time from duration
	//move start frame to target frame
end

function MGR.TrimEnd(id, frame)
	//get time between start frame and target frame
	//modify duration of clip based on frame input
end

SMH.AudioClipManager = MGR