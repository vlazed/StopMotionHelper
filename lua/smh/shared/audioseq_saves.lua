local SaveDir = "smh/audio/"

local MGR = {}

function MGR.ListFiles()
    local files, dirs = file.Find(SaveDir .. "*.txt", "DATA")

    local saves = {}
    for _, file in pairs(files) do
        table.insert(saves, file:sub(1, -5))
    end

    return saves
end

function MGR.Load(path)
    path = SaveDir .. path .. ".txt"
    if not file.Exists(path, "DATA") then
        error("SMH Audio: Seqeunce file does not exist: " .. path)
    end

    local json = file.Read(path)
    local serializedClips = util.JSONToTable(json)
    if not serializedClips then
        error("SMH Audio: Sequence file load failure")
    end

    return serializedClips
end

function MGR.Serialize(clips)

    local clipList = {}
	
	for k,v in pairs(clips) do
		local clip = {
			Path = v.Path,
			Frame = v.Frame,
			Duration = v.Duration,
			StartTime = v.StartTime
		}
		table.insert(clipList, clip)
	end
	
	local serializedClips = {
		PlaybackRate = SMH.State.PlaybackRate,
		PlaybackLength = SMH.State.PlaybackLength,
		Clips = clipList
	}

    return serializedClips
end

function MGR.Save(path, serializedKeyframes)
    if not file.Exists(SaveDir, "DATA") or not file.IsDir(SaveDir, "DATA") then
        file.CreateDir(SaveDir)
    end

    path = SaveDir .. path .. ".txt"
    local json = util.TableToJSON(serializedKeyframes, true)
    file.Write(path, json)
end

function MGR.CopyIfExists(pathFrom, pathTo)
    pathFrom = SaveDir .. pathFrom .. ".txt"
    pathTo = SaveDir .. pathTo .. ".txt"

    if file.Exists(pathFrom, "DATA") then
        file.Write(pathTo, file.Read(pathFrom));
    end
end

function MGR.Delete(path)
    path = SaveDir .. path .. ".txt"
    if file.Exists(path, "DATA") then
        file.Delete(path)
    end
end

SMH.AudioSeqSaves = MGR
