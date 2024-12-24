MOD.Name = "Model scale";

function MOD:Save(entity)
    return {
        ModelScale = entity:GetModelScale();
    };
end

function MOD:LoadGhost(entity, ghost, data)
    self:Load(ghost, data);
end

function MOD:LoadGhostBetween(entity, ghost, data1, data2, percentage)
    self:LoadBetween(ghost, data1, data2, percentage);
end

function MOD:Load(entity, data)
    entity:SetModelScale(data.ModelScale);
end

function MOD:OrganizeData(args)
    local data = args.data
    local modelscaletable = {}

    for d=1, #data do
        table.insert(modelscaletable, data[d].ModelScale)
    end

    return {ModelScale = modelscaletable}
end

function MOD:LoadBetween(entity, data1, data2, percentage)

    local lerpedModelScale = SMH.LerpLinear(data2.Frames, data2.Keydata.ModelScale, percentage);
    entity:SetModelScale(lerpedModelScale);

end
