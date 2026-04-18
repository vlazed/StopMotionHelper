
MOD.Name = "Body Template (don't enable)";
MOD.BodyEnds = {}
MOD.SetRoot = true
MOD.Ghost = true

---@param entity Entity
---@return table?
function MOD:Save(entity)

    local count = entity:GetPhysicsObjectCount();
    if count <= 0 then return nil; end

    local data = {};

    local endBones = {}
    for _, boneName in ipairs(self.BodyEnds) do
        local index = entity:LookupBone(boneName)
        if index then
            local physIndex = BoneToPhysBone(entity, index)
            if index and physIndex ~= -1 then
                table.insert(endBones, physIndex)
            end
        end
    end

    for _, physIndex in ipairs(endBones) do
        local walk = physIndex
        while walk ~= -1 do
            local newWalk = GetPhysBoneParent(entity, walk)
            if not data[walk] then
                local pb = entity:GetPhysicsObjectNum(walk)
                local record = false
                if self.SetRoot then
                    record = true
                else
                    -- We're a child bone
                    if newWalk >= 0 then
                        record = true
                    end
                end
                if record then
                    data[walk] = {
                        Pos = pb:GetPos(),
                        Ang = pb:GetAngles(),
                        Moveable = pb:IsMoveable(),
                    }
                end

            end
            walk = newWalk
        end
    end

    return data;

end

function MOD:Load(entity, data, settings)

    if settings and settings.IgnorePhysBones then
        return;
    end

    local count = entity:GetPhysicsObjectCount();

    for i = 0, count - 1 do

        local pb = entity:GetPhysicsObjectNum(i);

        local d = data[i];

        if not d then continue end

		pb:SetPos(d.Pos, true);
		pb:SetAngles(d.Ang);

        if settings and settings.FreezeAll then
            pb:EnableMotion(false);
        else
            pb:EnableMotion(d.Moveable);
        end

        pb:Wake();

    end

end

function MOD:LoadBetween(entity, data1, data2, percentage, settings)

    if settings and settings.IgnorePhysBones then
        return;
    end

    local count = entity:GetPhysicsObjectCount();

    for i = 0, count - 1 do
        local pb = entity:GetPhysicsObjectNum(i);

        local d1 = data1[i];
        local d2 = data2[i];

        if not d1 or not d2 then continue end

        local Pos = SMH.LerpLinearVector(d1.Pos, d2.Pos, percentage);
        local Ang = SMH.LerpLinearAngle(d1.Ang, d2.Ang, percentage);

        if settings and settings.FreezeAll then
            pb:EnableMotion(false);
        else
            pb:EnableMotion(d1.Moveable);
        end
        pb:SetPos(Pos, true);
        pb:SetAngles(Ang);

        pb:Wake();
    end

end

function MOD:LoadGhost(entity, ghost, data)
    return self:Load(ghost, data)
end

function MOD:LoadGhostBetween(entity, ghost, data1, data2, percentage)
    return self:LoadBetween(ghost, data1, data2, percentage)
end

function MOD:Offset(data, origindata, worldvector, worldangle, hitpos)

    if not hitpos then
        hitpos = origindata[0].Pos;
    end

    local newdata = {};

    for id, kdata in pairs(data) do

        local d = {};
        local Pos, Ang = WorldToLocal(kdata.Pos, kdata.Ang, origindata[0].Pos, Angle(0, 0, 0));
        d.Pos, d.Ang = LocalToWorld(Pos, Ang, worldvector, worldangle);
        d.Pos = d.Pos + hitpos;

        if kdata.LocalPos and kdata.LocalAng then -- those shouldn't change
            d.LocalPos, d.LocalAng = kdata.LocalPos, kdata.LocalAng;
        end

        d.Moveable = kdata.Moveable;

        newdata[id] = d;
    end

    return newdata;

end

function MOD:OffsetDupe(entity, data, origindata)

    local pb = entity:GetPhysicsObjectNum(0);
    if not IsValid(pb) then return nil end

    local entPos, entAng = pb:GetPos(), pb:GetAngles();
    local newdata = {};

    for id, kdata in pairs(data) do

        local d = {};
        d.Pos, d.Ang = WorldToLocal(kdata.Pos, kdata.Ang, origindata[0].Pos, origindata[0].Ang);
        d.Pos, d.Ang = LocalToWorld(d.Pos, d.Ang, entPos, entAng);

        if kdata.LocalPos and kdata.LocalAng then -- those shouldn't change
            d.LocalPos, d.LocalAng = kdata.LocalPos, kdata.LocalAng;
        end

        d.Moveable = kdata.Moveable;

        newdata[id] = d;
    end

    return newdata;

end
