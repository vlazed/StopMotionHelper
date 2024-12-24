
MOD.Name = "Advanced Cameras";

function MOD:IsAdvCamera(entity)

    if entity:GetClass() ~= "hl_camera" then return false; end
    return true;

end

function MOD:Save(entity)

    if not self:IsAdvCamera(entity) then return nil; end

    local data = {};

    data.FOV = entity:GetFOV();
    data.Nearz = entity:GetNearZ();
    data.Farz = entity:GetFarZ();
    data.Roll = entity:GetRoll();
    data.Offset = entity:GetViewOffset();

    return data;

end

function MOD:Load(entity, data)

    if not self:IsAdvCamera(entity) then return; end -- can never be too sure?

    entity:SetFOV(data.FOV);
    entity:SetNearZ(data.Nearz);
    entity:SetFarZ(data.Farz);
    entity:SetRoll(data.Roll);
    entity:SetViewOffset(data.Offset);

end

function MOD:OrganizeData(args)
    local data = args.data

    local dataFOV = {}
    local dataNearZ = {}
    local dataFarZ = {}
    local dataRoll = {}
    local dataOffset = {}

    for i=1, #data do
        table.insert(dataFOV, data[i].FOV)
        table.insert(dataNearZ, data[i].Nearz)
        table.insert(dataFarZ, data[i].Farz)
        table.insert(dataRoll, data[i].Roll)
        table.insert(dataOffset, data[i].Offset)
    end

    return {FOV = dataFOV, Nearz = dataNearZ, Farz = dataFarZ, Roll = dataRoll, Offset = dataOffset}

end

function MOD:LoadBetween(entity, data1, data2, percentage)

    if not self:IsAdvCamera(entity) then return; end -- can never be too sure?

    entity:SetFOV(SMH.LerpLinear(data1.FOV, data2.FOV, percentage));
    entity:SetNearZ(SMH.LerpLinear(data1.Nearz, data2.Nearz, percentage));
    entity:SetFarZ(SMH.LerpLinear(data1.Farz, data2.Farz, percentage));
    entity:SetRoll(SMH.LerpLinear(data1.Roll, data2.Roll, percentage));
    entity:SetViewOffset(SMH.LerpLinearVector(data1.Offset, data2.Offset, percentage));

end

function MOD:LoadBetweenCubic(entity, data1, data2, percentage)

    if not self:IsAdvCamera(entity) then return; end -- can never be too sure?

    entity:SetFOV(SMH.LerpCubic(data2.Frames, data2.Keydata.FOV, percentage));
    entity:SetNearZ(SMH.LerpCubic(data2.Frames, data2.Keydata.Nearz, percentage));
    entity:SetFarZ(SMH.LerpCubic(data2.Frames, data2.Keydata.Farz, percentage));
    entity:SetRoll(SMH.LerpCubic(data2.Frames, data2.Keydata.Roll, percentage));
    entity:SetViewOffset(SMH.LerpCubicVector(data2.Frames, data2.Keydata.Offset, percentage));

end