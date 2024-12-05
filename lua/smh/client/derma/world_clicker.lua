local BaseClass = baseclass.Get("EditablePanel")
local PANEL = {}

-- https://github.com/penolakushari/RagdollMover/blob/eefbda5c3b27e193b1c3e113b258f7a1d4334cad/lua/autorun/ragdollmover.lua#L72
local function GetViewTrace()
    local player = LocalPlayer()
    local viewEntity = player:GetViewEntity()

    local eyePos = player:EyePos()
    if IsValid(viewEntity) and viewEntity ~= player then
        eyePos = viewEntity:EyePos()
        if viewEntity:GetClass() == "hl_camera" then -- adding support for Advanced Camera's view offset https://steamcommunity.com/sharedfiles/filedetails/?id=881605937&searchtext=advanced+camera
			eyePos = viewEntity:LocalToWorld(viewEntity:GetViewOffset())
		end
    end

    return {
        start = eyePos,
        endpos = eyePos + player:GetAimVector() * 32678,
        filter = viewEntity
    }
end

function PANEL:Init()

    self:SetWorldClicker(true)
    self.m_bStretchToFit = true

    self:SetPos(0, 0)
    self:SetSize(ScrW(), ScrH())

    self:MakePopup()
    self:SetVisible(false)

end

function PANEL:SetVisible(visible)
    if not visible then
        RememberCursorPosition()
    end
    BaseClass.SetVisible(self, visible)
    if visible then
        RestoreCursorPosition()
    end
    self:OnVisibilityChange(visible)
end

function PANEL:Think()
    local trace = util.TraceLine(GetViewTrace())

    self:OnEntityHovered(trace.HitNonWorld and trace.Entity)
end

function PANEL:OnMousePressed(mousecode)
    if mousecode ~= MOUSE_RIGHT then
        return
    end

    local trace = util.TraceLine(GetViewTrace())
    if not IsValid(trace.Entity) then return end

    local setting = 0
    if input.IsKeyDown(KEY_LSHIFT) then setting = 1 end

    self:OnEntitySelected(trace.Entity, setting)
end

function PANEL:OnEntitySelected(entity, setting) end
function PANEL:OnEntityHovered(entity, setting) end
function PANEL:OnVisibilityChange(visible) end

vgui.Register("SMHWorldClicker", PANEL, "EditablePanel")
