--[[
    TerrainSaveManager.lua
    Decompiled by Roblox Decomps

    Recommended terrain system for game saves.
    This saves a list of terrain changes instead of trying to serialize the full terrain object.
]]--

local TerrainSaveManager = {}
TerrainSaveManager.__index = TerrainSaveManager

function TerrainSaveManager.new(saveService)
    local self = setmetatable({}, TerrainSaveManager)
    self.saveService = saveService
    self.terrainChanges = {}
    return self
end

function TerrainSaveManager:recordCellChange(position, material, materialVariant)
    local entry = {
        x = math.floor(position.X),
        y = math.floor(position.Y),
        z = math.floor(position.Z),
        material = tostring(material or Enum.Material.Air),
        materialVariant = materialVariant or 0,
        timestamp = os.time(),
    }

    table.insert(self.terrainChanges, entry)
    return entry
end

function TerrainSaveManager:saveTerrain(saveName)
    local snapshot = {
        changes = self.terrainChanges,
        timestamp = os.time(),
    }

    if self.saveService then
        self.saveService:saveTerrainSnapshot(saveName, snapshot)
    end

    return snapshot
end

function TerrainSaveManager:loadTerrain(saveName, terrainState)
    local data = terrainState or {}
    if not data.changes then
        return false
    end

    for _, cell in ipairs(data.changes) do
        local v3 = Vector3.new(cell.x, cell.y, cell.z)
        if workspace.Terrain then
            workspace.Terrain:SetCell(v3.X, v3.Y, v3.Z, Enum.Material.SmoothPlastic)
        end
    end

    return true
end

return TerrainSaveManager
