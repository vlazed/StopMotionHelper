-- Bone translation functions, so we can change their functionality here in case the original ones fuck up even more

---@type {[string]: {[integer]: integer}}
local bonePhysBoneParents = {}

---@param entity Entity Entity to translate bone
---@param bone integer Bone id
---@return integer physBone Physics object id
function GetPhysBoneParentFromBone(entity, bone)
	local model = entity:GetModel()
	if bonePhysBoneParents[model] and bonePhysBoneParents[model][bone] then
		return bonePhysBoneParents[model][bone]
	end	
	bonePhysBoneParents[model] = bonePhysBoneParents[model] or {}
	local b = bone
	local i = 1
	local bones = {}
	while true do
		b = entity:GetBoneParent(b)
		local parent = BoneToPhysBone(entity, b)
		if parent >= 0 and parent ~= bone then
			bonePhysBoneParents[model][bone] = parent
			for c = 1, #bones do
				bonePhysBoneParents[model][c] = parent
			end
			return parent
		end
		table.insert(bones, b)
		i = i + 1
		if i > 128 then --We've gone through all possible bones, so we get out.
			break
		end
	end
	bonePhysBoneParents[model][bone] = -1
	return -1
end

---@type {[string]: {[integer]: integer}}
local physBoneParents = {}

---@param entity Entity Entity to translate bone
---@param bone integer Physics object id
---@return integer physBone Parent physics object id
function GetPhysBoneParent(entity, bone)
	local model = entity:GetModel()
	if physBoneParents[model] and physBoneParents[model][bone] then
		return physBoneParents[model][bone]
	end
	physBoneParents[model] = physBoneParents[model] or {}
	local b = PhysBoneToBone(entity, bone)
	local i = 1
	while true do
		b = entity:GetBoneParent(b)
		local parent = BoneToPhysBone(entity, b)
		if parent >= 0 and parent ~= bone then
			physBoneParents[model][bone] = parent
			return parent
		end
		i = i + 1
		if i > 128 then --We've gone through all possible bones, so we get out.
			break
		end
	end
	physBoneParents[model][bone] = -1
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
