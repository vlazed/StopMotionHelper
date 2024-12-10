local BaseClass = baseclass.Get("EditablePanel")
---@class SMHWorldClickerPanel: EditablePanel
local PANEL = {}

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
end

function PANEL:OnMousePressed(mousecode)
    if mousecode ~= MOUSE_RIGHT then
        return
    end

    local trace = util.TraceLine(util.GetPlayerTrace(LocalPlayer()))
    if not IsValid(trace.Entity) then return end

    local setting = 0
    if input.IsKeyDown(KEY_LSHIFT) then setting = 1 end

    self:OnEntitySelected(trace.Entity, setting)
end

function PANEL:OnEntitySelected(entity, setting) end

vgui.Register("SMHWorldClicker", PANEL, "EditablePanel")
