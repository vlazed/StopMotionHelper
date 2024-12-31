
MOD.Name = "TF2 Cloak";
MOD.Default = false

function MOD:CloakInstalled()
    return isfunction(GiveMatproxyTF2CloakEffect)
end

function MOD:SetCloakEntity(entity)
    if self:CloakInstalled() then
        GiveMatproxyTF2CloakEffect(NULL, entity, {
            TintR = 255, 
            TintG = 255, 
            TintB = 255, 
            Factor = 0,
            RefractAmount = 0,
            DisableShadow = 0,
            Anim = 0,
            Anim_NumpadKey = 59,
            Anim_Toggle = 0,
            Anim_StartOn = 0,
            Anim_TimeIn = 1,
            Anim_TimeOut = 2,
        })
        return entity.ProxyentCloakEffect
    end

    return NULL
end

function MOD:GetCloakEntity(entity)

    if IsValid(entity.ProxyentCloakEffect) then 
        return entity.ProxyentCloakEffect
    end
    return self:SetCloakEntity(entity);
end

function MOD:Save(entity)

    if not self:CloakInstalled() and not self:PaintSparksInstalled() then return nil; end

    local data = {};

    local cloak = self:GetCloakEntity(entity)
    if IsValid(cloak) then
        data.CloakTintVector = cloak:GetCloakTintVector()
        data.CloakFactor = cloak:GetCloakFactor()
        data.CloakRefractAmount = cloak:GetCloakRefractAmount()
        data.CloakDisablesShadow = cloak:GetCloakDisablesShadow()
        data.CloakAnim = cloak:GetCloakAnim()
        data.CloakAnimToggle = cloak:GetCloakAnimToggle()
        data.CloakAnimActive = cloak:GetCloakAnimActive()
        data.CloakAnimTimeIn = cloak:GetCloakAnimTimeIn()
        data.CloakAnimTimeOut = cloak:GetCloakAnimTimeOut()
    end

    return Either(table.Count(data) > 0, data, nil);

end

function MOD:Load(entity, data)

    local cloak = self:GetCloakEntity(entity)
    if IsValid(cloak) then
        cloak:SetCloakTintVector(data.CloakTintVector)
        cloak:SetCloakFactor(data.CloakFactor)
        cloak:SetCloakRefractAmount(data.CloakRefractAmount)
        cloak:SetCloakDisablesShadow(data.CloakDisablesShadow)
        cloak:SetCloakAnim(data.CloakAnim)
        cloak:SetCloakAnimToggle(data.CloakAnimToggle)
        cloak:SetCloakAnimActive(data.CloakAnimActive)
        cloak:SetCloakAnimTimeIn(data.CloakAnimTimeIn)
        cloak:SetCloakAnimTimeOut(data.CloakAnimTimeOut)
    end

end

function MOD:LoadBetween(entity, data1, data2, percentage)

    local cloak = self:GetCloakEntity(entity)
    if IsValid(cloak) then
        cloak:SetCloakTintVector(SMH.LerpLinearVector(data1.CloakTintVector, data2.CloakTintVector, percentage))
        cloak:SetCloakFactor(SMH.LerpLinear(data1.CloakFactor, data2.CloakFactor, percentage))
        cloak:SetCloakRefractAmount(SMH.LerpLinear(data1.CloakRefractAmount, data2.CloakRefractAmount, percentage))
        cloak:SetCloakDisablesShadow(data1.CloakDisablesShadow)
        cloak:SetCloakAnim(data1.CloakAnim)
        cloak:SetCloakAnimToggle(data1.CloakAnimToggle)
        cloak:SetCloakAnimActive(data1.CloakAnimActive)
        cloak:SetCloakAnimTimeIn(data1.CloakAnimTimeIn)
        cloak:SetCloakAnimTimeOut(data1.CloakAnimTimeOut)
    end

end
