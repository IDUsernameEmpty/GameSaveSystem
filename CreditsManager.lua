--[[
    CreditsManager.lua
    Decompiled by Roblox Decomps

    Recommended player credits system with core drain support.
]]--

local Players = game:GetService("Players")

local CreditsManager = {}
CreditsManager.__index = CreditsManager

CreditsManager.DEFAULT_CREDITS = 1000
CreditsManager.CORE_DRAIN_PER_SECOND = 1

function CreditsManager.new(saveService)
    local self = setmetatable({}, CreditsManager)
    self.saveService = saveService
    self.playerCredits = {}
    self.playerDrainTimers = {}
    return self
end

function CreditsManager:getPlayerKey(player)
    return tostring(player.UserId)
end

function CreditsManager:initializePlayer(player)
    local key = self:getPlayerKey(player)
    self.playerCredits[key] = self.playerCredits[key] or self.DEFAULT_CREDITS

    if not self.playerDrainTimers[key] then
        self.playerDrainTimers[key] = true
    end
end

function CreditsManager:setCredits(player, amount)
    local key = self:getPlayerKey(player)
    self.playerCredits[key] = math.max(0, amount)
    return self.playerCredits[key]
end

function CreditsManager:getCredits(player)
    local key = self:getPlayerKey(player)
    return self.playerCredits[key] or self.DEFAULT_CREDITS
end

function CreditsManager:addCredits(player, amount)
    local key = self:getPlayerKey(player)
    self.playerCredits[key] = (self.playerCredits[key] or self.DEFAULT_CREDITS) + amount
    return self.playerCredits[key]
end

function CreditsManager:drainCredits(player, amount)
    local key = self:getPlayerKey(player)
    local current = self.playerCredits[key] or self.DEFAULT_CREDITS
    local removed = math.min(current, amount)
    self.playerCredits[key] = current - removed
    return removed
end

function CreditsManager:startCoreDrain(player, interval)
    local key = self:getPlayerKey(player)

    task.spawn(function()
        while self.playerDrainTimers[key] do
            task.wait(interval or 1)
            self:drainCredits(player, self.CORE_DRAIN_PER_SECOND)
        end
    end)
end

function CreditsManager:stopCoreDrain(player)
    local key = self:getPlayerKey(player)
    self.playerDrainTimers[key] = false
end

Players.PlayerAdded:Connect(function(player)
    local manager = CreditsManager
    manager:initializePlayer(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
    CreditsManager:initializePlayer(player)
end

return CreditsManager
