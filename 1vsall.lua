local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local JobId = game.JobId

local Window = Rayfield:CreateWindow({
    Name = "1 VS All | By Th1nK",
    LoadingTitle = "",
    LoadingSubtitle = "by Th1nK",
    ShowText = "Overpowered",
    Theme = "Default",
    ToggleUIKeybind = "M",
    ConfigurationSaving = {Enabled = false},
    KeySystem = false
})

local Tab = Window:CreateTab("Home", 4483362458)

Tab:CreateToggle({
    Name = "100% OP (+3%)",
    CurrentValue = false,
    Flag = "opbuff",
    Callback = function(state)
        getgenv().OPFriendToggle = state
        if state then Rayfield:Notify({Title = "OP +3%", Content = "buffing", Duration = 4}) end
        
        spawn(function()
            while getgenv().OPFriendToggle do
                pcall(function()
                    game:GetService("ReplicatedStorage")
                        :WaitForChild("Remotes", 5)
                        :WaitForChild("Reusable", 5)
                        :WaitForChild("InvitedFriend", 5)
                        :FireServer()
                end)
                task.wait(0.08)
            end
        end)
    end,
})

Tab:CreateButton({
    Name = "Get Gojo",
    Callback = function()
        local args = {
            [1] = "Limited Weapon",
            [2] = 1
        }
        game:GetService("ReplicatedStorage").Remotes.SpinReward:FireServer(unpack(args))
    end,
})

Tab:CreateToggle({
    Name = "inf cash",
    CurrentValue = false,
    Flag = "infcash",
    Callback = function(state)
        getgenv().CashSpamToggle = state
        
        if state then
            Rayfield:Notify({Title = "Cash Spam Activated", Content = "Running...", Duration = 5})
            
            task.spawn(function()  -- Chỉ tạo 1 thread thôi
                local Remote = game:GetService("ReplicatedStorage").Remotes.SpinReward
                local DELAY_BETWEEN_BATCH = 0.085   -- điều chỉnh: nhỏ hơn → spam mạnh hơn, nhưng dễ bị kick
                local FIRES_PER_BATCH = 50          -- số lần FireServer mỗi đợt (tương đương 70 worker cũ)
                
                while getgenv().CashSpamToggle do
                    for i = 1, FIRES_PER_BATCH do
                        task.spawn(function()  -- optional: spawn nhỏ để không block thread chính
                            pcall(Remote.FireServer, Remote, "10,000 Cash", 5)
                        end)
                        -- hoặc bỏ task.spawn nhỏ, gọi thẳng: pcall(Remote.FireServer, Remote, "10,000 Cash", 5)
                    end
                    
                    task.wait(DELAY_BETWEEN_BATCH)
                end
                
                Rayfield:Notify({Title = "Cash Spam", Content = "Stopped cleanly.", Duration = 3})
            end)
            
        else
            getgenv().CashSpamToggle = false
            Rayfield:Notify({Title = "Cash Spam", Content = "Stopping...", Duration = 4})
            -- Không cần cancel gì cả, vòng lặp sẽ tự thoát sau lần wait cuối
        end
    end,
})


Tab:CreateToggle({
    Name = "inf heal pots",
    CurrentValue = false,
    Flag = "InfHealPotion",
    Callback = function(state)
        getgenv().InfHealToggle = state
        
        if state then
            Rayfield:Notify({Title = "Healing Potions", Content = "Running... (spam active)", Duration = 4})
            
            task.spawn(function()
                while getgenv().InfHealToggle do
                    pcall(function()
                        game:GetService("ReplicatedStorage").Remotes.SpinReward:FireServer("10 Healing Potions", 40)
                    end)
                    task.wait(0.09)  -- ← giảm xuống 0.09 hoặc 0.1 để giống file txt
                end
            end)
        else
            Rayfield:Notify({Title = "Healing Potions", Content = "Stopped.", Duration = 3})
        end
    end,
})

Tab:CreateToggle({
    Name = "inf dmg pots",
    CurrentValue = false,
    Flag = "InfDamagePotion",
    Callback = function(state)
        getgenv().InfDamageToggle = state
        
        if state then
            Rayfield:Notify({Title = "Damage Potions", Content = "Running... (spam active)", Duration = 4})
            
            task.spawn(function()
                while getgenv().InfDamageToggle do
                    pcall(function()
                        game:GetService("ReplicatedStorage").Remotes.SpinReward:FireServer("10 Damage Potions", 14)
                    end)
                    task.wait(0.09)  -- ← tương tự
                end
            end)
        else
            Rayfield:Notify({Title = "Damage Potions", Content = "Stopped.", Duration = 3})
        end
    end,
})

Tab:CreateSection("hitbox expander")

Tab:CreateButton({
    Name = "hitbox ×8 (more = instant kick)",
    Callback = function()
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local root = player.Character:FindFirstChild("HumanoidRootPart")
                if root and root:IsA("BasePart") then
                    root.Size = Vector3.new(8, 8, 8)
                    root.Transparency = 0.9
                    root.CanCollide = false
                end
            end
        end
        Rayfield:Notify({Title = "Hitbox", Content = "Set to ×8 for all other players", Duration = 4})
    end,
})

Tab:CreateSection("server tools")

Tab:CreateButton({
    Name = "rejoin Server",
    Callback = function()
        Rayfield:Notify({
            Title = "Rejoining...",
            Content = "Preparing to rejoin current server...",
            Duration = 3,
        })
        
        if #Players:GetPlayers() <= 1 then
            LocalPlayer:Kick("\nRejoining server...")
            wait(1)
            TeleportService:Teleport(PlaceId, LocalPlayer)
        else
            TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LocalPlayer)
        end
    end,
})

Tab:CreateSection("Become REAL OP!")
Beta
0 / 0
used queries
1