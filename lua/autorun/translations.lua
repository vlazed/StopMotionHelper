-- Bone translation functions, so we can change their functionality here in case the original ones fuck up even more

---@param entity Entity Entity to translate bone
---@param bone integer Bone id
---@return integer physBone Physics object id
function GetPhysBoneParentFromBone(entity, bone)
	local b = bone
	local i = 1
	while true do
		b = entity:GetBoneParent(b)
		local parent = BoneToPhysBone(entity, b)
		if parent >= 0 and parent ~= bone then
			return parent
		end
		i = i + 1
		if i > 128 then --We've gone through all possible bones, so we get out.
			break
		end
	end
	return -1
end

---@param entity Entity Entity to translate bone
---@param bone integer Physics object id
---@return integer physBone Parent physics object id
function GetPhysBoneParent(entity, bone)
	local b = PhysBoneToBone(entity, bone)
	local i = 1
	while true do
		b = entity:GetBoneParent(b)
		local parent = BoneToPhysBone(entity, b)
		if parent >= 0 and parent ~= bone then
			return parent
		end
		i = i + 1
		if i > 128 then --We've gone through all possible bones, so we get out.
			break
		end
	end
	return -1
end

---@param ent Entity Entity to translate bone
---@param bone integer Physics object id
---@return integer b Bone id
function PhysBoneToBone(ent, bone)
	return ent:TranslatePhysBoneToBone(bone)
end

---@type {[string]: {[integer]: integer}}
local boneToPhysMap = {}

---@param ent Entity Entity to translate bone
---@param bone integer Bone id
---@return integer physBone Physics object id
function BoneToPhysBone(ent, bone)
	local model = ent:GetModel()
	if boneToPhysMap[model] and boneToPhysMap[model][bone] then
		return boneToPhysMap[model][bone]
	else
		boneToPhysMap[model] = boneToPhysMap[model] or {}
		for i = 0, ent:GetPhysicsObjectCount() - 1 do
			local b = ent:TranslatePhysBoneToBone(i)
			if bone == b then
				boneToPhysMap[model][b] = i
				return i
			end
		end
		boneToPhysMap[model][bone] = -1
		return -1
	end
end
