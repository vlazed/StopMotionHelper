local PANEL = {}

function PANEL:Init()

    self:SetTitle("Insert Audio Clip")
    self:SetDeleteOnClose(false)
    self:SetSizable(true)
	
	local sizeX, sizeY = ScrW()/4, ScrH()/3
	self:SetPos(ScrW()/2-sizeX/2,ScrH()/2-sizeY/2)
	self:SetSize(sizeX, sizeY)

    self:SetMinWidth(250)
    self:SetMinHeight(250)
	
	if not file.Exists("sound","GAME") then
		file.CreateDir("sound")
	end

    self.FileList = vgui.Create("DFileBrowser", self)
	
	self.FileList:SetPath("GAME")
	self.FileList:SetBaseFolder("sound")
	self.FileList:SetCurrentFolder("sound")
	self.FileList:SetOpen( true )
	self.FileList:SetFileTypes( "*.wav *.mp3" )
	self.FileList.OnDoubleClick = function()
		self.LoadSelected()
	end
	
	self.Form = vgui.Create("DForm", self)
	self.Form:SetName("File Name:")
	self.TextBox = self.Form:TextEntry("", nil)
	self.Button = self.Form:Button("Load", nil, nil)
	self.Button.DoClick = function()
		self:LoadSelected()
	end
	
	self.FileList.OnSelect = function(_, path, panel)
		self.TextBox:SetValue(table.GetLastValue(string.Split(path,"/")))
	end

end

function PANEL:PerformLayout(width, height)

    self.BaseClass.PerformLayout(self, width, height)
	
	self.FileList:Dock( FILL )
	self.FileList:DockMargin(0,0,0,30)
	
	self.Form:Dock(BOTTOM)
	self.Form:CopyWidth(self.FileList)

end

function PANEL:LoadSelected()
	local currentFolder = self.FileList:GetCurrentFolder()
	local filePath = currentFolder.."/"..self.TextBox:GetText()
	if file.Exists(filePath,"GAME") then
		self:SetVisible(false)
		self:OnInsertAudioRequested(filePath)
	else
		print("SMH Audio: "..filePath.." not found!")
		self.Button:SetText("File not found!")
		timer.Create("InsertFileNotFound", 3, 0, function()
			self.Button:SetText("Load")
		end)
	end
end

function PANEL:OnInsertAudioRequested(path) end

vgui.Register("SMHInsertAudio", PANEL, "DFrame")
