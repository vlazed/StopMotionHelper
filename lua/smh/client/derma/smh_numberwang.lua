
---@class SMHNumberWang: Panel
local PANEL = {}

function PANEL:Init()
	
    self.NumberWang = vgui.Create("DNumberWang", self)
	self.NumberWang.OnValueChanged = function(_, val)
		return self:OnValueChanged(val)
	end
    self.NumberWang:Dock(FILL)
    self.Label = vgui.Create("DLabel", self)
    self.Label:Dock(LEFT)
	self.Label:SetPaintBackground(false)

end

function PANEL:SetDecimals( num )

	self.NumberWang:SetDecimals(num)

end

function PANEL:PerformLayout(w, h)
	self.Label:SetWide( w / 2.4 )
end

function PANEL:SetMinMax( min, max )

	self.NumberWang:SetMin( min )
	self.NumberWang:SetMax( max )

end

function PANEL:SetMin( min )

	self.NumberWang:SetMin(min)

end

function PANEL:SetMax( max )

	self.NumberWang:SetMax(max)

end

function PANEL:GetFloatValue( max )

	return self.NumberWang:GetFloatValue()

end

function PANEL:Think()
	self.NumberWang:ConVarNumberThink()
end

function PANEL:SetValue( val )

    self.NumberWang:SetValue(val)

end

local meta = FindMetaTable( "Panel" )

function PANEL:GetValue()

	return self.NumberWang:GetValue()

end

function PANEL:SizeToContents()

    self.NumberWang:SizeToContents()
    self.Label:SizeToContents()

end

function PANEL:GetFraction( val )

    return self.NumberWang:GetFraction(val)

end

function PANEL:SetFraction( val )

    return self.NumberWang:SetFraction(val)

end

function PANEL:OnValueChanged( val )

end

function PANEL:GetTextArea()

	return self

end

function PANEL:SetDark( b )
	self.Label:SetDark( b )
	self:ApplySchemeSettings()
end

function PANEL:ApplySchemeSettings()

    ---@diagnostic disable-next-line
	self.Label:ApplySchemeSettings()

end

function PANEL:SetConVar(convar)
    self.NumberWang:SetConVar(convar)
end

function PANEL:SetText( text )
	return self.Label:SetText( text )
end

function PANEL:GetText()
	return self.Label:GetText()
end

vgui.Register( "SMHNumberWang", PANEL, "Panel" )
