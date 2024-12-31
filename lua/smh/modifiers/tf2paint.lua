
MOD.Name = "TF2 Item Paint";

function MOD:PaintInstalled()
    return isfunction(GiveMatproxyTF2ItemPaint)
end

function MOD:SetPaintEntity(parent)
    if self:PaintInstalled() then
        GiveMatproxyTF2ItemPaint(NULL, parent, {
            ColorR = 255,
            ColorG = 255,
            ColorB = 255,
            Override = 0
        })
        return parent.ProxyentPaintColor
    end

    return NULL
end

function MOD:GetPaintEntity(parent)

    if IsValid(parent.ProxyentPaintColor) then 
        return parent.ProxyentPaintColor
    end
    return self:SetPaintEntity(parent);
end

function MOD:Save(parent)

    if not self:PaintInstalled() then return nil; end

    local data = {};

    local paint = self:GetPaintEntity(parent)
    if IsValid(paint) then
        data.PaintColor = paint.Color
        data.PaintOverride = paint:GetPaintOverride()
    end

    return Either(table.Count(data) > 0, data, nil);

end

function MOD:Load(parent, data)

    local paint = self:GetPaintEntity(parent)
    if IsValid(paint) then
        paint:SetColor(data.PaintColor)
        paint:SetPaintOverride(data.PaintOverride)
    end

end

function MOD:LoadBetween(parent, data1, data2, percentage)

    local paint = self:GetPaintEntity(parent)
    if IsValid(paint) then
        paint:SetColor(SMH.LerpLinearVector(data1.PaintColor, data2.PaintColor, percentage))
        paint:SetPaintOverride(data1.PaintOverride)
    end

end
