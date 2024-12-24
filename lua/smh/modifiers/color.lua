
MOD.Name = "Color";

function MOD:Save(entity)

    if self:IsEffect(entity) then
        entity = entity.AttachedEntity;
    end

    local color = entity:GetColor();
    return { Color = color };

end

function MOD:Load(entity, data)

    if self:IsEffect(entity) then
        entity = entity.AttachedEntity;
    end

    entity:SetColor(data.Color);

end

local function ColorFramesOrganizer(data)

    local colorstable = {}
    local cn = #data

    local red = {}
    local green = {}
    local blue = {}
    local alpha = {}

    for c = 1, cn do

        table.insert(red, data[c].Color.r)
        table.insert(green, data[c].Color.g)
        table.insert(blue, data[c].Color.b)
        table.insert(alpha, data[c].Color.a)

    end

    colorstable.r = red
    colorstable.g = green
    colorstable.b = blue
    colorstable.a = alpha

    return colorstable
end


function MOD:OrganizeData(args)

    local data = args.data

    local colorstable = {}
    local cn = #data

    local red = {}
    local green = {}
    local blue = {}
    local alpha = {}

    for c = 1, cn do

        table.insert(red, data[c].Color.r)
        table.insert(green, data[c].Color.g)
        table.insert(blue, data[c].Color.b)
        table.insert(alpha, data[c].Color.a)

    end

    colorstable.r = red
    colorstable.g = green
    colorstable.b = blue
    colorstable.a = alpha

    return colorstable
end


function MOD:LoadBetween(entity, data1, data2, percentage)

    if self:IsEffect(entity) then
        entity = entity.AttachedEntity;
    end

    local ct = {}

    ct = data2.Keydata

    --ct = ColorFramesOrganizer(data2.Keydata)

    local r = SMH.LerpLinear(data2.Frames, ct.r, percentage);
    local g = SMH.LerpLinear(data2.Frames, ct.g, percentage);
    local b = SMH.LerpLinear(data2.Frames, ct.b, percentage);
    local a = SMH.LerpLinear(data2.Frames, ct.a, percentage);

    entity:SetColor(Color(r, g, b, a));

end
