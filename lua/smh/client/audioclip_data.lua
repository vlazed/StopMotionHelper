local META = {}
META.__index = META

function META:New(station, path)
	if not self.AudioClips then
		self.AudioClips = {}
	end
	
    local audioClip = {
        ID = self.NextKeyframeId,
		Path = path,
		AudioChannel = station,
        Frame = -1,
        Duration = 1,
		StartTime = 0
    }
    self.NextKeyframeId = self.NextKeyframeId + 1

    self.AudioClips[audioClip.ID] = audioClip

    return audioClip
end

function META:Delete(id)
    if not self.AudioClips[id] then
        return
    end
	self.AudioClips[id].AudioChannel:Stop()
    self.AudioClips[id] = nil
end

function META:DeleteAll()
	for k,v in pairs(self.AudioClips) do
		self:Delete(v.ID)
	end
end

SMH.AudioClipData = {
	AudioClips = {},
    NextKeyframeId = 0
}
setmetatable(SMH.AudioClipData, META)
