-- Place this in ServerScriptService

local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create RemoteEvent for communication
local remoteEvent = Instance.new("RemoteEvent")
remoteEvent.Name = "PSRemoteEvent"
remoteEvent.Parent = ReplicatedStorage

-- Handle private server creation
remoteEvent.OnServerEvent:Connect(function(player)
	print("Player " .. player.Name .. " requested private server")
	local placeId = game.PlaceId

	local success, result = pcall(function()
		return TeleportService:ReserveServer(placeId)
	end)

	if success then
		print("Reserved server with code: " .. result)
		local teleportSuccess, teleportError = pcall(function()
			TeleportService:TeleportToPrivateServer(placeId, result, {player})
		end)

		if not teleportSuccess then
			warn("Teleport failed: " .. tostring(teleportError))
		end
	else
		warn("Failed to reserve server: " .. tostring(result))
	end
end)