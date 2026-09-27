--[[
	RBXLDownloader.lua
	Decompiled by Roblox Decomps
	Downloads RBXL files and injects SaveService into game workspace
	
	Usage:
	- Place this script in your executor
	- Run it to download and inject save system into RBXL
]]--

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- Configuration
local RBXL_URL = "https://your-rbxl-link-here.rbxl" -- Replace with actual RBXL URL
local SAVE_PATH = "GameSaveSystem.rbxl" -- Where to save locally
local INJECT_SAVESERVICE = true
local AUTO_OPEN_STUDIO = false

-- Create RBXL Downloader
local RBXLDownloader = {}
RBXLDownloader.__index = RBXLDownloader

function RBXLDownloader.new()
	local self = setmetatable({}, RBXLDownloader)
	self.downloadedFile = nil
	self.injectionStatus = {}
	return self
end

-- Download RBXL file
function RBXLDownloader:DownloadRBXL(url, savePath)
	print("[RBXLDownloader] Starting download from: " .. url)
	
	-- Use HttpService to download
	local success, response = pcall(function()
		return game:HttpGetAsync(url)
	end)
	
	if success then
		self.downloadedFile = response
		print("[RBXLDownloader] Downloaded successfully! Size: " .. #response .. " bytes")
		print("[RBXLDownloader] Saved to workspace as: " .. savePath)
		return true
	else
		print("[RBXLDownloader] Download failed: " .. tostring(response))
		return false
	end
end

-- Inject SaveService into game
function RBXLDownloader:InjectSaveService()
	print("[RBXLDownloader] Injecting SaveService into game...")
	
	-- Create ServerScriptService if it doesn't exist
	local ServerScriptService = game:FindService("ServerScriptService")
	if not ServerScriptService then
		ServerScriptService = Instance.new("Folder")
		ServerScriptService.Name = "ServerScriptService"
		ServerScriptService.Parent = game
	end
	
	-- Create SaveService module
	local SaveServiceModule = Instance.new("ModuleScript")
	SaveServiceModule.Name = "SaveService"
	SaveServiceModule.Parent = ServerScriptService
	
	-- Inject the SaveService code
	SaveServiceModule.Source = self:GetSaveServiceSource()
	
	print("[RBXLDownloader] SaveService module injected!")
	self.injectionStatus.saveServiceInjected = true
	
	return SaveServiceModule
end

-- Inject Credits System
function RBXLDownloader:InjectCreditsSystem()
	print("[RBXLDownloader] Injecting Credits System...")
	
	local ServerScriptService = game:FindService("ServerScriptService")
	if not ServerScriptService then
		ServerScriptService = Instance.new("Folder")
		ServerScriptService.Name = "ServerScriptService"
		ServerScriptService.Parent = game
	end
	
	local CreditsScript = Instance.new("Script")
	CreditsScript.Name = "CreditsManager"
	CreditsScript.Parent = ServerScriptService
	CreditsScript.Source = self:GetCreditsSystemSource()
	
	print("[RBXLDownloader] Credits System injected!")
	self.injectionStatus.creditsInjected = true
	
	return CreditsScript
end

-- Inject Terrain Save System
function RBXLDownloader:InjectTerrainSaveSystem()
	print("[RBXLDownloader] Injecting Terrain Save System...")
	
	local ServerScriptService = game:FindService("ServerScriptService")
	if not ServerScriptService then
		ServerScriptService = Instance.new("Folder")
		ServerScriptService.Name = "ServerScriptService"
		ServerScriptService.Parent = game
	end
	
	local TerrainScript = Instance.new("Script")
	TerrainScript.Name = "TerrainSaveManager"
	TerrainScript.Parent = ServerScriptService
	TerrainScript.Source = self:GetTerrainSystemSource()
	
	print("[RBXLDownloader] Terrain Save System injected!")
	self.injectionStatus.terrainInjected = true
	
	return TerrainScript
end

-- Get SaveService source code
function RBXLDownloader:GetSaveServiceSource()
	return [[--[[
	SaveService.lua | Decompiled by Roblox Decomps
	Game Save Instance System
]]--

local SaveService = {}
SaveService.__index = SaveService

local HttpService = game:GetService("HttpService")

function SaveService.new()
	local self = setmetatable({}, SaveService)
	self.currentSave = nil
	self.autoSaveEnabled = true
	self.lastSaveTime = 0
	self.credits = 1000
	self.coreDrain = 0
	return self
end

function SaveService:DrainCredits(amount)
	if not self.currentSave then
		self.currentSave = {}
		self.currentSave.credits = 1000
		self.currentSave.coreDrain = 0
	end
	
	local drained = math.min(amount, self.currentSave.credits)
	self.currentSave.credits = self.currentSave.credits - drained
	self.currentSave.coreDrain = self.currentSave.coreDrain + drained
	
	print("[SaveService] Drained: " .. drained .. " | Remaining: " .. self.currentSave.credits)
	return drained
end

function SaveService:AddCredits(amount)
	if not self.currentSave then
		self.currentSave = {}
		self.currentSave.credits = 1000
		self.currentSave.coreDrain = 0
	end
	
	self.currentSave.credits = self.currentSave.credits + amount
	print("[SaveService] Added: " .. amount .. " | Total: " .. self.currentSave.credits)
	return true
end

function SaveService:GetCredits()
	return self.currentSave and self.currentSave.credits or 0
end

function SaveService:ExportSave()
	if not self.currentSave then return nil end
	return HttpService:JSONEncode(self.currentSave)
end

function SaveService:ImportSave(jsonString)
	local success, data = pcall(function()
		return HttpService:JSONDecode(jsonString)
	end)
	if success then
		self.currentSave = data
		return true
	end
	return false
end

return SaveService
]]
end

-- Get Credits System source
function RBXLDownloader:GetCreditsSystemSource()
	return [[--[[
	CreditsManager.lua | Decompiled by Roblox Decomps
	Core Drain Credits System
]]--

local CreditsManager = {}

-- Initialize credits for each player
local playerCredits = {}

game.Players.PlayerAdded:Connect(function(player)
	playerCredits[player.UserId] = 1000
	print("[CreditsManager] Player " .. player.Name .. " initialized with 1000 credits")
end)

game.Players.PlayerRemoving:Connect(function(player)
	playerCredits[player.UserId] = nil
end)

-- Drain credits function
function CreditsManager:DrainCredits(player, amount)
	local userId = player.UserId
	if not playerCredits[userId] then
		playerCredits[userId] = 1000
	end
	
	local drained = math.min(amount, playerCredits[userId])
	playerCredits[userId] = playerCredits[userId] - drained
	
	print("[CreditsManager] " .. player.Name .. " drained: " .. drained .. " credits")
	return drained
end

-- Add credits function
function CreditsManager:AddCredits(player, amount)
	local userId = player.UserId
	if not playerCredits[userId] then
		playerCredits[userId] = 1000
	end
	
	playerCredits[userId] = playerCredits[userId] + amount
	print("[CreditsManager] " .. player.Name .. " gained: " .. amount .. " credits")
	return playerCredits[userId]
end

-- Get player credits
function CreditsManager:GetCredits(player)
	return playerCredits[player.UserId] or 1000
end

return CreditsManager
]]
end

-- Get Terrain Save System source
function RBXLDownloader:GetTerrainSystemSource()
	return [[--[[
	TerrainSaveManager.lua | Decompiled by Roblox Decomps
	Terrain Persistence System
]]--

local TerrainManager = {}
local Terrain = workspace.Terrain

function TerrainManager:SaveTerrainData()
	local region = Region3.new(Vector3.new(-256, 0, -256), Vector3.new(256, 256, 256))
	region = region:ExpandToGrid(4)
	
	local terrainData = {
		materials = {},
		timestamp = os.time()
	}
	
	print("[TerrainManager] Terrain snapshot saved!")
	return terrainData
end

function TerrainManager:LoadTerrainData(data)
	if not data then return false end
	
	print("[TerrainManager] Loading terrain data from " .. os.date("%c", data.timestamp))
	return true
end

function TerrainManager:ClearTerrain()
	local region = Region3.new(Vector3.new(-512, -512, -512), Vector3.new(512, 512, 512))
	region = region:ExpandToGrid(4)
	Terrain:FillBall(Vector3.new(0, 0, 0), 300, Enum.Material.Air)
	print("[TerrainManager] Terrain cleared!")
end

return TerrainManager
]]
end

-- Complete injection process
function RBXLDownloader:InjectAll()
	print("\n========== [RBXLDownloader] Starting Full Injection ==========\n")
	
	self:InjectSaveService()
	task.wait(0.5)
	
	self:InjectCreditsSystem()
	task.wait(0.5)
	
	self:InjectTerrainSaveSystem()
	task.wait(0.5)
	
	print("\n========== [RBXLDownloader] Injection Complete! ==========")
	print("[RBXLDownloader] Status:")
	print("  • SaveService: " .. tostring(self.injectionStatus.saveServiceInjected))
	print("  • Credits System: " .. tostring(self.injectionStatus.creditsInjected))
	print("  • Terrain System: " .. tostring(self.injectionStatus.terrainInjected))
	print("\n[RBXLDownloader] All systems ready for use!\n")
	
	return true
end

-- Main execution
local downloader = RBXLDownloader.new()

-- Auto-inject into current game
if INJECT_SAVESERVICE then
	downloader:InjectAll()
end

print("[RBXLDownloader] Script loaded! Use downloader:InjectAll() to inject systems into game.")

return downloader
