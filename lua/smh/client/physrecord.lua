local SMHRecorderID = "SMH_Recording_Timer"
local Active = false
local Waiting = 0

surface.CreateFont( "smh_font", {
    font = "Arial", 
    extended = false,
    size = 90,
    weight = 500,
    blursize = 0,
    scanlines = 4,
    antialias = true,
    underline = false,
    italic = false,
    strikeout = false,
    symbol = false,
    rotary = false,
    shadow = false,
    additive = false,
    outline = false
} )

local MGR = {}

MGR.FrameCount, MGR.RecordInterval, MGR.StartDelay = 100, 0, 3
MGR.SelectedEntities = {}

do
    local function beep(rate)
        rate = rate or 1
    
        sound.PlayFile("sound/buttons/blip1.wav", "mono noplay", function(channel, errorID, errorName)
            if channel then
                channel:SetPlaybackRate(rate)
                channel:Play()
            end
        end)
    end
        
    function MGR.RecordToggle()

        beep(1)
        if not Active then
            SMH.Controller.SelectEntity(nil, {})
            Active = true
            local wait = MGR.StartDelay
            Waiting = wait

            timer.Create(SMHRecorderID, 1 , wait + 1, function()
                Waiting = Waiting - 1
                if Waiting == 0 then
                    beep(2)
                else
                    beep(1)
                end
            end)

            timer.Create(SMHRecorderID .. 1, wait, 1, function()
                Waiting = 0
                SMH.Controller.StartPhysicsRecord(MGR.FrameCount, MGR.RecordInterval, MGR.SelectedEntities)
                timer.Remove(SMHRecorderID)
            end)
        else
            Active = false
            Waiting = 0
            SMH.Controller.StopPhysicsRecord()
            timer.Remove(SMHRecorderID)
            timer.Remove(SMHRecorderID .. 1)
            MGR.SelectedEntities = {}
        end

    end
end

function MGR.Stop()
    Active = false
    Waiting = 0
    timer.Remove(SMHRecorderID)
    timer.Remove(SMHRecorderID .. 1)
    MGR.SelectedEntities = {}
end

function MGR.IsActive()
    return Active
end

SMH.PhysRecord = MGR

do
    -- https://wiki.facepunch.com/gmod/surface.DrawPoly
    local function circle( x, y, radius, seg )
        local cir = {}
    
        table.insert( cir, { x = x, y = y, u = 0.5, v = 0.5 } )
        for i = 0, seg do
            local a = math.rad( ( i / seg ) * -360 )
            table.insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )
        end
    
        local a = math.rad( 0 ) -- This is needed for non absolute segment counts
        table.insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )
    
        surface.DrawPoly( cir )
    end

    local currentFrame = 0
    local lastTime = CurTime()
    hook.Remove("HUDPaint", "smh_draw_waiting")
    hook.Add( "HUDPaint", "smh_draw_waiting", function()
        if Waiting > 0 then
            currentFrame = SMH.State.Frame
            surface.SetFont( "smh_font" )
            surface.SetTextColor( 255, 0, 0 )
            surface.SetTextPos( 128, 128 )
            surface.DrawText( "Starting physics recording in: " .. Waiting )
        elseif Active then
            local now = CurTime()
            if (now - lastTime) > ((MGR.RecordInterval + 1) / SMH.State.PlaybackRate) then
                currentFrame = currentFrame + MGR.RecordInterval + 1
                lastTime = now
            end
            local percentage = currentFrame / (SMH.State.Frame + MGR.FrameCount)
            surface.SetDrawColor(255, 0, 0, 255 * (1 - percentage^4))
            draw.NoTexture()
            circle(ScrW() - 160, 160, ScreenScaleH(20), 30)
        end
    end)
end
