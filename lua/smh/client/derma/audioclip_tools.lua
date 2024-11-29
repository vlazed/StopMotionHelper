local PANEL = {}
local deleteConfirmColour = Color(255,0,0)

function PANEL:Init()

	self.Visible = false
	self:SetVisible(false)

    self:SetTitle("Audio Clip Tools")
    self:SetDeleteOnClose(false)
	
	self:SetSize(320, 107)
	
	self.Label = vgui.Create("DLabel",self)
	self.Label:SetText("Actions will apply to clip under playhead.")
	self.Label:SetFont("DefaultSmall")
		

    self.TrimStart = vgui.Create("DButton", self)
    self.TrimStart:SetText("Trim Start")
	self.TrimStart:SetEnabled(false)
    self.TrimStart.DoClick = function()
        print("trim start")
    end
	
	self.TrimEnd = vgui.Create("DButton", self)
    self.TrimEnd:SetText("Trim End")
	self.TrimEnd:SetEnabled(false)
    self.TrimEnd.DoClick = function()
        print("trim end")
    end
	
	self.Copy = vgui.Create("DButton", self)
    self.Copy:SetText("Copy")
	self.Copy:SetEnabled(false)
    self.Copy.DoClick = function()
        print("copy")
    end
	
	self.Paste = vgui.Create("DButton", self)
    self.Paste:SetText("Paste")
	self.Paste:SetEnabled(false)
    self.Paste.DoClick = function()
        print("paste")
    end
	
	self.Delete = vgui.Create("DButton", self)
    self.Delete:SetText("Delete")
    self.Delete.DoClick = function()
        self:DoDelete()
    end
	self.DeleteDefaultColour = self.Delete:GetColor()
	self.DeleteConfirm = false
	
	self.DeleteAll = vgui.Create("DButton", self)
    self.DeleteAll:SetText("Delete All")
    self.DeleteAll.DoClick = function()
        self:DoDeleteAll()
    end
	self.DeleteAllConfirm = false
	
	self.Hide = vgui.Create("DButton", self)
    self.Hide:SetText("Hide")
	self.Hide:SetEnabled(false)
    self.Hide.DoClick = function()
        print("hide")
    end
	
	self.UnhideAll = vgui.Create("DButton", self)
    self.UnhideAll:SetText("Unhide All")
	self.UnhideAll:SetEnabled(false)
    self.UnhideAll.DoClick = function()
        print("unhide all")
    end

end

function PANEL:PerformLayout(width, height)

    self.BaseClass.PerformLayout(self, width, height)
	
	self.Label:SetPos(25, 25)
	self.Label:SetSize(280, 20)

    self.TrimStart:SetPos(25, 43)
    self.TrimStart:SetSize(60, 20)
	
	self.TrimEnd:SetPos(25, 68)
    self.TrimEnd:SetSize(60, 20)
	
	self.Copy:SetPos(95, 43)
    self.Copy:SetSize(60, 20)
	
	self.Paste:SetPos(95, 68)
    self.Paste:SetSize(60, 20)
	
	self.Delete:SetPos(165, 43)
    self.Delete:SetSize(60, 20)
	
	self.DeleteAll:SetPos(165, 68)
    self.DeleteAll:SetSize(60, 20)
	
	self.Hide:SetPos(235, 43)
    self.Hide:SetSize(60, 20)
	
	self.UnhideAll:SetPos(235, 68)
    self.UnhideAll:SetSize(60, 20)

end

function PANEL:SetVis(bool)
	self.Visible = bool
	if SMH.State.EditAudioTrack then
		self:SetVisible(bool)
	end
end

function PANEL:SetEnabled(bool)
	if not bool then
		self:SetVisible(false)
	else
		if self.Visible then
			self:SetVisible(true)
		end
	end
end

function PANEL:OnClose()
	self.Visible = false
end

function PANEL:DoDelete()
	if not self.DeleteConfirm then
		self.Delete:SetText("Confirm?")
		self.Delete:SetColor(deleteConfirmColour)
		self.DeleteConfirm = true
		timer.Create("DeleteConfirm", 3, 0, function()
			self.Delete:SetText("Delete")
			self.Delete:SetColor(self.DeleteDefaultColour)
			self.DeleteConfirm = false
		end)
	else
		self.Delete:SetText("Delete")
		self.Delete:SetColor(self.DeleteDefaultColour)
		self.DeleteConfirm = false
		self.OnRequestAudioClipDelete()
	end
end

function PANEL:DoDeleteAll()
	if not self.DeleteAllConfirm then
		self.DeleteAll:SetText("Confirm?")
		self.DeleteAll:SetColor(deleteConfirmColour)
		self.DeleteAllConfirm = true
		timer.Create("DeleteAllConfirm", 3, 0, function()
			self.DeleteAll:SetText("Delete All")
			self.DeleteAll:SetColor(self.DeleteDefaultColour)
			self.DeleteAllConfirm = false
		end)
	else
		self.DeleteAll:SetText("Delete All")
		self.DeleteAll:SetColor(self.DeleteDefaultColour)
		self.DeleteAllConfirm = false
		self.OnRequestAudioClipDeleteAll()
	end
end

function PANEL:OnRequestAudioClipDelete() end
function PANEL:OnRequestAudioClipDeleteAll() end


vgui.Register("SMHAudioClipTools", PANEL, "DFrame")
