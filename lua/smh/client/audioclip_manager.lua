local MGR = {}

---@type {[string]: Wave[]}
local Waveforms = {}

local SAMPLE_INTERVAL = 0.001

---@param path string
---@param startTime number
local function GenerateWaveform(path, startTime)
	if Waveforms[path] then
		return Waveforms[path]
	end

	Waveforms[path] = {}
	sound.PlayFile(path, "noplay noblock", function(audioChannel)
		audioChannel:SetVolume(0)
		audioChannel:Play()
		local timerId = "SMH_WaveformGenerator_" .. path
		timer.Create(timerId, SAMPLE_INTERVAL, audioChannel:GetLength() / SAMPLE_INTERVAL, function()
			local left, right = audioChannel:GetLevel()
			local fraction = audioChannel:GetTime() / audioChannel:GetLength()
			table.insert(Waveforms[path], {
				Left = left,
				Right = right,
				Fraction = fraction
			})
		end)
		timer.Start(timerId)
		timer.Simple(audioChannel:GetLength() + 0.1, function()
			audioChannel:SetVolume(1)
			audioChannel:SetTime(startTime)
			timer.Remove(timerId)
		end)
	end)

	return Waveforms[path]
end

function MGR.GetWaveforms()
	return Waveforms
end

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
			audioclip.Waveform = GenerateWaveform(path, startTime)
			
			print( "SMH Audio: Loaded from '"..path.."'")
			
			SMH.Controller.UpdateServerAudio()
			SMH.UI.CreateAudioClipPointer(audioclip)

			table.insert(audioclips, audioclip)
		else
			print( "SMH Audio: Error loading file!", errCode, errStr )
		end
	end )

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