local PANEL = {}

surface.CreateFont( "smh_tooltip", {
    font = "Arial", 
    extended = false,
    size = ScreenScaleH(8),
    weight = 100,
    antialias = true,
    underline = false,
    italic = false,
    strikeout = false,
    symbol = false,
    rotary = false,
    shadow = false,
    additive = false,
    outline = true
} )

function PANEL:Init()

	self:SetWorldClicker(true)
    self:SetPos(0, 0)
    self:SetContentAlignment(1)
    self:SetSize(2000, 50)
    self:SetWrap(true)
    self:SetTextColor(color_white)

    self:SetVisible(false)
    self:SetFont("smh_tooltip")

end

function PANEL:SetTooltip(entityName)
    self:SetVisible(#entityName > 0)
    self:SetText(entityName)
end

vgui.Register("SMHTooltip", PANEL, "DLabel")
