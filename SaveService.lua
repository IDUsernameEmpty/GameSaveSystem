--[[
    SaveService.lua
    Decompiled by Roblox Decomps

    Recommended Roblox save system for:
    - player credits
    - terrain changes
    - autosave
    - backups
    - versioned saves
]]--

local SaveService = {}
SaveService.__index = SaveService

local HttpService = game:GetService("HttpService")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

SaveService.DEFAULT_SAVE_NAME = "PlayerWorldSave"
SaveService.AUTO_SAVE_INTERVAL = 120
SaveService.BACKUP_LIMIT = 5
SaveService.SAVE_VERSION = 1

function SaveService.new(dataStoreName)
    local self = setmetatable({}, SaveService)
    self.dataStoreName = dataStoreName or self.DEFAULT_SAVE_NAME
    self.dataStore = DataStoreService:GetDataStore(self.dataStoreName)
    self.cache = {}
    self.isStudio = RunService:IsStudio()
    self.autoSaveThread = nil
    self.autoSaveEnabled = false
    return self
end

function SaveService:deepCopy(source)
    if type(source) ~= "table" then
        return source
    end

    local copy = {}
    for key, value in pairs(source) do
        copy[key] = self:deepCopy(value)
    end
    return copy
end

function SaveService:makeBackupKey(saveName)
    return saveName .. "_backup_" .. os.time()
end

function SaveService:createSaveData()
    return {
        version = self.SAVE_VERSION,
        timestamp = os.time(),
        credits = 1000,
        coreDrain = 0,
        terrain = {},
        world = {},
        players = {},
    }
end

function SaveService:serialize(data)
    return HttpService:JSONEncode(data)
end

function SaveService:deserialize(raw)
    if type(raw) ~= "string" or raw == "" then
        return nil
    end

    local success, decoded = pcall(function()
        return HttpService:JSONDecode(raw)
    end)

    if not success then
        return nil
    end

    return decoded
end

function SaveService:saveToDataStore(player, saveName, data)
    local key = player and player.UserId or saveName
    local encoded = self:serialize(data)

    local success, result = pcall(function()
        return self.dataStore:SetAsync(key, encoded)
    end)

    if not success then
        warn("[SaveService] Save failed for key " .. tostring(key) .. ": " .. tostring(result))
        return false
    end

    return true
end

function SaveService:loadFromDataStore(player, saveName)
    local key = player and player.UserId or saveName

    local success, result = pcall(function()
        return self.dataStore:GetAsync(key)
    end)

    if not success then
        warn("[SaveService] Load failed for key " .. tostring(key) .. ": " .. tostring(result))
        return nil
    end

    if type(result) ~= "string" then
        return nil
    end

    return self:deserialize(result)
end

function SaveService:saveWorldSnapshot(saveName, worldState)
    local save = self:createSaveData()
    save.world = self:deepCopy(worldState or {})
    save.timestamp = os.time()

    self.cache[saveName] = save
    return save
end

function SaveService:saveTerrainSnapshot(saveName, terrainState)
    local current = self.cache[saveName] or self:createSaveData()
    current.terrain = self:deepCopy(terrainState or {})
    current.timestamp = os.time()
    self.cache[saveName] = current
    return current
end

function SaveService:savePlayerProgress(player, saveName, progressData)
    local save = self.cache[saveName] or self:createSaveData()
    save.players[player.UserId] = self:deepCopy(progressData or {})
    save.timestamp = os.time()
    self.cache[saveName] = save

    return save
end

function SaveService:loadPlayerProgress(player, saveName)
    local save = self.cache[saveName]
    if save and save.players and save.players[player.UserId] then
        return self:deepCopy(save.players[player.UserId])
    end

    return nil
end

function SaveService:writeSave(saveName, data)
    local encoded = self:serialize(data)
    local backupKey = self:makeBackupKey(saveName)

    local current = self:loadFromDataStore(nil, saveName)
    if current then
        local backupSaved, backupResult = pcall(function()
            return self.dataStore:SetAsync(backupKey, self:serialize(current))
        end)

        if not backupSaved then
            warn("[SaveService] Backup failed: " .. tostring(backupResult))
        end
    end

    local success, result = pcall(function()
        return self.dataStore:SetAsync(saveName, encoded)
    end)

    if not success then
        warn("[SaveService] WriteSave failed: " .. tostring(result))
        return false
    end

    return true
end

function SaveService:readSave(saveName)
    local success, result = pcall(function()
        return self.dataStore:GetAsync(saveName)
    end)

    if not success then
        warn("[SaveService] readSave failed: " .. tostring(result))
        return nil
    end

    if type(result) ~= "string" then
        return nil
    end

    return self:deserialize(result)
end

function SaveService:drainCredits(saveName, amount)
    local save = self.cache[saveName] or self:createSaveData()
    save.credits = math.max(0, (save.credits or 0) - amount)
    save.coreDrain = (save.coreDrain or 0) + amount
    save.timestamp = os.time()
    self.cache[saveName] = save
    return save.credits
end

function SaveService:addCredits(saveName, amount)
    local save = self.cache[saveName] or self:createSaveData()
    save.credits = (save.credits or 0) + amount
    save.timestamp = os.time()
    self.cache[saveName] = save
    return save.credits
end

function SaveService:getCredits(saveName)
    local save = self.cache[saveName] or self:createSaveData()
    return save.credits or 0
end

function SaveService:startAutoSave(saveName, interval)
    if self.autoSaveEnabled then
        return
    end

    self.autoSaveEnabled = true
    self.autoSaveThread = task.spawn(function()
        while self.autoSaveEnabled do
            task.wait(interval or self.AUTO_SAVE_INTERVAL)
            if self.cache[saveName] then
                self:writeSave(saveName, self.cache[saveName])
            end
        end
    end)
end

function SaveService:stopAutoSave()
    self.autoSaveEnabled = false
    if self.autoSaveThread then
        task.cancel(self.autoSaveThread)
        self.autoSaveThread = nil
    end
end

function SaveService:hasValidSave(data)
    if type(data) ~= "table" then
        return false
    end

    if type(data.version) ~= "number" then
        return false
    end

    return true
end

return SaveService
