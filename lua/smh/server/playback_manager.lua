---@type table<Player, Playback>
local ActivePlaybacks = {}

local MGR = {}

local check = SMH.SettingsManager.CheckSetting
local getSetting = SMH.SettingsManager.GetSetting

local getBetweenKeyframes = SMH.GetBetweenKeyframes

---@param player Player
---@param playback Playback
---@param settings Settings
local function PlaybackSmooth(player, playback, settings)
    if not SMH.KeyframeData.Players[player] then
        return
    end

    playback.Timer = playback.Timer + FrameTime()
    local timePerFrame = playback.TimePerFrame

    playback.CurrentFrame = playback.Timer / timePerFrame + playback.StartFrame
    if playback.CurrentFrame > playback.EndFrame then
        playback.CurrentFrame = 0
        playback.StartFrame = 0
        playback.Timer = 0
    end

    local currentFrame = playback.CurrentFrame
    for entity, keyframes in pairs(SMH.KeyframeData.Players[player].Entities) do
        if entity ~= player then
            for name, mod in pairs(SMH.Modifiers) do
                local prevKeyframe, nextKeyframe = getBetweenKeyframes(keyframes, currentFrame, false, name)
                ---@cast prevKeyframe FrameData
                ---@cast nextKeyframe FrameData

                if not prevKeyframe then continue end

                local prevFrame = prevKeyframe.Frame
                local nextFrame = nextKeyframe.Frame
                local invDelta = 1 / (nextFrame - prevFrame)
                local prevData, nextData = prevKeyframe.Modifiers[name], nextKeyframe.Modifiers[name]

                if prevFrame == nextFrame then
                    if prevData and nextData then
                        mod:Load(entity, prevData, getSetting(settings, entity));
                    end
                else
                    local lerpMultiplier = (currentFrame - prevFrame) * invDelta
                    lerpMultiplier = math.EaseInOut(lerpMultiplier, prevKeyframe.EaseOut[name], nextKeyframe.EaseIn[name])

                    if lerpMultiplier <= 0 or check(settings, "TweenDisable", entity) then
                        mod:Load(entity, prevData, getSetting(settings, entity))
                    elseif prevData and nextData then
                        mod:LoadBetween(entity, prevData, nextData, lerpMultiplier, getSetting(settings, entity));
                    end
                end
            end
        else
            if check(settings, "EnableWorld", entity) then
                SMH.WorldKeyframesManager.Load(player, math.Round(currentFrame), keyframes)
            end
        end
    end
end

---@param player Player
---@param newFrame integer
---@param settings Settings
function MGR.SetFrame(player, newFrame, settings)
    if not SMH.KeyframeData.Players[player] then
        return
    end

    for entity, keyframes in pairs(SMH.KeyframeData.Players[player].Entities) do
        if entity ~= player then
            for name, mod in pairs(SMH.Modifiers) do
                local prevKeyframe, nextKeyframe, lerpMultiplier = SMH.GetClosestKeyframes(keyframes, newFrame, false, name)
                if not prevKeyframe then
                    continue
                end
                ---@cast prevKeyframe FrameData
                ---@cast nextKeyframe FrameData

                if lerpMultiplier <= 0 or check(settings, "TweenDisable", entity) then
                    mod:Load(entity, prevKeyframe.Modifiers[name], getSetting(settings, entity));
                elseif lerpMultiplier >= 1 then
                    mod:Load(entity, nextKeyframe.Modifiers[name], getSetting(settings, entity));
                else
                    mod:LoadBetween(entity, prevKeyframe.Modifiers[name], nextKeyframe.Modifiers[name], lerpMultiplier, getSetting(settings, entity));
                end
            end
        else
            if check(settings, "EnableWorld", entity) then
                SMH.WorldKeyframesManager.Load(player, newFrame, keyframes)
            end
        end
    end
end

---@param player Player
---@param newFrame integer
---@param settings Settings
---@param ignored Set<Entity>
function MGR.SetFrameIgnore(player, newFrame, settings, ignored)
    if not SMH.KeyframeData.Players[player] then
        return
    end

    for entity, keyframes in pairs(SMH.KeyframeData.Players[player].Entities) do
        if ignored[entity] then continue end
        for name, mod in pairs(SMH.Modifiers) do
            local prevKeyframe, nextKeyframe, lerpMultiplier = SMH.GetClosestKeyframes(keyframes, newFrame, false, name)
            if not prevKeyframe then
                continue
            end
            ---@cast prevKeyframe FrameData
            ---@cast nextKeyframe FrameData

            if lerpMultiplier <= 0 or check(settings, "TweenDisable", entity) then
                mod:Load(entity, prevKeyframe.Modifiers[name], getSetting(settings, entity));
            elseif lerpMultiplier >= 1 then
                mod:Load(entity, nextKeyframe.Modifiers[name], getSetting(settings, entity));
            else
                mod:LoadBetween(entity, prevKeyframe.Modifiers[name], nextKeyframe.Modifiers[name], lerpMultiplier, getSetting(settings, entity));
            end
        end
    end
end

-- AUDIO PLAYBACK CONTROL ==========
local playerAudio = {} //list of audio clips to play
local audioStopFrames = {} //which frame to stop each audio clip at
-- =================================

---@param player Player
---@param startFrame integer
---@param endFrame integer
---@param playbackRate integer
---@param settings Settings
function MGR.StartPlayback(player, startFrame, endFrame, playbackRate, settings)
    ActivePlaybacks[player] = {
        StartFrame = startFrame,
        EndFrame = endFrame,
        PlaybackRate = playbackRate,
        TimePerFrame = 1 / playbackRate,
        CurrentFrame = startFrame,
        PrevFrame = startFrame - 1,
        Timer = 0,
        Settings = settings,
    }
    MGR.SetFrame(player, startFrame, settings)
end

---@param player Player
function MGR.StopPlayback(player)
    ActivePlaybacks[player] = nil
	table.Empty(audioStopFrames) -- AUDIO: clear stop frames table when playback is stopped by user
end

-- AUDIO ================================
function MGR.UpdateServerAudio(len,ply)
	if not playerAudio[ply] then
		playerAudio[ply] = {
			audioFrames = {}
		}
	end
	local audioTable = net.ReadTable()
	if audioTable ~= nil then
		table.Empty(playerAudio[ply].audioFrames)
		playerAudio[ply].audioFrames = audioTable
		print("SMH Audio: Updated serverside list of audios")
		print(table.ToString(playerAudio, "Player Audios", true))
	else
		print("SMH Audio: Error receiving audio list from client.")
	end
end

---@param player Player
---@param playback Playback
function MGR.AudioPlayback(player, playback)
	--check for end of playback
	if playback.CurrentFrame == playback.EndFrame then
		SMH.Controller.StopAllAudio(player)
		table.Empty(audioStopFrames) --clear stop frames table when playback reaches end of timeline
		return
	end
	--check for end of clip
	if audioStopFrames[playback.CurrentFrame] then
		--stop audio
		for k,v in pairs(audioStopFrames[playback.CurrentFrame]) do
			SMH.Controller.StopAudio(v.ID, player)
		end
		table.remove(audioStopFrames,playback.CurrentFrame) --remove stop frames once playback has reached them
	end
	
	--check for start of clip
	if playerAudio[player] then
		if playerAudio[player].audioFrames[playback.CurrentFrame] ~= nil then
			for i,clip in pairs(playerAudio[player].audioFrames[playback.CurrentFrame]) do
				local audioFrame = clip
				
				--calculate end point
				local endFrame = math.ceil(playback.CurrentFrame + playback.PlaybackRate * audioFrame.Duration)
				local audioStop = {
					ID = audioFrame.ID,
					Player = player
				}
				
				--add stop frame
				if not audioStopFrames[endFrame] then
					audioStopFrames[endFrame] = {
						audioStop
					}
				else
					table.insert(audioStopFrames[endFrame], audioStop)
				end
				
				--start audio
				SMH.Controller.PlayAudio(audioFrame.ID, player)
			end
		end
	end
end
-- ======================================
local AudioPlayback = MGR.AudioPlayback

hook.Add("Think", "SMHPlaybackManagerThink", function()
    for player, playback in pairs(ActivePlaybacks) do
		AudioPlayback(player,playback) -- AUDIO PLAYBACK
		
        if not playback.Settings.SmoothPlayback or playback.Settings.TweenDisable then

            playback.Timer = playback.Timer + FrameTime()
            local timePerFrame = playback.TimePerFrame
            local playbackRate = playback.PlaybackRate

            if playback.Timer >= timePerFrame then

                playback.CurrentFrame = math.floor(playback.Timer * playbackRate) + playback.StartFrame
                if playback.CurrentFrame > playback.EndFrame then
                    playback.CurrentFrame = 0
                    playback.StartFrame = 0
                    playback.Timer = 0
                end

                if playback.CurrentFrame ~= playback.PrevFrame then
                    playback.PrevFrame = playback.CurrentFrame
                    MGR.SetFrame(player, playback.CurrentFrame, playback.Settings)
                end

            end
        else
            PlaybackSmooth(player, playback, playback.Settings)
        end
    end
end)

SMH.PlaybackManager = MGR
