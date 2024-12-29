local UseScreenshot = false
local IsRendering = false

CreateMaterial("SMH_XRay", "UnlitGeneric", {
	["$basetexture"] = 	"color/white",
    ["$model"] = 		1,
    ["$translucent"] = 	1,
    ["$decal"] = 	1,
    ["$ignorez"] = 		1,
    ["$nocull"] = 		1,
})

---@type Node[]
local Nodes = {}

local MGR = {}

---@return boolean
function MGR.IsRendering()
    return IsRendering
end

function MGR.Stop()
    LocalPlayer():EmitSound("buttons/button1.wav")

    IsRendering = false
    SMH.Controller.SetRendering(IsRendering)
end

local function RenderTick()
    if not IsRendering then
        return
    end

    local newPos = SMH.State.Frame + 1

    local command = "jpeg"
    if UseScreenshot then
        command = "screenshot"
    end

    RunConsoleCommand(command)

    if newPos >= SMH.State.PlaybackLength then
        MGR.Stop()
        return
    end

    timer.Simple(0.001, function()
        SMH.Controller.SetFrame(newPos)

        timer.Simple(0.001, function()
            RenderTick()
        end)
    end)

end

---@param useScreenshot boolean
---@param StartFrame integer
function MGR.Start(useScreenshot, StartFrame)
    UseScreenshot = useScreenshot

    IsRendering = true
    SMH.Controller.SetRendering(IsRendering)

    SMH.Controller.SetFrame(StartFrame)

    LocalPlayer():EmitSound("buttons/blip1.wav")

    timer.Simple(1, RenderTick)
end

function MGR.SetNodes(newNodes)
    Nodes = {}

    if #newNodes == 0 then return end
    local sortedNodes = {}
    for i = 1, #newNodes do
        sortedNodes[newNodes[i][1]] = {newNodes[i][2], newNodes[i][3]}
    end
    for frame, pose in SortedPairs(sortedNodes) do
        table.insert(Nodes, {Pos = pose[1], Ang = pose[2], Frame = frame})
    end
end

function MGR.GetNodes()
    return Nodes
end

do
    local RED = Color(255, 30, 30)
    local GREEN = Color(30, 200, 30)
    local YELLOW = Color(200, 200, 30)
    local UP_OFFSET = vector_up * 2.5

    local nodeRange = GetConVar("smh_motionpathrange")
    local name = GetConVar("smh_motionpathbone")
    local sphereSize = GetConVar("smh_motionpathsize")
    local offset = GetConVar("smh_motionpathoffset")
    local currentFrameIndex = 1 

    hook.Remove("PreDrawEffects", "SMHRenderMotionPath")
    hook.Add("PreDrawEffects", "SMHRenderMotionPath", function()
        name = name or GetConVar("smh_motionpathbone")
        nodeRange = nodeRange or GetConVar("smh_motionpathrange")
        sphereSize = sphereSize or GetConVar("smh_motionpathsize")
        offset = offset or GetConVar("smh_motionpathoffset")

        if #name:GetString() == 0 then return end
        if #Nodes == 0 or IsRendering then return end
        if not next(SMH.State.Entity) then Nodes = {} return end

        render.SetColorMaterialIgnoreZ()
        if nodeRange:GetInt() > 0 then
            for i = 1, #Nodes do
                if Nodes[i].Frame == SMH.State.Frame then
                    currentFrameIndex = i
                    break
                end
            end
        end

        local baseSize = sphereSize:GetFloat()
        local vectorString = offset:GetString():Split(" ")
        local vectorOffset = Vector(vectorString[1], vectorString[2], vectorString[3])
        for i = 1, #Nodes do 
            local currentFrame = SMH.State.Frame == Nodes[i].Frame
            local color = (SMH.State.Frame > Nodes[i].Frame) and RED or GREEN
            local size = baseSize + baseSize * 0.125 * math.sin(3 * CurTime() + i / 2)
            if nodeRange:GetInt() > 0 and math.abs(currentFrameIndex - i) > nodeRange:GetInt() then continue end
            render.DrawSphere(
                LocalToWorld(vectorOffset, angle_zero, Nodes[i].Pos, Nodes[i].Ang), 
                size, 
                10, 
                10, 
                currentFrame and YELLOW or color
            )
        end
        for i = 1, #Nodes - 1 do 
            local color = (SMH.State.Frame > Nodes[i].Frame) and RED or GREEN
            if nodeRange:GetInt() > 0 and math.abs(currentFrameIndex - i) > nodeRange:GetInt() then continue end

            render.DrawLine(
                LocalToWorld(vectorOffset, angle_zero, Nodes[i].Pos, Nodes[i].Ang), 
                LocalToWorld(vectorOffset, angle_zero, Nodes[i+1].Pos, Nodes[i+1].Ang), 
                color, 
                false
            )
        end
    end)

    hook.Remove("HUDPaint", "SMHDrawMotionPathText")
    hook.Add("HUDPaint", "SMHDrawMotionPathText", function()
        offset = offset or GetConVar("smh_motionpathoffset")
        name = name or GetConVar("smh_motionpathbone")

        if #name:GetString() == 0 then return end

        for i = 1, #Nodes do
            if Nodes[i].Frame ~= SMH.State.Frame then continue end 
            
            local vectorString = offset:GetString():Split(" ")
            local vectorOffset = Vector(vectorString[1], vectorString[2], vectorString[3])
            local framePosition = LocalToWorld(vectorOffset, angle_zero, Nodes[i].Pos, Nodes[i].Ang)
            if Nodes[i-1] then
                local previousPosition = LocalToWorld(vectorOffset, angle_zero, Nodes[i-1].Pos, Nodes[i-1].Ang)
                local dist = tostring(math.abs(Nodes[i].Frame - Nodes[i-1].Frame))
                local pos = ((framePosition + previousPosition) * 0.5 + UP_OFFSET):ToScreen()
                draw.SimpleTextOutlined(dist, "smh_tooltip", pos.x, pos.y, RED, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0, color_black)
            end
            if Nodes[i+1] then
                local nextPosition = LocalToWorld(vectorOffset, angle_zero, Nodes[i+1].Pos, Nodes[i+1].Ang)
                local dist = tostring(math.abs(Nodes[i].Frame - Nodes[i+1].Frame))
                local pos = ((framePosition + nextPosition) * 0.5 + UP_OFFSET):ToScreen()
                draw.SimpleTextOutlined(dist, "smh_tooltip", pos.x, pos.y, GREEN, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0, color_black)
            end
            return
        end
    end)
end

SMH.Renderer = MGR
