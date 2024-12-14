local MGR = {}

local Waveforms = {}
local WAVE_GENERATOR_ID = "SMH_WaveformGenerator_"
local SAMPLE_INTERVAL = 0.001

local function GenerateWaveform(path)
	if Waveforms[path] then
		return Waveforms[path]
	end

	Waveforms[path] = {}
	sound.PlayFile(path, "noplay noblock", function(audioChannel)
		-- We can sample the levels from an audio clip even if the volume is set to low
		audioChannel:SetVolume(0)
		audioChannel:EnableLooping(false)
		audioChannel:Play()
		local timerId = WAVE_GENERATOR_ID .. path
		timer.Create(timerId, SAMPLE_INTERVAL, audioChannel:GetLength() / SAMPLE_INTERVAL, function()
			local left, right = audioChannel:GetLevel()
			-- The fraction decouples from the time unit, allowing the waveform to fit the width of an audioclip_pointer
			local fraction = audioChannel:GetTime() / audioChannel:GetLength()
			table.insert(Waveforms[path], {
				Left = left,
				Right = right,
				Fraction = fraction
			})
		end)
		timer.Start(timerId)
		-- Stop sampling at the end of the audio track
		timer.Simple(audioChannel:GetLength() + 0.1, function()
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
			audioclip.Waveform = GenerateWaveform(path)
			
			station:SetTime(startTime)
			station:EnableLooping(false)
			
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