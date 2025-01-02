
MOD.Name = "Advanced Color";

function MOD:AdvColorInstalled(entity)
    return isfunction(entity.SetSubColor) and entity._adv_colours and next(entity._adv_colours)
end

function MOD:InitializeEntity(entity)
    -- Initialize all advanced colour fields
    for i = 0, #entity:GetMaterials() - 1 do
        if not entity._adv_colours[i] then
            entity:SetSubColor(i, color_white)
        end
    end
end

function MOD:Save(entity)

    if not self:AdvColorInstalled(entity) then return end

    if self:IsEffect(entity) then
        entity = entity.AttachedEntity;
    end

    self:InitializeEntity(entity)

    local data = {}
    for i, color in pairs(entity._adv_colours) do
        data[i] = color
    end
    return data;

end

function MOD:Load(entity, data)

    if not self:AdvColorInstalled(entity) then return end

    self:InitializeEntity(entity)

    if self:IsEffect(entity) then
        entity = entity.AttachedEntity;
    end

    for i, color in pairs(data) do
        entity:SetSubColor(i, color)
    end

end

function MOD:LoadBetween(entity, data1, data2, percentage)

    if not self:AdvColorInstalled(entity) then return end

    self:InitializeEntity(entity)

    if self:IsEffect(entity) then
        entity = entity.AttachedEntity;
    end

    for i, c1 in pairs(data1) do
        local c2 = data2[i]
        local r = SMH.LerpLinear(c1.r, c2.r, percentage);
        local g = SMH.LerpLinear(c1.g, c2.g, percentage);
        local b = SMH.LerpLinear(c1.b, c2.b, percentage);
        local a = SMH.LerpLinear(c1.a, c2.a, percentage);

        entity:SetSubColor(i, Color(r, g, b, a))
    end

end
