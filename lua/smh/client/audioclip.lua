local AUD = {}

local function GetAudioChannelByID(id)
	if SMH.AudioClipData.AudioClips[id] then
		return SMH.AudioClipData.AudioClips[id].AudioChannel
	end
end

local function GetAudioClipData(id)
	if SMH.AudioClipData.AudioClips[id] then
		return SMH.AudioClipData.AudioClips[id]
	end
end


// Audio channel start/stop

function AUD.Play(id, startTime)
	local audioChannel = GetAudioChannelByID(id)
	local audioData = GetAudioClipData(id)
	
	startTime = startTime or audioData.StartTime
	
	if startTime ~= audioData.StartTime then
		audioChannel:SetTime(startTime)
	end
	
	audioChannel:Play()
end

function AUD.Stop(id, rewind)
	rewind = rewind or true
	
	local audioChannel = GetAudioChannelByID(id)
	local audioData = GetAudioClipData(id)
	audioChannel:Pause()
	if rewind then
		audioChannel:SetTime(audioData.StartTime)
	end
end

function AUD.StopAll()
	if SMH.AudioClipData.AudioClips then
		for i,clip in pairs(SMH.AudioClipData.AudioClips) do
			AUD.Stop(clip.ID)
		end
	end
end

/* function AUD.Destroy(id)
	local audioChannel = GetAudioChannelByID(id)
	audioChannel:Stop()
end */

SMH.AudioClip = AUD