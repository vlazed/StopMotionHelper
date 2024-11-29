local PANEL = {}

function PANEL:Init()

    self:SetTitle("Load Audio Sequence")
    self:SetDeleteOnClose(false)
    self:SetSizable(true)

    self:SetSize(250, 250)
    self:SetMinWidth(250)
    self:SetMinHeight(250)
    self:SetPos(ScrW() / 2 - self:GetWide() / 2, ScrH() / 2 - self:GetTall() / 2)

    //self.FileName = vgui.Create("DTextEntry", self)
    //self.FileName.Label = vgui.Create("DLabel", self)
    //self.FileName.Label:SetText("Name")
    //self.FileName.Label:SizeToContents()

    self.FileList = vgui.Create("DListView", self)
    self.FileList:SetMultiSelect(false)
    self.FileList:AddColumn("Saved sequences")

    self.Load = vgui.Create("DButton", self)
    self.Load:SetText("Load")
    self.Load.DoClick = function()
        self:LoadSelected()
    end
	
	self.LoadFrameRate = vgui.Create("DCheckBoxLabel", self)
    self.LoadFrameRate:SetText("Load Framerate & Length")
	self.LoadFrameRate:SetValue(true)

end

function PANEL:PerformLayout(width, height)

    self.BaseClass.PerformLayout(self, width, height)

    //self.FileName:SetPos(5, 45)
    //self.FileName:SetSize(self:GetWide() - 5 - 5, 20)
    //self.FileName.Label:SetPos(5, 30)

    self.FileList:SetPos(5, 45)
    self.FileList:SetSize(self:GetWide() - 5 - 5, 150 * (self:GetTall() / 250) + 22)

    self.Load:SetPos(self:GetWide() - 60 - 5, self:GetTall() - 31)
    self.Load:SetSize(60, 20)
	
	self.LoadFrameRate:SetPos(5, self:GetTall() - 31)
	self.LoadFrameRate:SetSize(200, 20)

end

function PANEL:SetSaves(saves)
    self.FileList:UpdateLines(saves)
end

function PANEL:LoadSelected()
    local _, selectedSave = self.FileList:GetSelectedLine()

    if not IsValid(selectedSave) then
        return
    end
	
	self:SetVisible(false)
    self:OnLoadRequested(selectedSave:GetValue(1), self.LoadFrameRate:GetChecked())
end

function PANEL:OnLoadRequested(path) end

vgui.Register("SMHLoadAudio", PANEL, "DFrame")
