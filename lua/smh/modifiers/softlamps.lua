
MOD.Name = "Soft Lamps";

function MOD:IsSoftLamp(entity)

    if entity:GetClass() ~= "gmod_softlamp" then return false; end
    return true;

end

function MOD:Save(entity)

    if not self:IsSoftLamp(entity) then return nil; end

    local data = {};

    data.FOV = entity:GetLightFOV();
    data.Nearz = entity:GetNearZ();
    data.Farz = entity:GetFarZ();
    data.Brightness = entity:GetBrightness();
    data.Color = entity:GetLightColor();
    data.ShapeRadius = entity:GetShapeRadius();
    data.FocalPoint = entity:GetFocalDistance();
    data.Offset = entity:GetLightOffset();

    return data;

end

function MOD:Load(entity, data)

    if not self:IsSoftLamp(entity) then return; end -- can never be too sure?

    entity:SetLightFOV(data.FOV);
    entity:SetNearZ(data.Nearz);
    entity:SetFarZ(data.Farz);
    entity:SetBrightness(data.Brightness);
    entity:SetLightColor(data.Color);
    entity:SetShapeRadius(data.ShapeRadius);
    entity:SetFocalDistance(data.FocalPoint);
    entity:SetLightOffset(data.Offset);

end

function MOD:OrganizeData(args)
    local data = args.data

    local tfov = {}
    local tnearz = {}
    local tfarz = {}
    local tbrightness = {}
    local tcolor = {}
    local tshaperadius = {}
    local tfocalpoint = {}
    local toffset = {}

    for d=1, #data do
        table.insert(tfov, data[d].FOV)
        table.insert(tnearz, data[d].Nearz)
        table.insert(tfarz, data[d].Farz)
        table.insert(tbrightness, data[d].Brightness)
        table.insert(tcolor, data[d].Color)
        table.insert(tshaperadius, data[d].ShapeRadius)
        table.insert(tfocalpoint, data[d].FocalPoint)
        table.insert(toffset, data[d].Offset)
    end

    return {
        FOV = tfov,
        Nearz = tnearz,
        Farz = tfarz,
        Brightness = tbrightness,
        Color = tcolor,
        ShapeRadius = tshaperadius,
        FocalPoint = tfocalpoint,
        Offset = toffset
    }

end

function MOD:LoadBetween(entity, data1, data2, percentage)

    if not self:IsSoftLamp(entity) then return; end -- can never be too sure?

    entity:SetLightFOV(SMH.LerpLinear(data1.FOV, data2.FOV, percentage));
    entity:SetNearZ(SMH.LerpLinear(data1.Nearz, data2.Nearz, percentage));
    entity:SetFarZ(SMH.LerpLinear(data1.Farz, data2.Farz, percentage));
    entity:SetBrightness(SMH.LerpLinear(data1.Brightness, data2.Brightness, percentage));
    entity:SetLightColor(SMH.LerpLinearVector(data1.Color, data2.Color, percentage));
    entity:SetShapeRadius(SMH.LerpLinear(data1.ShapeRadius, data2.ShapeRadius, percentage));
    entity:SetFocalDistance(SMH.LerpLinear(data1.FocalPoint, data2.FocalPoint, percentage));
    entity:SetLightOffset(SMH.LerpLinearVector(data1.Offset, data2.Offset, percentage));

end

function MOD:LoadBetweenCubic(entity, data1, data2, percentage)

    if not self:IsSoftLamp(entity) then return; end -- can never be too sure?

    entity:SetLightFOV(SMH.LerpCubic(data2.Frames, data2.Keydata.FOV, percentage));
    entity:SetNearZ(SMH.LerpCubic(data2.Frames, data2.Keydata.Nearz, percentage));
    entity:SetFarZ(SMH.LerpCubic(data2.Frames, data2.Keydata.Farz, percentage));
    entity:SetBrightness(SMH.LerpCubic(data2.Frames, data2.Keydata.Brightness, percentage));
    entity:SetLightColor(SMH.LerpCubicVector(data2.Frames, data2.Keydata.Color, percentage));
    entity:SetShapeRadius(SMH.LerpCubic(data2.Frames, data2.Keydata.ShapeRadius, percentage));
    entity:SetFocalDistance(SMH.LerpCubic(data2.Frames, data2.Keydata.FocalPoint, percentage));
    entity:SetLightOffset(SMH.LerpCubicVector(data2.Frames, data2.Keydata.Offset, percentage));

end