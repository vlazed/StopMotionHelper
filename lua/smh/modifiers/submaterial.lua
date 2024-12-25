
MOD.Name = "Submaterial";

function MOD:Save(entity)

    if self:IsEffect(entity) then
        entity = entity.AttachedEntity;
    end

    local data = {};
    local materials = entity:GetMaterials()
    for i = 0, #materials-1 do
        data[i+1] = entity:GetSubMaterial(i)
    end
    return data;
end

function MOD:LoadGhost(entity, ghost, data)
    self:Load(ghost, data);
end

function MOD:LoadGhostBetween(entity, ghost, data1, data2, percentage)
    self:LoadBetween(ghost, data1, data2, percentage);
end

function MOD:Load(entity, data)

    if self:IsEffect(entity) then
        entity = entity.AttachedEntity;
    end

    for i = 1, #data do
        entity:SetSubMaterial(i-1, data[i])
    end
end

function MOD:LoadBetween(entity, data1, data2, percentage)

    if self:IsEffect(entity) then
        entity = entity.AttachedEntity;
    end

    self:Load(entity, data1);

end
