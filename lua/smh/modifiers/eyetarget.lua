
MOD.Name = "Eye target";

function MOD:HasEyes(entity)

    local Eyes = entity:LookupAttachment("eyes");

    if Eyes == 0 then return false; end
    return true;

end

function MOD:Save(entity)

    if self:IsEffect(entity) then
        entity = entity.AttachedEntity;
    end

    if not self:HasEyes(entity) then return nil; end

    local data = {};

    data.EyeTarget = entity:GetEyeTarget();

    return data;

end

function MOD:Load(entity, data)

    if self:IsEffect(entity) then
        entity = entity.AttachedEntity;
    end

    if not self:HasEyes(entity) then return; end --Shouldn't happen, but meh

    entity:SetEyeTarget(data.EyeTarget);

end

function MOD:OrganizeData(args)
    local entity = args.entity
    local data = args.data

    local EyeTarget = {}
    for f = 1 , #data do
        table.insert(EyeTarget, data[f].EyeTarget)
    end

    return {EyeTarget = EyeTarget}
end

function MOD:LoadBetween(entity, data1, data2, percentage)

    if self:IsEffect(entity) then
        entity = entity.AttachedEntity;
    end

    if not self:HasEyes(entity) then return; end --Shouldn't happen, but meh

    local et = SMH.LerpLinearVector(data1.EyeTarget, data2.EyeTarget, percentage);

    entity:SetEyeTarget(et);

end

function MOD:LoadBetweenCubic(entity, data1, data2, percentage)

    if self:IsEffect(entity) then
        entity = entity.AttachedEntity;
    end

    if not self:HasEyes(entity) then return; end --Shouldn't happen, but meh

    local et = SMH.LerpCubicVector(data2.Frames, data2.Keydata.EyeTarget, percentage);

    entity:SetEyeTarget(et);

end
