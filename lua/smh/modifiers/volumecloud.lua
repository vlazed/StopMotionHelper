
MOD.Name = "Volumetric Cloud";

function MOD:IsVolumeCloud(entity)

    return entity:GetClass() == "volume_cloud"

end

function MOD:Save(entity)

    if not self:IsVolumeCloud(entity) then return nil; end

    local data = {};

    data.size_x = entity:Getsize_x()
    data.size_y = entity:Getsize_y()
    data.size_z = entity:Getsize_z()
    data.subdivisions = entity:Getsubdivisions()
    data.blur = entity:Getblur()
    data.cloud_color = entity:Getcloud_color()

    return data;

end

function MOD:Load(entity, data)

    if not self:IsVolumeCloud(entity) then return; end -- can never be too sure?

    entity:Setsize_x(data.size_x)
    entity:Setsize_y(data.size_y)
    entity:Setsize_z(data.size_z)
    entity:Setsubdivisions(data.subdivisions)
    entity:Setblur(data.blur)
    entity:Setcloud_color(data.cloud_color)

end

function MOD:LoadBetween(entity, data1, data2, percentage)

    if not self:IsVolumeCloud(entity) then return; end -- can never be too sure?

    entity:Setsize_x(SMH.LerpLinear(data1.size_x, data2.size_x, percentage))
    entity:Setsize_y(SMH.LerpLinear(data1.size_y, data2.size_y, percentage))
    entity:Setsize_z(SMH.LerpLinear(data1.size_z, data2.size_z, percentage))
    entity:Setsubdivisions(SMH.LerpLinear(data1.subdivisions, data2.subdivisions, percentage))
    entity:Setblur(SMH.LerpLinear(data1.blur, data2.blur, percentage))
    entity:Setcloud_color(SMH.LerpLinearVector(data1.cloud_color, data2.cloud_color, percentage))

end
