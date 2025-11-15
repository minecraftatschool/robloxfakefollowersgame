-- Earn Followers Game Server Script
-- Place this in ServerScriptService

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FollowersDataStore = DataStoreService:GetDataStore("FollowersData_v1")

-- Create RemoteEvents for communication
local saveEvent = Instance.new("RemoteEvent")
saveEvent.Name = "SaveFollowers"
saveEvent.Parent = ReplicatedStorage

local loadEvent = Instance.new("RemoteFunction")
loadEvent.Name = "LoadFollowers"
loadEvent.Parent = ReplicatedStorage

-- Save player data
saveEvent.OnServerEvent:Connect(function(player, followers, playTime)
	local success, errorMsg = pcall(function()
		local data = {
			Followers = followers,
			PlayTime = playTime
		}

		FollowersDataStore:SetAsync("Player_" .. player.UserId, data)
		print("Data saved for " .. player.Name)
	end)

	if not success then
		warn("Failed to save data for " .. player.Name .. ": " .. tostring(errorMsg))
	end
end)

-- Load player data
loadEvent.OnServerInvoke = function(player)
	local success, data = pcall(function()
		return FollowersDataStore:GetAsync("Player_" .. player.UserId)
	end)

	if success and data then
		print("Data loaded for " .. player.Name)
		return data
	else
		print("No saved data found for " .. player.Name)
		return {Followers = 0, PlayTime = 0}
	end
end

-- Auto-save all players every 5 minutes
game:GetService("RunService").Heartbeat:Connect(function()
	wait(300) -- 5 minutes

	for _, player in pairs(game.Players:GetPlayers()) do
		-- Players will handle their own saving through the RemoteEvent
		print("Auto-save reminder for " .. player.Name)
	end
end)

-- Save data when player leaves
game.Players.PlayerRemoving:Connect(function(player)
	print("Player leaving, ensure data is saved: " .. player.Name)
end)

print("Followers DataStore server loaded!")