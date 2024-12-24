
MOD.Name = "Advanced Lights";

local validClasses = {
    projected_light = true,
    projected_light_new = true,
    cheap_light = true,
    expensive_light = true,
    expensive_light_new = true,
    spot_light = true
};

function MOD:IsAdvLight(entity)

    local theclass = entity:GetClass();

    return validClasses[theclass] or false;

end

function MOD:IsProjectedLight(entity)

    local theclass = entity:GetClass();

    if theclass == "cheap_light" or theclass == "spot_light" then return false; end
    return true;

end

function MOD:Save(entity)

    if not self:IsAdvLight(entity) then return nil; end

    local data = {};

    data.Brightness = entity:GetBrightness();
    data.Color = entity:GetLightColor();

    if self:IsProjectedLight(entity) then
        local theclass = entity:GetClass();
        if theclass ~= "expensive_light" and theclass ~= "expensive_light_new" then -- expensive lights don't have FoV settings, but they are projected lights
            data.FOV = entity:GetLightFOV();
        end
        if theclass == "projected_light_new" then
            data.OrthoBottom = entity:GetOrthoBottom();
            data.OrthoLeft = entity:GetOrthoLeft();
            data.OrthoRight = entity:GetOrthoRight();
            data.OrthoTop = entity:GetOrthoTop();
        end
        data.Nearz = entity:GetNearZ();
        data.Farz = entity:GetFarZ();
    elseif entity:GetClass() == "cheap_light" then
        data.LightSize = entity:GetLightSize();
    else
        data.InFOV = entity:GetInnerFOV();
        data.OutFOV = entity:GetOuterFOV();
        data.Radius = entity:GetRadius();
    end

    return data;

end

function MOD:Load(entity, data)

    if not self:IsAdvLight(entity) then return; end -- can never be too sure?

    entity:SetBrightness(data.Brightness);
    entity:SetLightColor(data.Color);

    if self:IsProjectedLight(entity) then
        local theclass = entity:GetClass();
        if theclass ~= "expensive_light" and theclass ~= "expensive_light_new" then
            entity:SetLightFOV(data.FOV);
        end
        if theclass == "projected_light_new" then
            entity:SetOrthoBottom(data.OrthoBottom);
            entity:SetOrthoLeft(data.OrthoLeft);
            entity:SetOrthoRight(data.OrthoRight);
            entity:SetOrthoTop(data.OrthoTop);
        end
        entity:SetNearZ(data.Nearz);
        entity:SetFarZ(data.Farz);
    elseif entity:GetClass() == "cheap_light" then
        entity:SetLightSize(data.LightSize);
    else
        entity:SetInnerFOV(data.InFOV);
        entity:SetOuterFOV(data.OutFOV);
        entity:SetRadius(data.Radius);
    end

end

function MOD:OrganizeData(args)
    local data = args.data
    
    local tbright = {}
    local tcolor = {}
    local tfov = {}
    local torthob = {}
    local torthol = {}
    local torthor = {}
    local torthot = {}
    local tnearz = {}
    local tfarz = {}
    local tlightsize = {}
    local tinfov = {}
    local toutfov = {}
    local tradius = {}
    
    for d=1, #data do
        table.insert(tbright, data[d].Brightness)
        table.insert(tcolor, data[d].Color)
        table.insert(tfov, data[d].FOV)
        table.insert(torthob, data[d].OrthoBottom)
        table.insert(torthol, data[d].OrthoLeft)
        table.insert(torthor, data[d].OrthoRight)
        table.insert(torthot, data[d].OrthoTop)
        table.insert(tnearz, data[d].Nearz)
        table.insert(tfarz, data[d].Farz)
        table.insert(tlightsize, data[d].LightSize)
        table.insert(tinfov, data[d].InFOV)
        table.insert(toutfov, data[d].OutFOV)
        table.insert(tradius, data[d].Radius)
    end

    return {
        Brightness = tbright,
        Color = tcolor,
        FOV = tfov,
        OrthoBottom = torthob,
        OrthoLeft = torthol,
        OrthoRight = torthor,
        OrthoTop = torthot,
        Nearz = tnearz,
        Farz = tfarz,
        LightSize = tlightsize,
        InFOV = tinfov,
        OutFOV = toutfov,
        Radius = tradius
    }
    
end

function MOD:LoadBetween(entity, data1, data2, percentage)

    if not self:IsAdvLight(entity) then return; end -- can never be too sure?

    entity:SetBrightness(SMH.LerpLinear(data1.Brightness, data2.Brightness, percentage));
    entity:SetLightColor(SMH.LerpLinearVector(data1.Color, data2.Color, percentage));

    if self:IsProjectedLight(entity) then
        local theclass = entity:GetClass();
        if theclass ~= "expensive_light" and theclass ~= "expensive_light_new" then
            entity:SetLightFOV(SMH.LerpLinear(data1.FOV, data2.FOV, percentage));
        end
        if theclass == "projected_light_new" then
            entity:SetOrthoBottom(SMH.LerpLinear(data1.OrthoBottom, data2.OrthoBottom, percentage));
            entity:SetOrthoLeft(SMH.LerpLinear(data1.OrthoLeft, data2.OrthoLeft, percentage));
            entity:SetOrthoRight(SMH.LerpLinear(data1.OrthoRight, data2.OrthoRight, percentage));
            entity:SetOrthoTop(SMH.LerpLinear(data1.OrthoTop, data2.OrthoTop, percentage));
        end
        entity:SetNearZ(SMH.LerpLinear(data1.Nearz, data2.Nearz, percentage));
        entity:SetFarZ(SMH.LerpLinear(data1.Farz, data2.Farz, percentage));
    elseif entity:GetClass() == "cheap_light" then
        entity:SetLightSize(SMH.LerpLinear(data1.LightSize, data2.LightSize, percentage));
    else
        entity:SetInnerFOV(SMH.LerpLinear(data1.InFOV, data2.InFOV, percentage));
        entity:SetOuterFOV(SMH.LerpLinear(data1.OutFOV, data2.OutFOV, percentage));
        entity:SetRadius(SMH.LerpLinear(data1.Radius, data2.Radius, percentage));
    end

end

function MOD:LoadBetweenCubic(entity, data1, data2, percentage)

    if not self:IsAdvLight(entity) then return; end -- can never be too sure?

    entity:SetBrightness(SMH.LerpCubic(data2.Frames, data2.Keydata.Brightness, percentage));
    entity:SetLightColor(SMH.LerpCubicVector(data2.Frames, data2.Keydata.Color, percentage));

    if self:IsProjectedLight(entity) then
        local theclass = entity:GetClass();
        if theclass ~= "expensive_light" and theclass ~= "expensive_light_new" then
            entity:SetLightFOV(SMH.LerpCubic(data2.Frames, data2.Keydata.FOV, percentage));
        end
        if theclass == "projected_light_new" then
            entity:SetOrthoBottom(SMH.LerpCubic(data2.Frames, data2.Keydata.OrthoBottom, percentage));
            entity:SetOrthoLeft(SMH.LerpCubic(data2.Frames, data2.Keydata.OrthoLeft, percentage));
            entity:SetOrthoRight(SMH.LerpCubic(data2.Frames, data2.Keydata.OrthoRight, percentage));
            entity:SetOrthoTop(SMH.LerpCubic(data2.Frames, data2.Keydata.OrthoTop, percentage));
        end
        entity:SetNearZ(SMH.LerpCubic(data2.Frames, data2.Keydata.Nearz, percentage));
        entity:SetFarZ(SMH.LerpCubic(data2.Frames, data2.Keydata.Farz, percentage));
    elseif entity:GetClass() == "cheap_light" then
        entity:SetLightSize(SMH.LerpCubic(data2.Frames, data2.Keydata.LightSize, percentage));
    else
        entity:SetInnerFOV(SMH.LerpCubic(data2.Frames, data2.Keydata.InFOV, percentage));
        entity:SetOuterFOV(SMH.LerpCubic(data2.Frames, data2.Keydata.OutFOV, percentage));
        entity:SetRadius(SMH.LerpCubic(data2.Frames, data2.Keydata.Radius, percentage));
    end

end
