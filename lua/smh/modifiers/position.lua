
MOD.Name = "Position and Rotation";

function MOD:Save(entity)

    local data = {};
    data.Pos = entity:GetPos();
    data.Ang = entity:GetAngles();
    return data;

end

function MOD:LoadGhost(entity, ghost, data)
    self:Load(ghost, data);
end

function MOD:LoadGhostBetween(entity, ghost, data1, data2, percentage)
    self:LoadBetween(ghost, data1, data2, percentage);
end

function MOD:Load(entity, data)

    entity:SetPos(data.Pos);
    entity:SetAngles(data.Ang);

end

function MOD:OrganizeData(args)
    local data = args.data
    local lang

    local datavec = {}
    local dataang = {}

    for i=1, #data do
        lang = SMH.AngleToQuaternion(data[i].Ang)
        table.insert(datavec, data[i].Pos)
        table.insert(dataang, lang)
    end

    return {Pos = datavec, Ang = dataang}

end

function MOD:LoadBetween(entity, data1, data2, percentage)

    local Pos = SMH.LerpLinearVector(data1.Pos, data2.Pos, percentage);
    local Ang = SMH.LerpLinearAngle(data1.Ang, data2.Ang, percentage);

    entity:SetPos(Pos);
    entity:SetAngles(Ang);

end

function MOD:LoadBetweenCubic(entity, data1, data2, percentage)


    local Pos = SMH.LerpCubicVector(data2.Frames, data2.Keydata.Pos, percentage);
    local Ang = SMH.LerpCubicAngle(data2.Frames, data2.Keydata.Ang, percentage);

    entity:SetPos(Pos);
    entity:SetAngles(Ang);

end

function MOD:Offset(data, origindata, worldvector, worldangle, hitpos)

    if not hitpos then
        hitpos = origindata.Pos
    end

    local datanew = {};
    local Pos, Ang = WorldToLocal(data.Pos, data.Ang, origindata.Pos, Angle(0, 0, 0));
    datanew.Pos, datanew.Ang = LocalToWorld(Pos, Ang, worldvector, worldangle);
    datanew.Pos = datanew.Pos + hitpos;
    return datanew;

end

function MOD:OffsetDupe(entity, data, origindata)

    local entPos, entAng = entity:GetPos(), entity:GetAngles();
    local datanew = {};
    datanew.Pos, datanew.Ang = WorldToLocal(data.Pos, data.Ang, origindata.Pos, origindata.Ang);
    datanew.Pos, datanew.Ang = LocalToWorld(datanew.Pos, datanew.Ang, entPos, entAng);

    return datanew;

end
