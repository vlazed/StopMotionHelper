local AUD = {}

local function GetAudioChannelByID(id)
	if SMH.AudioClipData.AudioClips[id] then
		return SMH.AudioClipData.AudioClips[id].AudioChannel
	end
end

function AUD.Play(id, startTime)
	startTime = startTime or 0

	local audioChannel = GetAudioChannelByID(id)
	if startTime ~= 0 then
		audioChannel:SetTime(startTime)
	end
	audioChannel:Play()
end

function AUD.Stop(id, rewind)
	rewind = rewind or true
	
	local audioChannel = GetAudioChannelByID(id)
	audioChannel:Pause()
	if rewind then
		audioChannel:SetTime(0)
	end
end

function AUD.StopAll()
	if SMH.AudioClipData.AudioClips then
		for i,clip in pairs(SMH.AudioClipData.AudioClips) do
			AUD.Stop(clip.ID)
		end
	end
end

function AUD.Destroy(id)
	local audioChannel = GetAudioChannelByID(id)
	audioChannel:Stop()
end

SMH.AudioClip = AUD