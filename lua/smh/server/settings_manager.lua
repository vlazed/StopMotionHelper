
local MGR = {}

function MGR.CheckSetting(settings, name, entity)
    if IsValid(entity) and settings[entity] then
        return settings[entity][name]
    else
        return settings[name]
    end
end

function MGR.GetSetting(settings, entity)
    if IsValid(entity) and settings[entity] then
        return settings[entity]
    else
        return settings
    end
end


SMH.SettingsManager = MGR