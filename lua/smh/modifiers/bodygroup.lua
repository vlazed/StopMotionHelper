
MOD.Name = "Bodygroup";

function MOD:Save(entity)

    if self:IsEffect(entity) then
        entity = entity.AttachedEntity;
    end

    local data = {};
    local bgs = entity:GetBodyGroups();
    for _, bg in pairs(bgs) do
        data[bg.id] = entity:GetBodygroup(bg.id);
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

    for id, value in pairs(data) do
        entity:SetBodygroup(id, value);
    end
end

function MOD:OrganizeData(args)
    local data = args.data
    return data;
end

function MOD:LoadBetween(entity, data1, data2, percentage)

    if self:IsEffect(entity) then
        entity = entity.AttachedEntity;
    end

    self:Load(entity, data1);

end

--[[

function MOD:Load(entity, data)
    print("data bodygroup = ")
    print(printTable(data))

    if self:IsEffect(entity) then
        entity = entity.AttachedEntity;
    end

    for id, value in pairs(data) do
        entity:SetBodygroup(id, value);
    end
end

function MOD:OrganizeData(args)
    local data = args.data
    return data;
end

function MOD:LoadBetween(entity, data1, data2, percentage)

    if self:IsEffect(entity) then
        entity = entity.AttachedEntity;
    end


    local frames = data2.Frames
    local scaledT
    local index
    local localT

    scaledT = t * (frames[#frames] - frames[1])

    index = 0
    for i = 1, #frames - 1 do
        if scaledT >= frames[i] and scaledT <= frames[i + 1] then
            index = i - 1  -- Restar 1 para compensar el inicio desde 0
            break
        end
    end

    local prev = data2.Keydata[math.max(index, 1)]



    self:Load(entity, prev);

end

]]

