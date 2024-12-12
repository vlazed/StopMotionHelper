
---@class Panel
local PANEL = FindMetaTable("Panel")

---@param otherPanel Panel
---@param x number
---@param y number
function PANEL:SetRelativePos(otherPanel, x, y)
    local posX, posY = otherPanel:GetPos()
    self:SetPos(posX + x, posY + y)
end

-- For DListView
---@param lines string[]
---@param isfolder boolean?
function PANEL:UpdateLines(lines, isfolder)
    ---@cast self DListView
    local set = {}
    local existing = {}

    for k, line in pairs(lines) do -- turn lines stuff into a "sorting" table
        if isfolder then
            line = "\\" .. line
        end
        set[line] = true
    end

    for k, line in pairs(self:GetLines()) do -- first we remove lines that are missing from the sorting table
        if not set[line:GetValue(1)] and isfolder == line.IsFolder then
            local _, selected = self:GetSelectedLine()
            if selected == line then self:ClearSelection() end -- clear selection if the removed line was selected
            self:RemoveLine(line:GetID())
            continue
        end
        existing[line:GetValue(1)] = true
    end

    for line, _ in pairs(set) do
        if existing[line] then continue end

        local line = self:AddLine(line)
        if isfolder then
            line.IsFolder = true
        end
    end
    self:SortByColumn(1)
end

-- For number wangs

---@return number?
function PANEL:GetNumberStep()
    ---@cast self SMHNumberWang

    return self.Step or 1
end
---@param step number
function PANEL:SetNumberStep(step)
    ---@cast self SMHNumberWang
    self.Step = step
    self.Up.DoClick = function() self:SetValue(self:GetValue() + self.Step) end
    self.Down.DoClick = function() self:SetValue(self:GetValue() - self.Step) end
end
