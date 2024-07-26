local MGR = {}



function MGR.Create(path, frame)
    local audioclips = {}
	
	sound.PlayFile( path, "noplay noblock", function( station, errCode, errStr )
		if ( IsValid( station ) ) then
			station:EnableLooping(false)
			audioclip = SMH.AudioClipData:New(station, path)
			audioclip.Frame = frame
			audioclip.Duration = station:GetLength()
			print( "SMH Audio: Loaded from '"..path.."'")
			SMH.Controller.UpdateServerAudio()
		else
			print( "SMH Audio: Error loading file!", errCode, errStr )
		end
	end )

	table.insert(audioclips, audioclip)

    return audioclips
end


SMH.AudioClipManager = MGR