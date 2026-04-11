include("smh/modifiers/bodytemplate.lua")

local modName = "rootphysics"
local refreshBody
do
    local directory = Format("smh_%s/", modName)
    function refreshBody()
        local files = file.Find(Format("%s/*.txt", directory), "DATA")
        for _, f in ipairs(files) do 
            local list = file.Read(Format("%s/%s", directory, f), "DATA")
            if list then
                for _, item in ipairs(string.Split(list, '\n')) do
                    table.insert(MOD.BodyEnds, string.TrimRight(item))
                end
            end
        end
    end
    concommand.Add(Format("smh_%s_refresh", modName), function (ply, cmd, args, argStr)
        refreshBody()
    end)
    refreshBody()

    local function initializeDirectory()
        if not file.IsDir(directory, "DATA") then
            file.CreateDir(directory)
        end
        local path = Format("%s/%s", directory, "valve.txt")
        if not file.Read(path) then
            local s = "ValveBiped.Bip01_Pelvis\nbip_pelvis"
            file.Write(path, s)
        end
    end
    initializeDirectory()
end

MOD.Name = "Root Physics"
MOD.SetRoot = true
