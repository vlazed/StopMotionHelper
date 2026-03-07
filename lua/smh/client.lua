include("shared.lua")

include("client/state.lua")

local files = file.Find("smh/client/derma/*.lua", "lcl")
for _, dermaFile in ipairs(files) do
    local success, errMsg = pcall(function ()
        include("client/derma/" .. dermaFile)
    end)
    if not success then
        ErrorNoHalt(errMsg)
    end
end

include("client/concommands.lua")
include("client/controller.lua")
include("client/highlighter.lua")
include("client/physrecord.lua")
include("client/renderer.lua")
include("client/settings.lua")
include("client/ui.lua")
include("client/audioclip.lua")
include("client/audioclip_data.lua")
include("client/audioclip_manager.lua")
