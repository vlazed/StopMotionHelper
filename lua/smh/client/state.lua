local playbackRateConVar = CreateClientConVar("smh_fps", "30", true, false, "Set the playback rate (frames per second) when pressing a key bound to +smh_playback", 1)
local playbackLengthConVar = CreateClientConVar("smh_framecount", "100", true, false, "Set the length of the timeline, which makes the animation loop.", 1)
CreateClientConVar("smh_zoom", "100", true, false, "Set the visual length of the timeline.", 1)

---@type State
SMH.State = {
    Entity = {},
    Frame = 0,
    Timeline = 1,

    PlaybackRate = playbackRateConVar:GetInt(),
    PlaybackLength = playbackLengthConVar:GetInt(),
	
	EditAudioTrack = false,
    TimeStamp = RealTime() -- TODO: Use metamethods to track state changes to update this automatically
}
