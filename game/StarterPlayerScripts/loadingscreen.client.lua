-- Fullscreen NV Loading Screen (Topmost Layer + Spin)
local player = game.Players.LocalPlayer
local runService = game:GetService("RunService")

-- ScreenGui setup
local gui = Instance.new("ScreenGui")
gui.Name = "NVLoading"
gui.IgnoreGuiInset = true -- covers topbar
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui.DisplayOrder = 999999 -- highest possible layer
gui.Parent = player:WaitForChild("PlayerGui")

-- Background (black fullscreen)
local bg = Instance.new("Frame")
bg.Size = UDim2.new(1, 0, 1, 0)
bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
bg.BorderSizePixel = 0
bg.ZIndex = 999999
bg.Parent = gui

-- Function to create text layers
local function createTextLayer(color, z)
	local txt = Instance.new("TextLabel")
	txt.AnchorPoint = Vector2.new(0.5, 0.5)
	txt.Position = UDim2.new(0.5, 0, 0.5, 0)
	txt.Size = UDim2.new(1, 0, 1, 0)
	txt.BackgroundTransparency = 1
	txt.Text = "NV"
	txt.TextScaled = true
	txt.Font = Enum.Font.SourceSansBold
	txt.TextColor3 = color
	txt.ZIndex = z
	txt.Parent = bg
	return txt
end

-- Create layers (blue outline + purple main)
local outline = createTextLayer(Color3.fromRGB(0, 100, 255), 999999)
local main = createTextLayer(Color3.fromRGB(170, 0, 255), 1000000)

-- Spin animation
local rotation = 0
local spinning = true

task.spawn(function()
	while spinning do
		rotation += 2
		if rotation >= 360 then rotation = 0 end
		main.Rotation = rotation
		outline.Rotation = rotation
		runService.RenderStepped:Wait()
	end
end)

-- Wait, then fade everything out
task.wait(3)
for i = 1, 30 do
	local t = i / 30
	main.TextTransparency = t
	outline.TextTransparency = t
	bg.BackgroundTransparency = t
	task.wait(0.05)
end

spinning = false
gui:Destroy()
