
MOD.Name = "Advanced Color";

function MOD:AdvColorInstalled(entity)
    return isfunction(entity.SetSubColor) and entity._adv_colours and next(entity._adv_colours)
end

function MOD:Save(entity)

    if not self:AdvColorInstalled(entity) then return end

    if self:IsEffect(entity) then
        entity = entity.AttachedEntity;
    end

    local data = {}
    for i, color in pairs(entity._adv_colours) do
        data[i] = color
    end
    return data;

end

function MOD:Load(entity, data)

    if not self:AdvColorInstalled(entity) then return end

    if self:IsEffect(entity) then
        entity = entity.AttachedEntity;
    end

    for i, color in pairs(data) do
        entity:SetSubColor(i, color)
    end

end

function MOD:LoadBetween(entity, data1, data2, percentage)

    if not self:AdvColorInstalled(entity) then return end

    if self:IsEffect(entity) then
        entity = entity.AttachedEntity;
    end

    for i, c1 in pairs(data1) do
        local c2 = data2[i] or c1
        local diff = c1 ~= c2
        local r = diff and SMH.LerpLinear(c1.r, c2.r, percentage) or c1.r;
        local g = diff and SMH.LerpLinear(c1.g, c2.g, percentage) or c1.g;
        local b = diff and SMH.LerpLinear(c1.b, c2.b, percentage) or c1.b;
        local a = diff and SMH.LerpLinear(c1.a, c2.a, percentage) or c1.a;

        entity:SetSubColor(i, Color(r, g, b, a))
    end

end
