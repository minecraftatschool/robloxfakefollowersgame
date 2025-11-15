-- Earn Followers Game LocalScript with DataStore and Music
-- Place this in StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Configuration
local GAMEPASS_ID = 1530638388
local BASE_FOLLOWERS_PER_MINUTE = 10
local MULTIPLIER_FOLLOWERS = 20

-- Player Data
local followers = 0
local hasGamepass = false
local playTime = 0
local lastUpdate = tick()
local antiAFKEnabled = false

-- Wait for RemoteEvents to be created by server
local saveEvent
local loadEvent

local function waitForRemoteEvents()
	local maxWait = 10
	local waited = 0

	while (not saveEvent or not loadEvent) and waited < maxWait do
		saveEvent = ReplicatedStorage:FindFirstChild("SaveFollowers")
		loadEvent = ReplicatedStorage:FindFirstChild("LoadFollowers")
		if not saveEvent or not loadEvent then
			wait(0.1)
			waited = waited + 0.1
		end
	end

	if not saveEvent or not loadEvent then
		warn("RemoteEvents not found! Make sure the server script is running.")
	else
		print("RemoteEvents found successfully!")
	end
end

-- Create background music
local function setupMusic()
	local sound = Instance.new("Sound")
	sound.Name = "BackgroundMusic"
	sound.SoundId = "rbxasset://sounds/Relaxed Scene.mp3" -- Classic Roblox Relaxed Scene
	sound.Volume = 0.3
	sound.Looped = true
	sound.Parent = game.Workspace
	sound:Play()

	print("Background music started!")
end

-- Check if player owns gamepass
local function checkGamepass()
	if GAMEPASS_ID == 0 then
		warn("Gamepass ID not set!")
		return false
	end

	local success, owned = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, GAMEPASS_ID)
	end)

	if success then
		return owned
	else
		warn("Failed to check gamepass ownership")
		return false
	end
end

-- Format time function
local function formatTime(seconds)
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = math.floor(seconds % 60)
	return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

-- Format followers with commas
local function formatNumber(num)
	local formatted = tostring(num)
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if k == 0 then
			break
		end
	end
	return formatted
end

-- Save data function
local function saveData()
	if not saveEvent then
		warn("SaveEvent not found! Cannot save data.")
		return
	end

	local success, err = pcall(function()
		saveEvent:FireServer(followers, playTime)
	end)

	if success then
		print("Data saved successfully! Followers: " .. followers .. ", PlayTime: " .. playTime)
	else
		warn("Failed to save data: " .. tostring(err))
	end
end

-- Load data function
local function loadData()
	if not loadEvent then
		warn("LoadEvent not found! Cannot load data.")
		return
	end

	local success, data = pcall(function()
		return loadEvent:InvokeServer()
	end)

	if success and data then
		followers = data.Followers or 0
		playTime = data.PlayTime or 0
		print("Data loaded successfully! Followers: " .. followers .. ", PlayTime: " .. playTime)
	else
		warn("Failed to load data: " .. tostring(data))
		print("Starting with fresh data")
	end
end

-- Create GUI
local function createGUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "FollowersGUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	-- Open Button (to reopen GUI)
	local openButton = Instance.new("TextButton")
	openButton.Name = "OpenButton"
	openButton.Size = UDim2.new(0, 80, 0, 40)
	openButton.Position = UDim2.new(0, 10, 0, 10)
	openButton.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
	openButton.BorderSizePixel = 0
	openButton.Text = "Open"
	openButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	openButton.TextSize = 18
	openButton.Font = Enum.Font.GothamBold
	openButton.Visible = false
	openButton.Parent = screenGui

	local openCorner = Instance.new("UICorner")
	openCorner.CornerRadius = UDim.new(0, 10)
	openCorner.Parent = openButton

	-- Main Frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 300, 0, 265)
	mainFrame.Position = UDim2.new(0.5, -150, 0.5, -132.5)
	mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = mainFrame

	-- Title Bar (for dragging)
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 40)
	titleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = mainFrame

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 12)
	titleCorner.Parent = titleBar

	-- Fix for bottom corners
	local titleBarFix = Instance.new("Frame")
	titleBarFix.Size = UDim2.new(1, 0, 0, 12)
	titleBarFix.Position = UDim2.new(0, 0, 1, -12)
	titleBarFix.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
	titleBarFix.BorderSizePixel = 0
	titleBarFix.Parent = titleBar

	-- Title Text
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -40, 1, 0)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "📱 Follower Stats"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 20
	title.Font = Enum.Font.GothamBold
	title.Parent = titleBar

	-- Close Button (X)
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 35, 0, 35)
	closeButton.Position = UDim2.new(1, -38, 0, 2.5)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.BorderSizePixel = 0
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextSize = 20
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = titleBar

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeButton

	-- Followers Label
	local followersLabel = Instance.new("TextLabel")
	followersLabel.Name = "FollowersLabel"
	followersLabel.Size = UDim2.new(1, -20, 0, 35)
	followersLabel.Position = UDim2.new(0, 10, 0, 50)
	followersLabel.BackgroundTransparency = 1
	followersLabel.Text = "Followers: 0"
	followersLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
	followersLabel.TextSize = 18
	followersLabel.Font = Enum.Font.GothamBold
	followersLabel.TextXAlignment = Enum.TextXAlignment.Left
	followersLabel.Parent = mainFrame

	-- Rate Label
	local rateLabel = Instance.new("TextLabel")
	rateLabel.Name = "RateLabel"
	rateLabel.Size = UDim2.new(1, -20, 0, 30)
	rateLabel.Position = UDim2.new(0, 10, 0, 90)
	rateLabel.BackgroundTransparency = 1
	rateLabel.Text = "Rate: 10/min"
	rateLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
	rateLabel.TextSize = 16
	rateLabel.Font = Enum.Font.Gotham
	rateLabel.TextXAlignment = Enum.TextXAlignment.Left
	rateLabel.Parent = mainFrame

	-- Play Time Label
	local playTimeLabel = Instance.new("TextLabel")
	playTimeLabel.Name = "PlayTimeLabel"
	playTimeLabel.Size = UDim2.new(1, -20, 0, 30)
	playTimeLabel.Position = UDim2.new(0, 10, 0, 125)
	playTimeLabel.BackgroundTransparency = 1
	playTimeLabel.Text = "Play Time: 00:00:00"
	playTimeLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
	playTimeLabel.TextSize = 16
	playTimeLabel.Font = Enum.Font.Gotham
	playTimeLabel.TextXAlignment = Enum.TextXAlignment.Left
	playTimeLabel.Parent = mainFrame

	-- 2x Gamepass Button (only show if don't have it)
	local gamepassButton = Instance.new("TextButton")
	gamepassButton.Name = "GamepassButton"
	gamepassButton.Size = UDim2.new(1, -20, 0, 35)
	gamepassButton.Position = UDim2.new(0, 10, 0, 165)
	gamepassButton.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
	gamepassButton.BorderSizePixel = 0
	gamepassButton.Text = "🚀 Get 2x Gamepass!"
	gamepassButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	gamepassButton.TextSize = 16
	gamepassButton.Font = Enum.Font.GothamBold
	gamepassButton.Parent = mainFrame

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = gamepassButton

	-- Anti-AFK Toggle Button
	local antiAFKButton = Instance.new("TextButton")
	antiAFKButton.Name = "AntiAFKButton"
	antiAFKButton.Size = UDim2.new(1, -20, 0, 35)
	antiAFKButton.Position = UDim2.new(0, 10, 0, 210)
	antiAFKButton.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
	antiAFKButton.BorderSizePixel = 0
	antiAFKButton.Text = "⚡ Anti-AFK: OFF"
	antiAFKButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	antiAFKButton.TextSize = 16
	antiAFKButton.Font = Enum.Font.GothamBold
	antiAFKButton.Parent = mainFrame

	local antiAFKCorner = Instance.new("UICorner")
	antiAFKCorner.CornerRadius = UDim.new(0, 8)
	antiAFKCorner.Parent = antiAFKButton

	-- Make draggable
	local dragging = false
	local dragInput, mousePos, framePos

	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			mousePos = input.Position
			framePos = mainFrame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	titleBar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - mousePos
			mainFrame.Position = UDim2.new(
				framePos.X.Scale,
				framePos.X.Offset + delta.X,
				framePos.Y.Scale,
				framePos.Y.Offset + delta.Y
			)
		end
	end)

	-- Close and Open button functionality
	closeButton.MouseButton1Click:Connect(function()
		mainFrame.Visible = false
		openButton.Visible = true
	end)

	openButton.MouseButton1Click:Connect(function()
		mainFrame.Visible = true
		openButton.Visible = false
	end)

	return screenGui, followersLabel, rateLabel, playTimeLabel, gamepassButton, antiAFKButton
end

-- Update GUI
local gui, followersLabel, rateLabel, playTimeLabel, gamepassButton, antiAFKButton = createGUI()

-- Wait 1 second for UI to fully load
wait(1)

-- Wait for RemoteEvents from server
waitForRemoteEvents()

local function updateGUI()
	followersLabel.Text = "Followers: " .. formatNumber(followers)

	local rate = hasGamepass and MULTIPLIER_FOLLOWERS or BASE_FOLLOWERS_PER_MINUTE
	local multiplierText = hasGamepass and " (2x Active!)" or ""
	rateLabel.Text = "Rate: " .. rate .. "/min" .. multiplierText

	playTimeLabel.Text = "Play Time: " .. formatTime(playTime)

	-- Hide gamepass button if owned
	gamepassButton.Visible = not hasGamepass
end

-- Prompt gamepass purchase
gamepassButton.MouseButton1Click:Connect(function()
	if GAMEPASS_ID == 0 then
		warn("Please set a valid Gamepass ID!")
		return
	end

	MarketplaceService:PromptGamePassPurchase(player, GAMEPASS_ID)
end)

-- Handle gamepass purchase
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(plr, gamepassId, wasPurchased)
	if plr == player and gamepassId == GAMEPASS_ID and wasPurchased then
		hasGamepass = true
		updateGUI()
	end
end)

-- Anti-AFK Toggle
antiAFKButton.MouseButton1Click:Connect(function()
	antiAFKEnabled = not antiAFKEnabled

	if antiAFKEnabled then
		antiAFKButton.Text = "⚡ Anti-AFK: ON"
		antiAFKButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
	else
		antiAFKButton.Text = "⚡ Anti-AFK: OFF"
		antiAFKButton.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
	end
end)

-- Anti-AFK System
spawn(function()
	local VirtualUser = game:GetService("VirtualUser")

	player.Idled:Connect(function()
		if antiAFKEnabled then
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
			print("Anti-AFK activated!")
		end
	end)
end)

-- Setup background music
setupMusic()

-- Load data on start
loadData()

-- Initialize gamepass check
hasGamepass = checkGamepass()
updateGUI()

-- Main loop for followers gain
spawn(function()
	while true do
		wait(60) -- Wait 1 minute

		if hasGamepass then
			followers = followers + MULTIPLIER_FOLLOWERS
		else
			followers = followers + BASE_FOLLOWERS_PER_MINUTE
		end

		updateGUI()
		saveData() -- Save after gaining followers
	end
end)

-- Play time counter
spawn(function()
	while true do
		wait(1)
		local currentTime = tick()
		playTime = playTime + (currentTime - lastUpdate)
		lastUpdate = currentTime
		updateGUI()
	end
end)

-- Auto-save every 30 seconds
spawn(function()
	while true do
		wait(30)
		saveData()
	end
end)

-- Save when player leaves
game.Players.PlayerRemoving:Connect(function(plr)
	if plr == player then
		saveData()
	end
end)

print("Earn Followers Game loaded successfully!")