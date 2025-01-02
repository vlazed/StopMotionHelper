
MOD.Name = "TF2 Item Paint";
MOD.Default = false

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
        data.PaintColor = paint:GetColor()
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
        local r = SMH.LerpLinear(data1.PaintColor.r, data2.PaintColor.r, percentage)
        local g = SMH.LerpLinear(data1.PaintColor.g, data2.PaintColor.g, percentage)
        local b = SMH.LerpLinear(data1.PaintColor.b, data2.PaintColor.b, percentage)
        paint:SetColor(Color(r, g, b))
        paint:SetPaintOverride(data1.PaintOverride)
    end

end
