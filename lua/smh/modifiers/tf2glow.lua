
MOD.Name = "TF2 Glow";
MOD.Default = false

function MOD:SparksInstalled()
    return isfunction(GiveMatproxyTF2CritGlow)
end

function MOD:SetGlowEntity(entity)
    if self:SparksInstalled() then
        GiveMatproxyTF2CritGlow(NULL, entity, {
            ColorR = 0,
            ColorG = 0,
            ColorB = 0,
            RedSparks = 0,
            BluSparks = 0,
            ColorableSparks = 0,
            JarateSparks = 0,
            JarateColorableSparks = 0,
        })
        return entity.ProxyentCritGlow
    end

    return NULL
end

function MOD:GetGlowEntity(entity)


    if IsValid(entity.ProxyentCritGlow) then 
        return entity.ProxyentCritGlow
    end

    return self:SetGlowEntity(entity);
end

function MOD:Save(entity)

    if not self:SparksInstalled() then return nil; end

    local data = {};

    local glow = self:GetGlowEntity(entity)
    if IsValid(glow) then
        data.GlowColor = glow.Color
        data.SparksRed = glow:GetSparksRed()
        data.SparksBlu = glow:GetSparksBlu()
        data.SparksColorable = glow:GetSparksColorabl() 
        data.SparksJarate = glow:GetSparksJarate()
        data.SparksJarateColorable = glow:GetSparksJarateColorable()
    end

    return Either(table.Count(data) > 0, data, nil);

end

function MOD:Load(entity, data)

    local glow = self:GetGlowEntity(entity)
    if IsValid(glow) then
        glow:SetColor(data.GlowColor)
        glow:SetSparksRed(data.SparksRed)
        glow:SetSparksBlu(data.SparksBlu)
        glow:SetSparksColorable(data.SparksColorable)
        glow:SetSparksJarate(data.SparksJarate)
        glow:SetSparksJarateColorable(data.SparksJarateColorable)
    end

end

function MOD:LoadBetween(entity, data1, data2, percentage)

    local glow = self:GetGlowEntity(entity)
    if IsValid(glow) then
        glow:SetColor(SMH.LerpLinearVector(data1.GlowColor, data2.GlowColor, percentage))
        glow:SetSparksRed(data1.SparksRed)
        glow:SetSparksBlu(data1.SparksBlu)
        glow:SetSparksColorable(data1.SparksColorable)
        glow:SetSparksJarate(data1.SparksJarate)
        glow:SetSparksJarateColorable(data1.SparksJarateColorable)
    end

end
