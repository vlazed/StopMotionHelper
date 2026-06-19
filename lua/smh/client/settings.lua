---@enum ConVarType
local ConVarType = {
    Bool = 1,
    Int = 2,
    Float = 3,
}

local GhostVars = {
    smh_ghostprevframe = "GhostPrevFrame",
    smh_ghostnextframe = "GhostNextFrame",
    smh_ghostallentities = "GhostAllEntities",
    smh_ghosttransparency = "GhostTransparency",
    smh_onionskin = "OnionSkin",
    smh_ghostxray = "GhostXRay",
}

---@class TypedConVar
---@field Type ConVarType
---@field ConVar ConVar
---@field Global boolean
local TYPED_CV = {}
TYPED_CV.__index = TYPED_CV

function TYPED_CV:GetValue()
    if self.Type == ConVarType.Bool then
        return self.ConVar:GetBool()
    elseif self.Type == ConVarType.Int then
        return self.ConVar:GetInt()
    elseif self.Type == ConVarType.Float then
        return self.ConVar:GetFloat()
    end
end

function TYPED_CV:GetDefault()
    if self.Type == ConVarType.Bool then
        return tobool(self.ConVar:GetDefault())
    elseif self.Type == ConVarType.Int then
        return tonumber(self.ConVar:GetDefault())
    elseif self.Type == ConVarType.Float then
        return tonumber(self.ConVar:GetDefault())
    end
end

function TYPED_CV:SetValue(value)
    if self.Type == ConVarType.Bool then
        return self.ConVar:SetBool(value)
    elseif self.Type == ConVarType.Int then
        return self.ConVar:SetInt(value)
    elseif self.Type == ConVarType.Float then
        return self.ConVar:SetFloat(value)
    end
end

---@param type ConVarType
---@param name string
---@param defaultValue any
---@param helptext string?
---@param userInfo boolean?
---@param isGlobal boolean?
---@return TypedConVar
local function CreateTypedConVar(type, name, defaultValue, helptext, userInfo, isGlobal)
    if type == ConVarType.Bool then
        defaultValue = tostring(defaultValue and 1 or 0)
    elseif type == ConVarType.Int then
        defaultValue = tostring(defaultValue)
    elseif type == ConVarType.Float then
        defaultValue = tostring(defaultValue)
    end

    local cv = {
        Type = type,
        Global = userInfo,
        ConVar = CreateClientConVar(name, defaultValue, true, Either(userInfo ~= nil, userInfo, false), helptext, nil, nil),
    }
    setmetatable(cv, TYPED_CV)

    if GhostVars[name] then
        cvars.AddChangeCallback(name, function(convar, oldvalue, newvalue)
            if oldvalue == newvalue then return end

            SMH.Controller.UpdateUISetting(GhostVars[name], newvalue)
            SMH.Controller.UpdateGhostState()
        end)
    end

    return cv
end

---@type {[Entity]: Settings}
local EntitySettings = {}

---@type {[string]: TypedConVar}
local ConVars = {
    FreezeAll = CreateTypedConVar(ConVarType.Bool, "smh_freezeall", true),
    LocalizePhysBones = CreateTypedConVar(ConVarType.Bool, "smh_localizephysbones", false),
    IgnorePhysBones = CreateTypedConVar(ConVarType.Bool, "smh_ignorephysbones", false),
    GhostPrevFrame = CreateTypedConVar(ConVarType.Bool, "smh_ghostprevframe", false),
    GhostNextFrame = CreateTypedConVar(ConVarType.Bool, "smh_ghostnextframe", false),
    GhostAllEntities = CreateTypedConVar(ConVarType.Bool, "smh_ghostallentities", false),
    GhostXRay = CreateTypedConVar(ConVarType.Bool, "smh_ghostxray", false),
    GhostTransparency = CreateTypedConVar(ConVarType.Float, "smh_ghosttransparency", 0.5),
    OnionSkin = CreateTypedConVar(ConVarType.Bool, "smh_onionskin", false),
    TweenDisable = CreateTypedConVar(ConVarType.Bool, "smh_tweendisable", false),
    SmoothPlayback = CreateTypedConVar(ConVarType.Bool, "smh_smoothplayback", false),
    EnableWorld = CreateTypedConVar(ConVarType.Bool, "smh_enableworldkeyframes", false, nil, true),
    EnablePhysBake = CreateTypedConVar(ConVarType.Bool, "smh_enablephysbake", false, "When enabled, it will disable loading keyframes from the Physical Bone modifier, to enable baking the body modifiers")
}

local InitialSettings = {}
for name, convar in pairs(ConVars) do
    InitialSettings[name] = convar:GetDefault()
end

---@type {[string]: TypedConVar}
local Globals = {}
for name, convar in pairs(ConVars) do
    if convar.Global then
        Globals[name] = convar
    end
end 

local MGR = {}

local function initializeSetting(entity)
    EntitySettings[entity] = table.Copy(InitialSettings)
end

function MGR.Initialize(entity, settings)
    if IsValid(entity) then
        for name, convar in pairs(ConVars) do
            if not EntitySettings[entity] then
                initializeSetting(entity)
            end
            EntitySettings[entity][name] = Either(settings[name] ~= nil, settings[name], convar:GetValue())
        end
    end
end

function MGR.GetGlobals()
    return Globals
end

---@param isSave boolean?
---@return Settings
function MGR.GetAll(isSave)
    local settings = {}

    for name, convar in pairs(ConVars) do
        settings[name] = convar:GetValue()
    end

    if GetConVar("smh_entity_settings"):GetBool() then
        local newSettings = table.Merge(EntitySettings, not isSave and settings or {})
        return newSettings
    end

    return settings
end

function MGR.Update(newSettings, entities)
    for name, value in pairs(newSettings) do
        local convar = ConVars[name]
        if not convar then
            continue
        end

        if not convar.Global and istable(entities) and GetConVar("smh_entity_settings"):GetBool() then
            for entity, _ in pairs(entities) do
                if IsValid(entity) then
                    if not EntitySettings[entity] then
                        initializeSetting(entity)
                    end
                    EntitySettings[entity][name] = value
                end
            end
        else
            convar:SetValue(value)
        end
    end
end

hook.Add("EntityRemoved", "SMHSettingsEntityRemoved", function(entity)
    EntitySettings[entity] = nil
end)

SMH.Settings = MGR
