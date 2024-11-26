
MOD.Name = "Sequence";

function MOD:Save(entity)

    if entity:IsPlayer() then return end

    local data = {};

    data.id = entity:GetSequence()

    return data;

end

function MOD:Load(entity, data)

    if entity:IsPlayer() then return end

    entity:SetSequence(data.id)

end

function MOD:LoadBetween(entity, data1, data2, percentage)

    self:Load(entity, data1);

end
