
MOD.Name = "Nonphysical Bones";

function MOD:Save(entity)

    if self:IsEffect(entity) then
        entity = entity.AttachedEntity;
    end

    local count = entity:GetBoneCount();

    local data = {};

    for b = 0, count -1 do

        local d = {};
        d.Pos = entity:GetManipulateBonePosition(b);
        d.Ang = entity:GetManipulateBoneAngles(b);
        d.Scale = entity:GetManipulateBoneScale(b);

        data[b] = d;

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

    local count = entity:GetBoneCount();

    for b = 0, count - 1 do

        local d = data[b];
        entity:ManipulateBonePosition(b, d.Pos);
        entity:ManipulateBoneAngles(b, d.Ang);
        entity:ManipulateBoneScale(b, d.Scale);

    end

end

function MOD:OrganizeData(args)
    local entity = args.entity
    local data = args.data
    
    local n = entity:GetBoneCount();
    local bonetabla = {}
    local lang

    for b = 0, n-1 do
        
        local bpos = {}
        local bang = {}
        local bscale = {}

        for f = 1, #data do

            lang = SMH.AngleToQuaternion(data[f][b].Ang)

            table.insert(bpos, data[f][b].Pos)
            table.insert(bang, lang)
            table.insert(bscale, data[f][b].Scale)

        end

        bonetabla[b] = bonetabla[b] or {}  
        bonetabla[b] = {Pos = bpos, Ang = bang, Scale = bscale}
        
    end
    return bonetabla
end

function MOD:LoadBetween(entity, data1, data2, percentage)

    if self:IsEffect(entity) then
        entity = entity.AttachedEntity;
    end
  
    for i = 0, #data2.Keydata do
        local Pos = SMH.LerpLinearVector(data2.Frames, data2.Keydata[i].Pos, percentage);
        local Ang = SMH.LerpLinearAngle(data2.Frames, data2.Keydata[i].Ang, percentage);
        local Scale = SMH.LerpLinearVector(data2.Frames, data2.Keydata[i].Scale, percentage);

        entity:ManipulateBonePosition(i, Pos);
        entity:ManipulateBoneAngles(i, Ang);
        entity:ManipulateBoneScale(i, Scale);

    end
    
end
