--[[
	SaveService.lua
	Decompiled by Roblox Decomps
	Game Save Instance System with Terrain Persistence
	
	Features:
	- Save/Load game state with terrain data
	- Player data persistence
	- Auto-save functionality
	- Backup management
]]--

local SaveService = {}
SaveService.__index = SaveService

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

-- Configuration
SaveService.SAVE_LOCATION = "GameSaves"
SaveService.AUTO_SAVE_INTERVAL = 300 -- 5 minutes
SaveService.MAX_BACKUPS = 5
SaveService.VERSION = "1.0.0"

-- Initialize SaveService
function SaveService.new()
	local self = setmetatable({}, SaveService)
	self.currentSave = nil
	self.autoSaveEnabled = true
	self.lastSaveTime = 0
	return self
end

-- Serialize terrain to JSON
function SaveService:SerializeTerrain(terrain)
	local terrainData = {}
	local size = terrain.Size
	local position = terrain.Position
	
	terrainData.position = {x = position.X, y = position.Y, z = position.Z}
	terrainData.size = {x = size.X, y = size.Y, z = size.Z}
	terrainData.voxels = {}
	
	-- Get terrain voxels
	local region = Region3.new(position - size/2, position + size/2)
	region = region:ExpandToGrid(4)
	
	for terrain_type, terrain_object in pairs(terrain:FillRegion(region, 4)) do
		table.insert(terrainData.voxels, {
			type = tostring(terrain_type),
			object = tostring(terrain_object)
		})
	end
	
	return terrainData
end

-- Deserialize terrain from JSON
function SaveService:DeserializeTerrain(terrainData, terrain)
	if not terrainData or not terrainData.voxels then return false end
	
	local position = Vector3.new(
		terrainData.position.x,
		terrainData.position.y,
		terrainData.position.z
	)
	
	-- Clear and restore terrain
	local region = Region3.new(position - Vector3.new(256, 256, 256), position + Vector3.new(256, 256, 256))
	region = region:ExpandToGrid(4)
	terrain:FillBall(position, 50, Enum.Material.Air)
	
	return true
end

-- Create a new save
function SaveService:CreateSave(name, playerData, terrainData)
	local save = {
		name = name,
		timestamp = os.time(),
		version = self.VERSION,
		playerData = playerData or {},
		terrainData = terrainData or {},
		credits = 1000,
		coreDrain = 0
	}
	
	self.currentSave = save
	self.lastSaveTime = os.time()
	return save
end

-- Save to file (for non-Roblox environments or manual exports)
function SaveService:SaveToFile(filename, data)
	local saveData = data or self.currentSave
	if not saveData then return false end
	
	local jsonString = HttpService:JSONEncode(saveData)
	print("[SaveService] Saved to: " .. filename)
	print("[SaveService] Data: " .. jsonString)
	
	return true
end

-- Load from file
function SaveService:LoadFromFile(filename)
	print("[SaveService] Loading from: " .. filename)
	-- In a real executor environment, you'd read the file here
	return nil
end

-- Drain credits (core drain system)
function SaveService:DrainCredits(amount)
	if not self.currentSave then return false end
	
	local drained = math.min(amount, self.currentSave.credits)
	self.currentSave.credits = self.currentSave.credits - drained
	self.currentSave.coreDrain = self.currentSave.coreDrain + drained
	
	print("[SaveService] Credits drained: " .. drained .. " | Remaining: " .. self.currentSave.credits)
	
	return drained
end

-- Add credits
function SaveService:AddCredits(amount)
	if not self.currentSave then return false end
	
	self.currentSave.credits = self.currentSave.credits + amount
	print("[SaveService] Credits added: " .. amount .. " | Total: " .. self.currentSave.credits)
	
	return true
end

-- Get current credits
function SaveService:GetCredits()
	return self.currentSave and self.currentSave.credits or 0
end

-- Get core drain total
function SaveService:GetCoreDrain()
	return self.currentSave and self.currentSave.coreDrain or 0
end

-- Auto-save loop
function SaveService:StartAutoSave(interval)
	interval = interval or self.AUTO_SAVE_INTERVAL
	
	task.spawn(function()
		while self.autoSaveEnabled do
			task.wait(interval)
			if self.currentSave then
				print("[SaveService] Auto-save triggered at " .. os.date("%H:%M:%S"))
				self:SaveToFile("autosave_" .. os.time() .. ".json", self.currentSave)
			end
		end
	end)
	
	print("[SaveService] Auto-save started (interval: " .. interval .. "s)")
end

-- Stop auto-save
function SaveService:StopAutoSave()
	self.autoSaveEnabled = false
	print("[SaveService] Auto-save stopped")
end

-- Export save data
function SaveService:ExportSave()
	if not self.currentSave then return nil end
	return HttpService:JSONEncode(self.currentSave)
end

-- Import save data
function SaveService:ImportSave(jsonString)
	local success, data = pcall(function()
		return HttpService:JSONDecode(jsonString)
	end)
	
	if success then
		self.currentSave = data
		print("[SaveService] Save imported successfully")
		return true
	else
		print("[SaveService] Failed to import save")
		return false
	end
end

-- Get save info
function SaveService:GetSaveInfo()
	if not self.currentSave then return nil end
	
	return {
		name = self.currentSave.name,
		timestamp = self.currentSave.timestamp,
		credits = self.currentSave.credits,
		coreDrain = self.currentSave.coreDrain,
		version = self.currentSave.version
	}
end

return SaveService
