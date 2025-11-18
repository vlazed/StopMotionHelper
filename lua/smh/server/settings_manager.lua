
---@type {[Player]: Settings}
local PlayerSettings = {}

local MGR = {}

---@param player Player
---@param settings Settings
function MGR.StorePlayerSettings(player, settings)
    PlayerSettings[player] = settings
end

---@param player Player
---@return Settings
function MGR.GetPlayerSettings(player)
    return PlayerSettings[player]
end

---@param settings Settings
---@param name string
---@param entity Entity
---@return any
function MGR.CheckSetting(settings, name, entity)
    if IsValid(entity) and settings[entity] then
        return settings[entity][name]
    else
        return settings[name]
    end
end

---@param settings Settings
---@param entity Entity
---@return Settings
function MGR.GetSetting(settings, entity)
    if IsValid(entity) and settings[entity] then
        return settings[entity]
    else
        return settings
    end
end


SMH.SettingsManager = MGR