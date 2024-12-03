local UseScreenshot = false
local IsRendering = false

local Nodes = {}

local MGR = {}

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
        sortedNodes[newNodes[i][1]] = newNodes[i][2]
    end
    for _, pos in SortedPairs(sortedNodes) do
        table.insert(Nodes, pos)
    end
end

function MGR.GetNodes()
    return Nodes
end

do
    local GREEN = Color(0, 200, 0)
    hook.Remove("PreDrawEffects", "SMHRenderMotionPath")
    hook.Add("PreDrawEffects", "SMHRenderMotionPath", function()
        if #Nodes == 0 or IsRendering then return end
        if not next(SMH.State.Entity) then Nodes = {} return end

        render.SetColorMaterialIgnoreZ()
        for i = 1, #Nodes do 
            local sphereSize = 1 + 0.125 * math.sin(1.5 * CurTime() + i / 2)
            render.DrawSphere(Nodes[i], sphereSize, 10, 10, GREEN)
        end
        for i = 1, #Nodes - 1 do 
            render.DrawLine(Nodes[i], Nodes[i+1], GREEN, false)
        end
    end)
end

SMH.Renderer = MGR
