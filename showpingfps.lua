repeat task.wait() until game:IsLoaded()

-- CẤU HÌNH
local SETTINGS = {
	Color = Color3.fromHex("#369eff"),
	TextSize = 20,
	Font = Enum.Font.GothamBold,

	UpdateInterval = 0.15,   -- refresh text
	Smoothing = 0.12,        -- 0.08~0.2 (càng lớn càng mượt nhưng trễ)

	-- Glass panel (blur giả)
	PanelSize = UDim2.new(0, 240, 0, 44),
	PanelBg = Color3.fromRGB(10, 10, 14),
	PanelTransparency = 0.35,
	StrokeTransparency = 0.65,

	-- Auto-fit theo chữ để không bị "thừa"
	AutoFit = true,
	PaddingLeft = 12,
	PaddingRight = 12,
	MinWidth = 140,
	MaxWidth = 420,
	PanelHeight = 44,

	-- Nếu muốn blur toàn màn hình (không phải blur vùng UI)
	EnableGlobalBlur = false,
	GlobalBlurSize = 8,
}

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SmoothFPS"
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false

if syn and syn.protect_gui then
	syn.protect_gui(ScreenGui)
	ScreenGui.Parent = game.CoreGui
elseif gethui then
	ScreenGui.Parent = gethui()
else
	ScreenGui.Parent = game.CoreGui
end

-- Panel (nền glass)
local Panel = Instance.new("Frame")
Panel.Name = "Panel"
Panel.Parent = ScreenGui
Panel.Size = SETTINGS.PanelSize
Panel.AnchorPoint = Vector2.new(0, 1)
Panel.Position = UDim2.new(0, 15, 1, -15) -- góc dưới trái
Panel.BackgroundColor3 = SETTINGS.PanelBg
Panel.BackgroundTransparency = SETTINGS.PanelTransparency
Panel.BorderSizePixel = 0

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = Panel

local Stroke = Instance.new("UIStroke")
Stroke.Parent = Panel
Stroke.Thickness = 1
Stroke.Color = Color3.new(1, 1, 1)
Stroke.Transparency = SETTINGS.StrokeTransparency

local Gradient = Instance.new("UIGradient")
Gradient.Rotation = 90
Gradient.Parent = Panel
Gradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.15),
	NumberSequenceKeypoint.new(1, 0.00),
})

-- Text
local StatsLabel = Instance.new("TextLabel")
StatsLabel.Name = "Stats"
StatsLabel.Parent = Panel
StatsLabel.BackgroundTransparency = 1
StatsLabel.BorderSizePixel = 0

StatsLabel.Font = SETTINGS.Font
StatsLabel.TextSize = SETTINGS.TextSize
StatsLabel.TextColor3 = SETTINGS.Color
StatsLabel.TextStrokeTransparency = 0.6
StatsLabel.TextStrokeColor3 = SETTINGS.Color
StatsLabel.TextXAlignment = Enum.TextXAlignment.Left
StatsLabel.TextYAlignment = Enum.TextYAlignment.Center
StatsLabel.Text = "..."

-- Auto-fit panel theo độ rộng chữ (fix cái "thừa")
local function fitToText()
	if not SETTINGS.AutoFit then return end

	-- defer 1 tick để TextBounds cập nhật đúng sau khi set Text
	task.defer(function()
		local textW = math.ceil(StatsLabel.TextBounds.X)
		local newW = math.clamp(
			textW + SETTINGS.PaddingLeft + SETTINGS.PaddingRight,
			SETTINGS.MinWidth,
			SETTINGS.MaxWidth
		)

		Panel.Size = UDim2.new(0, newW, 0, SETTINGS.PanelHeight)
		StatsLabel.Position = UDim2.new(0, SETTINGS.PaddingLeft, 0, 0)
		StatsLabel.Size = UDim2.new(1, -(SETTINGS.PaddingLeft + SETTINGS.PaddingRight), 1, 0)
	end)
end

-- set layout ban đầu
StatsLabel.Position = UDim2.new(0, SETTINGS.PaddingLeft, 0, 0)
StatsLabel.Size = UDim2.new(1, -(SETTINGS.PaddingLeft + SETTINGS.PaddingRight), 1, 0)
Panel.Size = UDim2.new(0, SETTINGS.MinWidth, 0, SETTINGS.PanelHeight)
fitToText()

-- Optional blur toàn màn hình
if SETTINGS.EnableGlobalBlur then
	local Lighting = game:GetService("Lighting")
	local blur = Lighting:FindFirstChild("SmoothFPS_Blur") or Instance.new("BlurEffect")
	blur.Name = "SmoothFPS_Blur"
	blur.Size = SETTINGS.GlobalBlurSize
	blur.Parent = Lighting
end

-- LOGIC FPS/PING (chuẩn + mượt)
local RunService = game:GetService("RunService")
local StatsService = game:GetService("Stats")

-- FPS: tính theo số frame / tổng dt trong 1 khoảng -> ổn định hơn 1/step
local frames = 0
local dtSum = 0
local smoothedFps = 0

local function getPingMs()
	local item = StatsService:FindFirstChild("Network")
		and StatsService.Network:FindFirstChild("ServerStatsItem")
		and StatsService.Network.ServerStatsItem:FindFirstChild("Data Ping")

	if item then
		local okStr, str = pcall(function() return item:GetValueString() end)
		if okStr and type(str) == "string" then
			local n = tonumber(str:match("([%d%.]+)"))
			if n then
				return math.floor(n + 0.5)
			end
		end

		local okVal, val = pcall(function() return item:GetValue() end)
		if okVal and type(val) == "number" then
			if val > 0 and val < 5 then
				return math.floor(val * 1000 + 0.5)
			end
			return math.floor(val + 0.5)
		end
	end

	return 0
end

local lastUpdate = 0

RunService.RenderStepped:Connect(function(dt)
	frames += 1
	dtSum += dt

	if os.clock() - lastUpdate >= SETTINGS.UpdateInterval then
		local rawFps = 0
		if dtSum > 0 then
			rawFps = frames / dtSum
		end

		-- smoothing (EMA)
		if smoothedFps == 0 then
			smoothedFps = rawFps
		else
			local a = SETTINGS.Smoothing
			smoothedFps = smoothedFps + (rawFps - smoothedFps) * a
		end

		local ping = getPingMs()

		StatsLabel.Text = string.format("%d FPS  |  %d ms", math.floor(smoothedFps + 0.5), ping)
		fitToText()

		frames = 0
		dtSum = 0
		lastUpdate = os.clock()
	end
end)
