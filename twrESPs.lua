-- espbox Zombie + Items (prefix = L), use with espbox.txt (plr)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local camera = workspace.CurrentCamera

local drawingsZombies = {}
local drawingsItems = {}
local ESPEnabled = true

-- Toggle ESP với phím L
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.L then
		ESPEnabled = not ESPEnabled
		print("ESP " .. (ESPEnabled and "BẬT" or "TẮT"))

		for _, box in pairs(drawingsZombies) do
			if box then box.Visible = ESPEnabled end
		end
		for _, drawing in pairs(drawingsItems) do
			if drawing then
				drawing.box.Visible = ESPEnabled
				drawing.text.Visible = ESPEnabled
			end
		end
	end
end)

-- ================= ZOMBIES =================
local function addESPZombie(zombie)
	if not zombie:FindFirstChild("HumanoidRootPart") then return end
	local box = Drawing.new("Square")
	box.Color = Color3.fromRGB(255, 0, 0)
	box.Thickness = 0.8
	box.Transparency = 0.5
	box.Filled = false
	box.Visible = ESPEnabled
	drawingsZombies[zombie] = box
end

local function removeESPZombie(zombie)
	if drawingsZombies[zombie] then
		drawingsZombies[zombie]:Remove()
		drawingsZombies[zombie] = nil
	end
end

-- ================= ITEMS (FIX) =================
local function getItemWorldPos(item)
	-- BasePart
	if item:IsA("BasePart") then
		return item.Position
	end

	-- Model (Ammo, Medkit,...)
	if item:IsA("Model") then
		local pp = item.PrimaryPart
		if pp and pp:IsA("BasePart") then
			return pp.Position
		end
		-- fallback: pivot (ổn cho model không set PrimaryPart)
		local ok, cf = pcall(function() return item:GetPivot() end)
		if ok and cf then
			return cf.Position
		end
	end

	return nil
end

local function addESPItem(item)
	if not (item:IsA("BasePart") or item:IsA("Model")) then return end

	-- nếu là Model mà chưa có part nào thì bỏ qua
	if item:IsA("Model") and not getItemWorldPos(item) then return end

	local box = Drawing.new("Square")
	box.Color = Color3.fromRGB(255, 255, 255)
	box.Thickness = 0.8
	box.Transparency = 0.5
	box.Filled = false
	box.Visible = ESPEnabled

	local text = Drawing.new("Text")
	text.Color = Color3.fromRGB(255, 255, 255)
	text.Size = 16
	text.Outline = true
	text.Center = true
	text.Visible = ESPEnabled
	text.Text = item.Name

	drawingsItems[item] = { box = box, text = text }
end

local function removeESPItem(item)
	local d = drawingsItems[item]
	if d then
		d.box:Remove()
		d.text:Remove()
		drawingsItems[item] = nil
	end
end

-- ================= UPDATE =================
local function updateESP()
	if not ESPEnabled then return end

	-- Zombies
	local toRemoveZ = {}
	for zombie, box in pairs(drawingsZombies) do
		if not (zombie and zombie.Parent and zombie:FindFirstChild("HumanoidRootPart")) then
			toRemoveZ[zombie] = true
		else
			local root = zombie.HumanoidRootPart
			local rootPos2D, onScreen = camera:WorldToViewportPoint(root.Position)
			if onScreen then
				local head = zombie:FindFirstChild("Head")
				local headOffset = head and (head.Size.Y / 2 + 1) or 5
				local legOffset = 4

				local headPos3D = camera:WorldToViewportPoint(root.Position + Vector3.new(0, headOffset, 0))
				local legPos3D = camera:WorldToViewportPoint(root.Position - Vector3.new(0, legOffset, 0))

				local topY = math.min(headPos3D.Y, legPos3D.Y)
				local botY = math.max(headPos3D.Y, legPos3D.Y)
				local height = math.abs(botY - topY)
				local sizeY = math.clamp(height * 1.2, 8, 2000)
				local sizeX = sizeY * 0.6

				box.Size = Vector2.new(sizeX, sizeY)
				box.Position = Vector2.new(rootPos2D.X - sizeX / 2, topY)
				box.Visible = true
			else
				box.Visible = false
			end
		end
	end
	for z in pairs(toRemoveZ) do removeESPZombie(z) end

	-- Items
	local toRemoveI = {}
	for item, drawing in pairs(drawingsItems) do
		if not (item and item.Parent) then
			toRemoveI[item] = true
		else
			local pos3D = getItemWorldPos(item)
			if not pos3D then
				toRemoveI[item] = true
			else
				local pos2D, onScreen = camera:WorldToViewportPoint(pos3D)
				if onScreen then
					local dist = (camera.CFrame.Position - pos3D).Magnitude
					local sizeBase = math.clamp(1000 / dist, 10, 50)

					drawing.box.Size = Vector2.new(sizeBase, sizeBase)
					drawing.box.Position = Vector2.new(pos2D.X - sizeBase / 2, pos2D.Y - sizeBase / 2)
					drawing.box.Visible = true

					drawing.text.Position = Vector2.new(pos2D.X, pos2D.Y - sizeBase / 2 - 10)
					drawing.text.Visible = true
				else
					drawing.box.Visible = false
					drawing.text.Visible = false
				end
			end
		end
	end
	for i in pairs(toRemoveI) do removeESPItem(i) end
end

-- ================= HOOK FOLDERS =================
-- Zombies
if workspace:FindFirstChild("Entities") and workspace.Entities:FindFirstChild("Infected") then
	for _, zombie in pairs(workspace.Entities.Infected:GetChildren()) do
		addESPZombie(zombie)
	end
	workspace.Entities.Infected.ChildAdded:Connect(addESPZombie)
	workspace.Entities.Infected.ChildRemoved:Connect(removeESPZombie)
end

-- Items (ƯU TIÊN PATH ĐÚNG: workspace.Ignore.Items)
local itemsFolder =
	(workspace:FindFirstChild("Ignore") and workspace.Ignore:FindFirstChild("Items"))
	or workspace:FindFirstChild("Items")

if itemsFolder then
	for _, item in pairs(itemsFolder:GetChildren()) do
		addESPItem(item)
	end
	itemsFolder.ChildAdded:Connect(addESPItem)
	itemsFolder.ChildRemoved:Connect(removeESPItem)
else
	warn("Không tìm thấy folder Items (thử: workspace.Ignore.Items).")
end

RunService.RenderStepped:Connect(updateESP)
