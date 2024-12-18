
MOD.Name = "Facial flexes";

function MOD:Save(entity)

    if self:IsEffect(entity) then
        entity = entity.AttachedEntity;
    end

    local count = entity:GetFlexNum();
    if count <= 0 then return nil; end

    local data = {};

    data.Scale = entity:GetFlexScale();

    data.Weights = {};

    for i = 0, count - 1 do
        data.Weights[i] = entity:GetFlexWeight(i);
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

    local count = entity:GetFlexNum();
    if count <= 0 then return; end --Shouldn't happen, but meh

    entity:SetFlexScale(data.Scale);
    entity:SetNW2Float("faceposer_scale", data.Scale)

    for i, f in pairs(data.Weights) do
        entity:SetFlexWeight(i, f);
        entity:SetNW2Float("faceposer_flex" .. i, f)
    end

end

function MOD:LoadBetween(entity, data1, data2, percentage)

    if self:IsEffect(entity) then
        entity = entity.AttachedEntity;
    end

    local count = entity:GetFlexNum();
    if count <= 0 then return; end --Shouldn't happen, but meh

    local scale = SMH.LerpLinear(data1.Scale, data2.Scale, percentage);
    entity:SetFlexScale(scale);

    for i = 0, count - 1 do

        local w1 = data1.Weights[i];
        local w2 = data2.Weights[i];
        local w = SMH.LerpLinear(w1, w2, percentage);

        entity:SetFlexWeight(i, w);

    end

end
