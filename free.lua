local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Create GUI Window (mobile-friendly size, no tab dropdown, slightly transparent)
local Window = WindUI:CreateWindow({
    Title = "Sypher Hub - Fish It",
    Icon = "https://raw.githubusercontent.com/fonov58646a/image/main/file_00000000fbe061fa913561383180e1d9.png",
    IconThemed = true,
    Author = "VERSION: FREEMIUM",
    Folder = "Sypher-Hub",
    Size = UDim2.new(0, 380, 0, 260), -- ✅ Lebih kecil biar pas di Android
    Theme = "Dark" -- Bisa ganti "Light" kalau silau
})

-- Info Tab
local InfoTab = Window:Tab({ Title = "Info", Icon = "info" })

InfoTab:Paragraph({
    Title = "Welcome to Sypher Hub",
    Desc = "Version Game: Fish it.",
    Image = "https://raw.githubusercontent.com/fonov58646a/image/main/file_00000000fbe061fa913561383180e1d9.png",
    ImageSize = 30,
    Thumbnail = "https://raw.githubusercontent.com/fonov58646a/image/main/file_00000000fbe061fa913561383180e1d9.png",
    ThumbnailSize = 170
})

InfoTab:Button({
    Title = "Join Our SYPHER Discord",
    Desc = "Click to copy our Discord invite link.",
    Callback = function()
        setclipboard("https://discord.gg/FYAVrc5CSb")
        WindUI:Notify({
            Title = "Discord",
            Content = "Discord invite link copied to clipboard!",
            Duration = 5
        })
    end
})

-- Anti-AFK System
local VirtualUser = game:GetService("VirtualUser")
local Players = game:GetService("Players")

-- Anti-AFK handler
Players.LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
    WindUI:Notify({
        Title = "Anti-AFK", 
        Content = "Preventing idle kick...",
        Duration = 2
    })
end)

-- Background anti-idle movement
task.spawn(function()
    while true do
        task.wait(60) -- Every minute
        VirtualUser:CaptureController()
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(0.1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end
end)

-- Auto Farm Tab
local AutofarmTab = Window:Tab({ 
    Title = "Auto Farm", 
    Icon = "fish"
})

-- Toggle Fishing Radar
AutofarmTab:Toggle({
    Title = "Fishing Radar",
    Desc = "Bypass Fishing Radar",
    Default = false,
    Callback = function(state)
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Lighting = game:GetService("Lighting")

        local Replion = require(ReplicatedStorage.Packages.Replion)
        local Net = require(ReplicatedStorage.Packages.Net)
        local SPR = require(ReplicatedStorage.Packages.spr)
        local Soundbook = require(ReplicatedStorage.Shared.Soundbook)
        local ClientTime = require(ReplicatedStorage.Controllers.ClientTimeController)
        local TextNotification = require(ReplicatedStorage.Controllers.TextNotificationController)

        local UpdateFishingRadar = Net:RemoteFunction("UpdateFishingRadar")

        local function SetRadar(enable)
            local clientData = Replion.Client:GetReplion("Data")
            if not clientData then return end

            if clientData:Get("RegionsVisible") ~= enable then
                if UpdateFishingRadar:InvokeServer(enable) then
                    Soundbook.Sounds.RadarToggle:Play().PlaybackSpeed = 1 + math.random() * 0.3

                    -- Adjust lighting when enabling
                    if enable then
                        local ccEffect = Lighting:FindFirstChildWhichIsA("ColorCorrectionEffect")
                        if ccEffect then
                            SPR.stop(ccEffect)
                            local lightingProfile = ClientTime:_getLightingProfile()
                            local targetSettings = (lightingProfile and lightingProfile.ColorCorrection) or {}
                            targetSettings.Brightness = targetSettings.Brightness or 0.04
                            targetSettings.TintColor = targetSettings.TintColor or Color3.fromRGB(255, 255, 255)

                            ccEffect.TintColor = Color3.fromRGB(42, 226, 118)
                            ccEffect.Brightness = 0.4
                            SPR.target(ccEffect, 1, 1, targetSettings)
                        end

                        SPR.stop(Lighting)
                        Lighting.ExposureCompensation = 1
                        SPR.target(Lighting, 1, 2, {ExposureCompensation = 0})
                    end

                    -- Notification
                    TextNotification:DeliverNotification({
                        Type = "Text",
                        Text = "Radar: "..(enable and "Enabled" or "Disabled"),
                        TextColor = enable and {R = 9, G = 255, B = 0} or {R = 255, G = 0, B = 0}
                    })
                end
            end
        end

        -- Toggle ON/OFF
        if state then
            SetRadar(true)
        else
            SetRadar(false)
        end
    end
})

-- Paragraph with description
AutofarmTab:Paragraph({
    Title = "Auto Farm",
})

-- ===== Auto Fish Setup (Fixed by Sypher) =====
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local animTracks = nil
local autoFishEnabled = false
local isRunning = false -- Track if the auto-fish loop is running

-- ===== Global delay settings =====
local delayTime = 3 -- default delay
local minSafeDelay = 1.6
local delayInputValue = nil -- temporary input storage

-- Animation IDs
local animations = {
    idle = "rbxassetid://96586569072385",
    cast = "rbxassetid://180435571",
    wait = "rbxassetid://92624107165273",
    reel = "rbxassetid://134965425664034"
}

-- Helper function to get the Animator
local function getAnimator()
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid", 5)
    if not humanoid then
        warn("Failed to find Humanoid")
        return nil
    end
    local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
    return animator
end

-- Load animations into tracks
local function loadAnimations()
    local animator = getAnimator()
    if not animator then
        warn("Could not load animations: Animator not found")
        return nil
    end
    local newTracks = {}
    for name, id in pairs(animations) do
        local success, anim = pcall(function()
            local animation = Instance.new("Animation")
            animation.AnimationId = id
            return animator:LoadAnimation(animation)
        end)
        if success and anim then
            newTracks[name] = anim
        else
            warn("Failed to load animation:", name, id)
        end
    end
    return newTracks
end

-- Initialize animations when character spawns
player.CharacterAdded:Connect(function()
    animTracks = loadAnimations()
end)

if player.Character then
    animTracks = loadAnimations()
end

-- Function to safely stop all animations
local function stopAllAnimations()
    if animTracks then
        for _, track in pairs(animTracks) do
            if track then
                track.Looped = false
                track:Stop(0)
            end
        end
        animTracks = nil
    end
end

-- Auto-fish toggle
AutofarmTab:Toggle({
    Title = "Auto Fish V1",
    Desc = "Automatically fish and auto perfect fishing",
    Value = false,
    Callback = function(state)
        autoFishEnabled = state
        if state then
            if WindUI then
                WindUI:Notify({Title="Auto Fish", Content="Enabled", Duration=3})
            end

            if not player.Character or not animTracks then
                animTracks = loadAnimations()
                if not animTracks then
                    warn("Failed to initialize auto-fish: Animations not loaded")
                    autoFishEnabled = false
                    return
                end
            end

            local netFolder = ReplicatedStorage:FindFirstChild("Packages")
                and ReplicatedStorage.Packages:FindFirstChild("_Index")
                and ReplicatedStorage.Packages._Index:FindFirstChild("sleitnick_net@0.2.0")
                and ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"]:FindFirstChild("net")
            if not netFolder then
                warn("Network folder not found")
                autoFishEnabled = false
                return
            end

            local EquipRod = netFolder:FindFirstChild("RE/EquipToolFromHotbar")
            local StartMinigame = netFolder:FindFirstChild("RF/RequestFishingMinigameStarted")
            local ChargeRod = netFolder:FindFirstChild("RF/ChargeFishingRod")

            if not (EquipRod and StartMinigame and ChargeRod) then
                warn("Required remotes not found")
                autoFishEnabled = false
                return
            end

            pcall(function()
                EquipRod:FireServer(1)
            end)

            if animTracks.idle then
                animTracks.idle.Looped = true
                animTracks.idle:Play()
            end

            if not isRunning then
                isRunning = true
                task.spawn(function()
                    while autoFishEnabled do
                        local success, err = pcall(function()
                            if not player.Character or not player.Character:FindFirstChild("Humanoid") then
                                animTracks = loadAnimations()
                                if not animTracks then return end
                            end

                            if animTracks.cast then animTracks.cast:Play() end
                            StartMinigame:InvokeServer(-0.7499996423721313, 1)
                            task.wait(0.2)

                            if animTracks.wait then animTracks.wait:Play() end
                            task.wait(0.2)

                            if animTracks.reel then animTracks.reel:Play() end
                            ChargeRod:InvokeServer(workspace:GetServerTimeNow())
                            task.wait(0.2)

                            StartMinigame:InvokeServer(-0.7499996423721313, 1)
                        end)

                        if not success then
                            warn("Auto Fish error:", err)
                        end

                        task.wait(math.max(delayTime, minSafeDelay))
                    end
                    isRunning = false
                end)
            end
        else
            autoFishEnabled = false
            stopAllAnimations()
            isRunning = false
            if WindUI then
                WindUI:Notify({Title="Auto Fish", Content="Disabled", Duration=3})
            end
        end
    end
})

-- ===== Delay TextBox + Button =====
AutofarmTab:Input({
    Title = "Auto Fish Delay",
    Placeholder = "Enter delay (0.1–4 seconds)",
    Callback = function(text)
        delayInputValue = text
    end
})

AutofarmTab:Button({
    Title = "Apply Delay",
    Desc = "Apply the entered delay value",
    Callback = function()
        local value = tonumber(delayInputValue)
        if value and value >= 0.1 and value <= 4 then
            delayTime = value
            WindUI:Notify({
                Title = "Auto Fish Delay",
                Content = "Delay set to "..string.format("%.1f s", delayTime).." (min safe: "..minSafeDelay.." s)",
                Duration = 2
            })
        else
            WindUI:Notify({
                Title = "Auto Fish Delay",
                Content = "Invalid input! Must be between 0.1–4 seconds",
                Duration = 2
            })
        end
    end
})


-- ===== Services =====
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local camera = Workspace.CurrentCamera

-- ===== Remote =====
local REEquipToolFromHotbar = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/EquipToolFromHotbar"]
local REFishingCompleted = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/FishingCompleted"]

-- ===== Auto Fishing v2 (Hold Screen) =====
local autoHoldEnabled = false
AutofarmTab:Toggle({
    Title = "Auto Fishing v2",
    Desc = "Beta Test / Risk Error Better v1",
    Value = false,
    Callback = function(state)
        autoHoldEnabled = state

        if state then
            WindUI:Notify({
                Title = "Auto Fishing v2",
                Content = "Enabled",
                Duration = 3
            })

            task.spawn(function()
                local holdDuration = 0.4
                local loopDelay = 0.2

                while autoHoldEnabled do
                    pcall(function()
                        -- Equip rod slot 1
                        REEquipToolFromHotbar:FireServer(1)

                        -- Klik pojok kiri bawah
                        local clickX = 5
                        local clickY = camera.ViewportSize.Y - 5
                        VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, true, game, 0)
                        task.wait(holdDuration)
                        VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, false, game, 0)
                    end)

                    task.wait(loopDelay)
                    RunService.Heartbeat:Wait()
                end
            end)
        else
            WindUI:Notify({
                Title = "Auto Fishing v2",
                Content = "Disabled",
                Duration = 3
            })
        end
    end
})

-- ===== Auto Instant Fish =====
-- Enhanced Auto Fish V2
local autoInstantFishEnabled = true
local selectedRarities = {
    Common = true,
    Uncommon = true,
    Rare = true,
    Epic = true,
    Legendary = true,
    Mythical = true
}

-- Main auto fish function (instant, no delay)
local function startAutoFishV2()
    task.spawn(function()
        while autoInstantFishEnabled do
            pcall(function()
                -- Instant complete fishing
                REFishingCompleted:FireServer()
                
                -- Auto catch berdasarkan rarity
                for rarity, enabled in pairs(selectedRarities) do
                    if enabled then
                        -- Fire server untuk catch specific rarity
                        game:GetService("ReplicatedStorage").Events.CatchFish:FireServer(rarity)
                    end
                end
            end)
            -- No delay for instant processing
            game:GetService("RunService").Heartbeat:Wait()
        end
    end)
end

-- Toggle di GUI
local toggle = AutofarmTab:Toggle({
    Title = "Auto Instant complete Fishing",
    Desc = "Automatically completes fishing instantly",
    Value = autoInstantFishEnabled, -- default ON
    Callback = function(state)
        autoInstantFishEnabled = state
        if state then
            WindUI:Notify({
                Title = "Auto Instant Fish",
                Content = "Enabled (Delay: " .. delayTime .. "s)",
                Duration = 3
            })
            startAutoFish()
        else
            WindUI:Notify({
                Title = "Auto Instant Fish",
                Content = "Disabled",
                Duration = 3
            })
        end
    end
})

-- langsung trigger sekali saat load biar ON otomatis
toggle.Callback(true)

AutofarmTab:Paragraph({
    Title = "Auto Sell",
    Desc = "Please be careful when using auto sell and have set auto sell in backpack",
})

-- Rarity Selection Tab
local RarityTab = Window:Tab({
    Title = "Fish Rarity",
    Icon = "fish"
})

RarityTab:Paragraph({
    Title = "Select Fish Rarities",
    Desc = "Choose which rarities to auto-catch"
})

-- Toggle untuk setiap rarity
local rarityList = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical"}

for _, rarity in ipairs(rarityList) do
    RarityTab:Toggle({
        Title = rarity .. " Fish",
        Default = true,
        Callback = function(state)
            selectedRarities[rarity] = state
            local status = state and "Enabled" or "Disabled"
            WindUI:Notify({
                Title = rarity .. " Rarity",
                Content = status,
                Duration = 2
            })
        end
    })
end

-- Multi-select dropdown alternative
RarityTab:Multiselect({
    Title = "Quick Select Rarities",
    Values = rarityList,
    Default = rarityList,
    Callback = function(values)
        -- Reset all
        for _, r in ipairs(rarityList) do
            selectedRarities[r] = false
        end
        -- Enable selected
        for _, r in ipairs(values) do
            selectedRarities[r] = true
        end
    end
})

-- ===== Auto Sell Button =====
local sellAllButton = AutofarmTab:Button({
    Title = "Sell All Fish",
    Desc = "Click to sell all your items instantly",
    Callback = function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local RFSellAllItems = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RF/SellAllItems"]

        pcall(function()
            RFSellAllItems:InvokeServer()
        end)

        WindUI:Notify({
            Title = "Auto Sell",
            Content = "All items sold!",
            Duration = 3
        })
    end
})

-- ===== Auto Sell Toggle =====
local autoSellEnabled = false
local autoSellConnection

local autoSellToggle = AutofarmTab:Toggle({
    Title = "Auto Sell",
    Desc = "Automatically sell all Fish / Warning",
    Value = false,
    Callback = function(state)
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local RFSellAllItems = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RF/SellAllItems"]

        autoSellEnabled = state

        if state then
            WindUI:Notify({
                Title = "Auto Sell",
                Content = "Enabled - Selling Fish automatically",
                Duration = 3
            })

            autoSellConnection = task.spawn(function()
                while autoSellEnabled do
                    pcall(function()
                        RFSellAllItems:InvokeServer()
                    end)
                    task.wait(3) -- jeda biar aman, jangan terlalu spam
                end
            end)

        else
            WindUI:Notify({
                Title = "Auto Sell Fish",
                Content = "Disabled",
                Duration = 3
            })
            autoSellEnabled = false
        end
    end
})

AutofarmTab:Paragraph({
    Title = "Anti Kicked From Server",
})

local antiKickToggle = AutofarmTab:Toggle({
    Title = "Anti Kick",
    Value = false,
    Callback = function(state)
        local player = game.Players.LocalPlayer

        if state then
            -- Ambil karakter & HumanoidRootPart
            local char = player.Character or player.CharacterAdded:Wait()
            local hrp = char:WaitForChild("HumanoidRootPart")
            local initialPos = hrp.Position
            local initialCFrame = hrp.CFrame -- simpan orientasi awal

            -- Anti-AFK VirtualUser
            _G.AntiKickConnection = player.Idled:Connect(function()
                local vu = game:GetService("VirtualUser")
                vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            end)

            -- Auto Jump + pergerakan horizontal random
            _G.AutoJumpEnabled = true
            spawn(function()
                while _G.AutoJumpEnabled do
                    task.wait(350) -- interval 5 detik
                    local char = player.Character
                    if not char then break end
                    local humanoid = char:FindFirstChild("Humanoid")
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if humanoid and humanoid.Health > 0 then
                        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                    if hrp then
                        -- Pergerakan horizontal acak
                        local offsetX = math.random(-2,2)/10 -- ±0.2 studs
                        local offsetZ = math.random(-2,2)/10
                        local newPos = hrp.Position + Vector3.new(offsetX, 0, offsetZ)
                        hrp.CFrame = CFrame.lookAt(newPos, newPos + initialCFrame.LookVector)

                        task.wait(0.1)

                        -- Kembali ke posisi awal tetap menghadap depan
                        local currentY = hrp.Position.Y
                        hrp.CFrame = CFrame.lookAt(initialPos + Vector3.new(0, currentY - initialPos.Y, 0), 
                                                   initialPos + Vector3.new(0, currentY - initialPos.Y, 0) + initialCFrame.LookVector)
                    end
                end
            end)

            WindUI:Notify({
                Title = "Anti-Kick + Auto Jump",
                Content = "Enabled: Anti-Kick active with random horizontal movements",
                Duration = 3
            })
        else
            -- Matikan loop & disconnect Idled
            if _G.AntiKickConnection then
                _G.AntiKickConnection:Disconnect()
                _G.AntiKickConnection = nil
            end
            _G.AutoJumpEnabled = false

            WindUI:Notify({
                Title = "Anti-Kick + Auto Jump",
                Content = "Disabled",
                Duration = 3
            })
        end
    end
})

local changestatsTab = Window:Tab({ 
    Title = "Change Rod Stats", 
    Icon = "file-text" 
})

-- ===== Paragraph =====
changestatsTab:Paragraph({
    Title="Rod Modifier",
    Desc="Select a Rod to apply max stats."
})

local rodDisplayOrder = {
    "Starter Rod",
    "Lava Rod",
    "Luck Rod",
    "Carbon Rod",
    "Grass Rod",
    "Demascus Rod",
    "Ice Rod",
    "Lucky Rod",
    "Midnight Rod",
    "Steampunk Rod",
    "Chrome Rod",
    "Astral Rod",
    "Ares Rod",
    "Angler Rod",
    "Ghostfinn Rod"
}

-- Mapping display name ke modul asli (dengan !!!)
local rodKeyMap = {
    ["Starter Rod"] = "!!! Starter Rod",
    ["Lava Rod"] = "!!! Lava Rod",
    ["Luck Rod"] = "!!! Luck Rod",
    ["Carbon Rod"] = "!!! Carbon Rod",
    ["Grass Rod"] = "!!! Grass Rod",
    ["Demascus Rod"] = "!!! Demascus Rod",
    ["Ice Rod"] = "!!! Ice Rod",
    ["Lucky Rod"] = "!!! Lucky Rod",
    ["Midnight Rod"] = "!!! Midnight Rod",
    ["Steampunk Rod"] = "!!! Steampunk Rod",
    ["Chrome Rod"] = "!!! Chrome Rod",
    ["Astral Rod"] = "!!! Astral Rod",
    ["Ares Rod"] = "!!! Ares Rod",
    ["Angler Rod"] = "!!! Angler Rod",
    ["Ghostfinn Rod"] = "!!! Ghostfinn Rod"
}

-- Selected default
local selectedRod = rodDisplayOrder[1]

-- ===== Dropdown =====
changestatsTab:Dropdown({
    Title = "Select Rod",
    Values = rodDisplayOrder,
    Value = selectedRod,
    Callback = function(value)
        selectedRod = value
        WindUI:Notify({
            Title = "Rod Selected",
            Content = value,
            Duration = 3
        })
    end
})

-- ===== Tombol Apply Max Stats =====
changestatsTab:Button({
    Title = "Apply Max Stats",
    Callback = function()
        local moduleName = rodKeyMap[selectedRod] -- modul asli dengan !!!
        if moduleName then
            local success, err = pcall(function()
                local ReplicatedStorage = game:GetService("ReplicatedStorage")
                local rodModule = ReplicatedStorage.Items:FindFirstChild(moduleName)
                
                if rodModule and rodModule:IsA("ModuleScript") then
                    local rodData = require(rodModule)
                    
                    rodData.VisualClickPowerPercent = 99999999999999
                    rodData.ClickPower = 99999999999999
                    rodData.Resilience = 99999999999999
                    rodData.Windup = NumberRange.new(2.5, 3)
                    rodData.MaxWeight = 99999999999999

                    if rodData.RollData then
                        rodData.RollData.BaseLuck = 99999999999999
                        if rodData.RollData.Frequency then
                            rodData.RollData.Frequency.Golden = 2
                            rodData.RollData.Frequency.Rainbow = 0
                        end
                    end
                else
                    warn("Module "..moduleName.." tidak ditemukan!")
                end
            end)

            if success then
                WindUI:Notify({
                    Title = "Rod Modifier",
                    Content = selectedRod.." max stats applied!",
                    Duration = 3
                })
            else
                WindUI:Notify({
                    Title = "Rod Modifier Error",
                    Content = tostring(err),
                    Duration = 5
                })
            end
        end
    end
})

-- Teleport Tab
local TpTab = Window:Tab({  
    Title = "Teleport",  
    Icon = "map-pin"
})

-- Daftar lokasi teleport
local teleportLocations = {
    {Title = "Kohana Lava", Position = Vector3.new(-593.32, 59.0, 130.82)},
    {Title = "Esotoric Island", Position = Vector3.new(2024.490, 27.397, 1391.620)},
    {Title = "Ice Island", Position = Vector3.new(1766.46, 19.16, 3086.23)},
    {Title = "Lost Isle", Position = Vector3.new(-3660.070, 5.426, -1053.020)},
	{Title = "Sishypus Statue", Position = Vector3.new(-3693.96, -135.57, -1027.28)},
	{Title = "Treasure Hall", Position = Vector3.new(-3598.39, -275.82, -1641.46)},
    {Title = "Stingray Shores", Position = Vector3.new(13.06, 24.53, 2911.16)},
    {Title = "Tropical Grove", Position = Vector3.new(-2092.897, 6.268, 3693.929)},
    {Title = "Weather Machine", Position = Vector3.new(-1495.250, 6.500, 1889.920)},
    {Title = "Coral Reefs", Position = Vector3.new(-2949.359, 63.250, 2213.966)},
    {Title = "Crater Island", Position = Vector3.new(1012.045, 22.676, 5080.221)},
    {Title = "Teleport To Enchant", Position = Vector3.new(3236.120, -1302.855, 1399.491)}
}

-- Buat list nama untuk dropdown
local locationNames = {}
for _, loc in ipairs(teleportLocations) do
    table.insert(locationNames, loc.Title)
end

-- Default selected location
local selectedLocation = locationNames[1]

-- Paragraph
TpTab:Paragraph({
    Title = "Teleport To Island",
    Desc = "Select a location and press Teleport."
})

-- Dropdown Teleport
local teleportDropdown = TpTab:Dropdown({
    Title = "Select Location",
    Values = locationNames,
    Value = selectedLocation,
    Callback = function(value)
        selectedLocation = value
        WindUI:Notify({Title="Location Selected", Content=value, Duration=3})
    end
})

-- Tombol Teleport
TpTab:Button({
    Title = "Teleport To Island",
    Icon = "rbxassetid://85151307796718",
    Callback = function()
        if selectedLocation then
            local loc
            for _, l in ipairs(teleportLocations) do
                if l.Title == selectedLocation then
                    loc = l
                    break
                end
            end

            if loc then
                local player = game.Players.LocalPlayer
                local character = player.Character or player.CharacterAdded:Wait()
                local hrp = character:WaitForChild("HumanoidRootPart")
                hrp.CFrame = CFrame.new(loc.Position)
                WindUI:Notify({Title="Teleported", Content="Teleported to "..loc.Title, Duration=3})
            end
        end
    end
})

-- Toggle Diving Gear ON/OFF
TpTab:Toggle({
    Title = "Diving Gear",
    Desc = "Using diving gear without buying it",
    Default = false,
    Callback = function(state)
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Replion = require(ReplicatedStorage.Packages.Replion)
        local Net = require(ReplicatedStorage.Packages.Net)
        local ItemUtility = require(ReplicatedStorage.Shared.ItemUtility)
        local Soundbook = require(ReplicatedStorage.Shared.Soundbook)
        local NotificationController = require(ReplicatedStorage.Controllers.TextNotificationController)

        local DivingGear = ItemUtility:GetItemData("Diving Gear")
        if not DivingGear then return end

        local ReplionData = Replion.Client:GetReplion("Data")

        if state then
            -- ON
            if ReplionData:Get("EquippedOxygenTankId") ~= DivingGear.Data.Id then
                local EquipFunc = Net:RemoteFunction("EquipOxygenTank")
                local success = EquipFunc:InvokeServer(DivingGear.Data.Id)
                if success then
                    Soundbook.Sounds.DivingToggle:Play().PlaybackSpeed = 1 + math.random() * 0.3
                    NotificationController:DeliverNotification({
                        Type = "Text",
                        Text = "Diving Gear: On",
                        TextColor = {R = 9, G = 255, B = 0}
                    })
                end
            end
        else
            -- OFF
            if ReplionData:Get("EquippedOxygenTankId") == DivingGear.Data.Id then
                local UnequipFunc = Net:RemoteFunction("UnequipOxygenTank")
                local success = UnequipFunc:InvokeServer()
                if success then
                    Soundbook.Sounds.DivingToggle:Play().PlaybackSpeed = 1 + math.random() * 0.3
                    NotificationController:DeliverNotification({
                        Type = "Text",
                        Text = "Diving Gear: Off",
                        TextColor = {R = 255, G = 0, B = 0}
                    })
                end
            end
        end
    end
})

TpTab:Paragraph({
    Title = "Teleport To Other Player",
    Desc = "Select Name Player And Press Teleport"
})

-- Teleport to Player Tab
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local selectedPlayer = nil
local playerDropdown = nil -- reference dropdown

-- Fungsi refresh dropdown
local function refreshPlayerDropdown()
    -- Hapus dropdown lama jika ada
    if playerDropdown then
        playerDropdown:Remove()
    end

    -- Buat daftar player baru
    local playerNames = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(playerNames, plr.Name)
        end
    end

    -- Default selected player
    if #playerNames > 0 then
        if not table.find(playerNames, selectedPlayer) then
            selectedPlayer = playerNames[1]
        end
    else
        selectedPlayer = nil
    end

    -- Buat dropdown baru
    playerDropdown = TpTab:Dropdown({
        Title = "Select Player",
        Values = playerNames,
        Value = selectedPlayer,
        Callback = function(value)
            selectedPlayer = value
            WindUI:Notify({Title="Player Selected", Content=value, Duration=3})
        end
    })
end

-- Buat dropdown pertama kali sebelum tombol
refreshPlayerDropdown()

-- Tombol Teleport di bawah dropdown
TpTab:Button({
    Title = "Telepor To Other Player",
    Callback = function()
        if selectedPlayer then
            local targetPlayer = Players:FindFirstChild(selectedPlayer)
            local myChar = LocalPlayer.Character
            local hrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local targetChar = targetPlayer and targetPlayer.Character
            local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")

            if hrp and targetHRP then
                hrp.CFrame = targetHRP.CFrame + Vector3.new(0,5,0)
                WindUI:Notify({Title="Teleported", Content="Teleported to "..selectedPlayer, Duration=3})
            end
        end
    end
})

-- Loop refresh dropdown tiap detik (tombol tetap di bawah)
spawn(function()
    while true do
        wait(1)
        refreshPlayerDropdown()
    end
end)

TpTab:Paragraph({
    Title = "Saved & Load, Location",
    Desc = "Saved Potition And Load Potition"
})

-- ===== Load Config =====
local savedConfig
if Window.ConfigManager then
    savedConfig = Window.ConfigManager:CreateConfig("Sypher Hub"):Load()
end

-- ===== Default Values =====
local defaultTheme = (savedConfig and savedConfig.Theme) or WindUI:GetCurrentTheme()
local defaultTransparency = (savedConfig and savedConfig.TransparentMode ~= nil) and savedConfig.TransparentMode or true

-- ===== Saved Position =====
local savedPosition
if savedConfig and savedConfig.SavedPosition then
    local pos = savedConfig.SavedPosition
    if pos.X and pos.Y and pos.Z then
        savedPosition = Vector3.new(pos.X, pos.Y, pos.Z)
    end
end

-- Tombol Save Position
TpTab:Button({
    Title = "Save Position",
    Callback = function()
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local hrp = character:WaitForChild("HumanoidRootPart")
        savedPosition = hrp.Position

        -- Simpan ke Config
        if Window.ConfigManager then
            local config = Window.ConfigManager:CreateConfig("Sypher Hub")
            config:Set("SavedPosition", {X = savedPosition.X, Y = savedPosition.Y, Z = savedPosition.Z})
            config:Save()
        end

        WindUI:Notify({Title="Position Saved", Content=tostring(savedPosition), Duration=3})
    end
})

-- Tombol Load Saved Position (hanya jalan kalau ditekan)
TpTab:Button({
    Title = "Load Saved Position",
    Callback = function()
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local hrp = character:WaitForChild("HumanoidRootPart")

        if savedPosition then
            hrp.CFrame = CFrame.new(savedPosition)
            WindUI:Notify({Title="Loaded Saved Position", Content=tostring(savedPosition), Duration=3})
        else
            WindUI:Notify({Title="Info", Content="No saved position found, please save first.", Duration=3})
        end
    end
})

-- Spawn  Tab
local SpawnBoatTab = Window:Tab({  
    Title = "Spawn Boat",  
    Icon = "ship"
})

-- Boat Types
-- Extended Boat Types (Including Premium)
local boatTypes = {
    -- Free Boats
    {Title = "Small Boat", Id = 1, Premium = false},
    {Title = "Kayak", Id = 2, Premium = false},
    {Title = "Jetski", Id = 3, Premium = false},
    {Title = "Highfield", Id = 4, Premium = false},
    {Title = "Speed Boat", Id = 5, Premium = false},
    {Title = "Fishing Boat", Id = 6, Premium = false},
    
    -- Premium Boats (akan di-bypass)
    {Title = "Mini Yacht", Id = 14, Premium = true},
    {Title = "Hyper Boat", Id = 7, Premium = true},
    {Title = "Frozen Boat", Id = 11, Premium = true},
    {Title = "Cruiser Boat", Id = 13, Premium = true},
    {Title = "Luxury Yacht", Id = 15, Premium = true},
    {Title = "Submarine", Id = 16, Premium = true},
    {Title = "Mega Cruiser", Id = 17, Premium = true}
}

-- Bypass premium check
local function spawnBoatFree(boatId)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local RFSpawnBoat = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RF/SpawnBoat"]
    
    -- Bypass premium validation
    local oldInvoke = RFSpawnBoat.InvokeServer
    RFSpawnBoat.InvokeServer = function(self, id)
        -- Override premium check
        return oldInvoke(self, id, {Premium = true})
    end
    
    -- Spawn boat
    local success = pcall(function()
        RFSpawnBoat:InvokeServer(boatId)
    end)
    
    -- Restore original function
    RFSpawnBoat.InvokeServer = oldInvoke
    
    return success
end

-- Buat list nama untuk dropdown
local boatNames = {}
for _, boat in ipairs(boatTypes) do
    table.insert(boatNames, boat.Title)
end

-- Default selected boat
local selectedBoat = boatNames[1]

-- Paragraph
SpawnBoatTab:Paragraph({
    Title = "Set All Boat Speed 1000",
})

-- Toggle
SpawnBoatTab:Toggle({
    Title = "Super Speed Boats",
    Default = false,
    Callback = function(state)
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local BoatsModule = require(ReplicatedStorage.Shared.BoatsHandlingData)

        -- Simpan Speed asli untuk restore
        if not BoatsModule._OriginalSpeed then
            BoatsModule._OriginalSpeed = {}
            for boatName, boatData in pairs(BoatsModule) do
                BoatsModule._OriginalSpeed[boatName] = boatData.Speed
            end
        end

        if state then
            -- ON: Set semua boat Speed = 1000
            for _, boatData in pairs(BoatsModule) do
                boatData.Speed = 1000
            end
        else
            -- OFF: Restore Speed asli
            for boatName, boatData in pairs(BoatsModule) do
                if BoatsModule._OriginalSpeed[boatName] then
                    boatData.Speed = BoatsModule._OriginalSpeed[boatName]
                end
            end
        end
    end
})

-- Paragraph
SpawnBoatTab:Paragraph({
    Title = "Spawn Boats",
    Desc = "Select a boat from dropdown and press Spawn."
})

-- Dropdown Boat
SpawnBoatTab:Dropdown({
    Title = "Select Boat",
    Values = boatNames,
    Value = selectedBoat,
    Callback = function(value)
        selectedBoat = value
        WindUI:Notify({Title="Boat Selected", Content=value, Duration=3})
    end
})

-- Tombol Spawn
SpawnBoatTab:Button({
    Title = "Spawn Boat",
    Icon = "ship",
    Callback = function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local RFSpawnBoat = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RF/SpawnBoat"]
        if RFSpawnBoat then
            -- Cari ID boat yang sesuai nama
            local boatId
            for _, boat in ipairs(boatTypes) do
                if boat.Title == selectedBoat then
                    boatId = boat.Id
                    break
                end
            end

            if boatId then
                local success, err = pcall(function()
                    RFSpawnBoat:InvokeServer(boatId)
                end)
                if success then
                    WindUI:Notify({Title="Boat Spawned", Content=selectedBoat, Duration=3})
                else
                    WindUI:Notify({Title="Spawn Error", Content=tostring(err), Duration=5})
                end
            else
                WindUI:Notify({Title="Spawn Error", Content="Boat ID not found!", Duration=5})
            end
        end
    end
})

-- Buy Rod Tab
local BuyRodTab = Window:Tab({  
    Title = "Shop",  
    Icon = "shopping-cart"
})

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RFPurchaseFishingRod = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RF/PurchaseFishingRod"]
local RFPurchaseBait = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RF/PurchaseBait"]
local RFPurchaseWeatherEvent = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RF/PurchaseWeatherEvent"]
local RFPurchaseBoat = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RF/PurchaseBoat"]

-- ===== Rod Data =====
local rods = {
    ["Luck Rod"] = 79,
    ["Carbon Rod"] = 76,
    ["Grass Rod"] = 85,
    ["Demascus Rod"] = 77,
    ["Ice Rod"] = 78,
    ["Lucky Rod"] = 4,
    ["Midnight Rod"] = 80,
    ["Steampunk Rod"] = 6,
    ["Chrome Rod"] = 7,
    ["Astral Rod"] = 5,
    ["Ares Rod"] = 126,
    ["Angler Rod"] = 168
}

-- Dropdown display names (nama + harga)
local rodNames = {
    "Luck Rod (350 Coins)", "Carbon Rod (900 Coins)", "Grass Rod (1.5k Coins)", "Demascus Rod (3k Coins)",
    "Ice Rod (5k Coins)", "Lucky Rod (15k Coins)", "Midnight Rod (50k Coins)", "Steampunk Rod (215k Coins)",
    "Chrome Rod (437k Coins)", "Astral Rod (1M Coins)", "Ares Rod (3M Coins)", "Angler Rod ($8M Coins)"
}

-- Mapping dari display name ke key asli
local rodKeyMap = {
    ["Luck Rod (350 Coins)"]="Luck Rod",
    ["Carbon Rod (900 Coins)"]="Carbon Rod",
    ["Grass Rod (1.5k Coins)"]="Grass Rod",
    ["Demascus Rod (3k Coins)"]="Demascus Rod",
    ["Ice Rod (5k Coins)"]="Ice Rod",
    ["Lucky Rod (15k Coins)"]="Lucky Rod",
    ["Midnight Rod (50k Coins)"]="Midnight Rod",
    ["Steampunk Rod (215k Coins)"]="Steampunk Rod",
    ["Chrome Rod (437k Coins)"]="Chrome Rod",
    ["Astral Rod (1M Coins)"]="Astral Rod",
    ["Ares Rod (3M Coins)"]="Ares Rod",
    ["Angler Rod (8M Coins)"]="Angler Rod"
}

local selectedRod = rodNames[1]

-- ===== Dropdown =====
BuyRodTab:Dropdown({
    Title = "Select Rod",
    Values = rodNames,
    Value = selectedRod,
    Callback = function(value)
        selectedRod = value
        WindUI:Notify({Title="Rod Selected", Content=value, Duration=3})
    end
})

-- ===== Tombol Buy Rod =====
BuyRodTab:Button({
    Title="Buy Rod",
    Callback=function()
        local key = rodKeyMap[selectedRod] -- ambil key asli
        if key and rods[key] then
            local success, err = pcall(function()
                RFPurchaseFishingRod:InvokeServer(rods[key])
            end)
            if success then
                WindUI:Notify({Title="Rod Purchase", Content="Purchased "..selectedRod, Duration=3})
            else
                WindUI:Notify({Title="Rod Purchase Error", Content=tostring(err), Duration=5})
            end
        end
    end
})

-- ===== Bait Data =====
local baits = {
    ["TopWater Bait"] = 10,
    ["Lucky Bait"] = 2,
    ["Midnight Bait"] = 3,
    ["Chroma Bait"] = 6,
    ["Dark Mater Bait"] = 8,
    ["Corrupt Bait"] = 15,
    ["Aether Bait"] = 16
}

-- Dropdown display names (nama + harga + "Coins")
local baitNames = {
    "TopWater Bait (100 Coins)",
    "Lucky Bait (1k Coins)",
    "Midnight Bait (3k Coins)",
    "Chroma Bait (290k Coins)",
    "Dark Mater Bait (630k Coins)",
    "Corrupt Bait (1.15M Coins)",
    "Aether Bait (3.7M Coins)"
}

-- Mapping display name -> key asli
local baitKeyMap = {
    ["TopWater Bait (100 Coins)"] = "TopWater Bait",
    ["Lucky Bait (1k Coins)"] = "Lucky Bait",
    ["Midnight Bait (3k Coins)"] = "Midnight Bait",
    ["Chroma Bait (290k Coins)"] = "Chroma Bait",
    ["Dark Mater Bait (630k Coins)"] = "Dark Mater Bait",
    ["Corrupt Bait (1.15M Coins)"] = "Corrupt Bait",
    ["Aether Bait (3.7M Coins)"] = "Aether Bait"
}

local selectedBait = baitNames[1]

-- ===== Paragraph =====
BuyRodTab:Paragraph({
    Title = "Buy Bait",
    Desc = "Select a bait to purchase."
})

-- ===== Dropdown =====
BuyRodTab:Dropdown({
    Title="Select Bait",
    Values=baitNames,
    Value=selectedBait,
    Callback=function(value)
        selectedBait = value
        WindUI:Notify({
            Title="Bait Selected",
            Content=value,
            Duration=3
        })
    end
})

-- ===== Tombol Buy Bait =====
BuyRodTab:Button({
    Title="Buy Bait",
    Callback=function()
        local key = baitKeyMap[selectedBait] -- ambil key asli
        if key and baits[key] then
            local amount = baits[key]
            local success, err = pcall(function()
                RFPurchaseBait:InvokeServer(amount)
            end)
            if success then
                WindUI:Notify({
                    Title="Bait Purchase",
                    Content="Purchased "..selectedBait.." x"..amount,
                    Duration=3
                })
            else
                WindUI:Notify({
                    Title="Bait Purchase Error",
                    Content=tostring(err),
                    Duration=5
                })
            end
        end
    end
})

-- ===== Weather Data =====
local weathers = {
    ["Wind"] = 10000,
    ["Snow"] = 15000,
    ["Cloudy"] = 20000,
    ["Storm"] = 35000,
    ["Radiant"] = 50000,
    ["Shark Hunt"] = 300000
}

-- Dropdown display names
local weatherNames = {
    "Wind (10k Coins)", "Snow (15k Coins)", "Cloudy (20k Coins)", "Storm (35k Coins)",
    "Radiant (50k Coins)", "Shark Hunt (300k Coins)"
}

-- Mapping display name -> key asli
local weatherKeyMap = {
    ["Wind (10k Coins)"] = "Wind",
    ["Snow (15k Coins)"] = "Snow",
    ["Cloudy (20k Coins)"] = "Cloudy",
    ["Storm (35k Coins)"] = "Storm",
    ["Radiant (50k Coins)"] = "Radiant",
    ["Shark Hunt (300k Coins)"] = "Shark Hunt"
}

-- Selected weathers (multi-select)
local selectedWeathers = {weatherNames[1]} -- default

-- ===== Paragraph =====
BuyRodTab:Paragraph({
    Title="Buy Weather",
    Desc="Select weather(s) to purchase automatically."
})

-- ===== Multi-Select Dropdown =====
local weatherDropdown = BuyRodTab:Dropdown({
    Title="Select Weather(s)",
    Values=weatherNames,
    Multi=true, -- multi-select
    Value=selectedWeathers,
    Callback=function(values)
        selectedWeathers = values -- update selection
        WindUI:Notify({
            Title="Weather Selected",
            Content="Selected "..#values.." weather(s)",
            Duration=2
        })
    end
})

-- ===== Toggle Auto Buy =====
local autoBuyEnabled = false
local buyDelay = 0.5 -- delay antar pembelian

local function startAutoBuy()
    task.spawn(function()
        while autoBuyEnabled do
            for _, displayName in ipairs(selectedWeathers) do
                local key = weatherKeyMap[displayName]
                if key and weathers[key] then
                    local success, err = pcall(function()
                        RFPurchaseWeatherEvent:InvokeServer(key)
                    end)
                    if success then
                        WindUI:Notify({
                            Title="Auto Buy",
                            Content="Purchased "..displayName,
                            Duration=1
                        })
                    else
                        warn("Error buying weather:", err)
                    end
                    task.wait(buyDelay)
                end
            end
            task.wait(0.1) -- loop kecil supaya bisa break saat toggle dimatikan
        end
    end)
end

BuyRodTab:Toggle({
    Title = "Auto Buy Weather",
    Desc = "Automatically purchase selected weather(s).",
    Value = false,
    Callback = function(state)
        autoBuyEnabled = state
        if state then
            WindUI:Notify({
                Title = "Auto Buy",
                Content = "Enabled",
                Duration = 2
            })
            startAutoBuy()
        else
            WindUI:Notify({
                Title = "Auto Buy",
                Content = "Disabled",
                Duration = 2
            })
        end
    end
})

-- Urutan boat
local boatOrder = {
    "Small Boat",
    "Kayak",
    "Jetski",
    "Highfield",
    "Speed Boat",
    "Fishing Boat",
    "Mini Yacht",
    "Hyper Boat",
    "Frozen Boat",
    "Cruiser Boat"
}

-- Data boat
local boats = {
    ["Small Boat"] = {Id = 1, Price = 300},
    ["Kayak"] = {Id = 2, Price = 1100},
    ["Jetski"] = {Id = 3, Price = 7500},
    ["Highfield"] = {Id = 4, Price = 25000},
    ["Speed Boat"] = {Id = 5, Price = 70000},
    ["Fishing Boat"] = {Id = 6, Price = 180000},
    ["Mini Yacht"] = {Id = 14, Price = 1200000},
    ["Hyper Boat"] = {Id = 7, Price = 999000},
    ["Frozen Boat"] = {Id = 11, Price = 0},
    ["Cruiser Boat"] = {Id = 13, Price = 0}
}

-- Buat display names sesuai urutan
local boatNames = {}
for _, name in ipairs(boatOrder) do
    local data = boats[name]
    local priceStr
    if data.Price >= 1000000 then
        priceStr = string.format("%.2fM Coins", data.Price/1000000)
    elseif data.Price >= 1000 then
        priceStr = string.format("%.0fk Coins", data.Price/1000)
    else
        priceStr = data.Price.." Coins"
    end
    table.insert(boatNames, name.." ("..priceStr..")")
end

-- Buat keyMap sesuai urutan
local boatKeyMap = {}
for _, displayName in ipairs(boatNames) do
    local nameOnly = displayName:match("^(.-) %(") -- ambil nama sebelum tanda '('
    boatKeyMap[displayName] = nameOnly
end

-- Selected default
local selectedBoat = boatNames[1]

-- ===== Paragraph =====
BuyRodTab:Paragraph({
    Title="Buy Boat",
    Desc="Select a Boat to purchase."
})

-- ===== Dropdown =====
BuyRodTab:Dropdown({
    Title = "Select Boat",
    Values = boatNames,
    Value = selectedBoat,
    Callback = function(value)
        selectedBoat = value
        WindUI:Notify({
            Title = "Boat Selected",
            Content = value,
            Duration = 3
        })
    end
})

-- ===== Tombol Buy Boat =====
BuyRodTab:Button({
    Title = "Buy Boat",
    Callback = function()
        local key = boatKeyMap[selectedBoat]
        if key and boats[key] then
            local success, err = pcall(function()
                RFPurchaseBoat:InvokeServer(boats[key].Id)
            end)
            if success then
                WindUI:Notify({
                    Title = "Boat Purchase",
                    Content = "Purchased "..selectedBoat,
                    Duration = 3
                })
            else
                WindUI:Notify({
                    Title = "Boat Purchase Error",
                    Content = tostring(err),
                    Duration = 5
                })
            end
        end
    end
})

local karakterTab = Window:Tab({  
    Title = "User",  
    Icon = "user-plus"
})

karakterTab:Paragraph({
    Title = "Change Ability Your Character",
})

-- ===== Speed Hack Slider =====
karakterTab:Slider({
    Title = "Speed Hack",
    Value = {
        Min = 18,
        Max = 200,
        Default = 18
    },
    Callback = function(value)
        local player = game.Players.LocalPlayer
        local char = player.Character or player.CharacterAdded:Wait()
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = value
        end
        WindUI:Notify({
            Title = "Speed Hack",
            Content = "WalkSpeed set to "..value,
            Duration = 2
        })
    end
})

karakterTab:Button({
    Title = "Reset SpeedHack",
    Desc = "Return to normal speed",
    Callback = function()
        local player = game.Players.LocalPlayer
        local char = player.Character or player.CharacterAdded:Wait()
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = 18
        end
        WindUI:Notify({
            Title = "SpeedHack Reset",
            Content = "WalkSpeed dikembalikan ke normal (18)",
            Duration = 2
        })
    end
})

local infinityJumpToggle = karakterTab:Toggle({
    Title = "Infinity Jump",
    Value = false,
    Callback = function(state)
        _G.InfinityJumpEnabled = state
        local UserInputService = game:GetService("UserInputService")
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer

        -- Disconnect existing connections
        if _G.InfinityJumpConnection then
            _G.InfinityJumpConnection:Disconnect()
            _G.InfinityJumpConnection = nil
        end

        if state then
            local function tryJump()
                local char = player.Character or player.CharacterAdded:Wait()
                local humanoid = char:FindFirstChild("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end

            -- PC keyboard (Space)
            _G.InfinityJumpConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed then return end
                if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Space then
                    tryJump()
                elseif input.UserInputType == Enum.UserInputType.Touch then
                    tryJump()
                end
            end)

            -- Android / Touch hold
            UserInputService.TouchMoved:Connect(function(touch, gameProcessed)
                if _G.InfinityJumpEnabled then
                    tryJump()
                end
            end)
        end
    end
})

-- ===== Noclip Toggle =====
local noclipEnabled = false
karakterTab:Toggle({
    Title = "Noclip",
    Desc = "Can go through objects",
    Value = false,
    Callback = function(state)
        noclipEnabled = state
        local player = game.Players.LocalPlayer
        local char = player.Character or player.CharacterAdded:Wait()

        if state then
            _G.NoclipConnection = game:GetService("RunService").RenderStepped:Connect(function()
                if char then
                    for _, part in ipairs(char:GetChildren()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
            WindUI:Notify({Title="Noclip", Content="Enabled", Duration=2})
        else
            if _G.NoclipConnection then
                _G.NoclipConnection:Disconnect()
                _G.NoclipConnection = nil
            end
            if char then
                for _, part in ipairs(char:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
            WindUI:Notify({Title="Noclip", Content="Disabled", Duration=2})
        end
    end
})


local walkOnWaterEnabled = false
local floatHeight = 3
local player = game.Players.LocalPlayer
local runService = game:GetService("RunService")

-- Simpan reference BodyPosition & connection
local bp, floatConnection

local function setupFloat()
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")

    -- BodyPosition untuk mengatur posisi Y
    bp = Instance.new("BodyPosition")
    bp.MaxForce = Vector3.new(0, math.huge, 0)
    bp.D = 15
    bp.P = 2000
    bp.Position = hrp.Position
    bp.Parent = hrp

    -- Loop RenderStepped untuk update posisi
    floatConnection = runService.RenderStepped:Connect(function(delta)
        if walkOnWaterEnabled and hrp and hrp.Parent then
            local ray = Ray.new(hrp.Position, Vector3.new(0, -50, 0))
            local part, pos = workspace:FindPartOnRay(ray, char)
            if part and (part.Material == Enum.Material.Water or part.Name:lower():find("lava")) then
                bp.Position = Vector3.new(hrp.Position.X, pos.Y + floatHeight, hrp.Position.Z)
            else
                -- Kalau bukan air/lava, biarkan jatuh normal
                bp.Position = hrp.Position
            end
        end
    end)
end

-- Toggle di karakterTab
karakterTab:Toggle({
    Title = "Fly Little",
    Desc = "Raise your character a little and make your character float",
    Value = false,
    Callback = function(state)
        walkOnWaterEnabled = state
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")

        if state then
            setupFloat()
            WindUI:Notify({Title="Walk On Water", Content="Enabled", Duration=2})
        else
            if floatConnection then
                floatConnection:Disconnect()
                floatConnection = nil
            end
            if bp then
                bp:Destroy()
                bp = nil
            end
            WindUI:Notify({Title="Walk On Water", Content="Disabled", Duration=2})
        end
    end
})

karakterTab:Paragraph({
    Title = "Visual / ESP",
})

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

-- Folder untuk ESP
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "PlayerESP"
ESPFolder.Parent = CoreGui

local playerESPEnabled = false

-- Fungsi membuat ESP (hanya dipanggil saat toggle ON)
local function CreatePlayerESP(player)
    if player == LocalPlayer or ESPFolder:FindFirstChild(player.Name) then return end
    local character = player.Character
    if not character then return end
    local head = character:FindFirstChild("Head")
    if not head then return end

    local container = Instance.new("Folder")
    container.Name = player.Name
    container.Parent = ESPFolder

    -- Highlight biru
    local highlight = Instance.new("Highlight")
    highlight.Adornee = character
    highlight.FillTransparency = 1
    highlight.OutlineColor = Color3.fromRGB(0, 170, 255) -- BIRU
    highlight.OutlineTransparency = 0
    highlight.Parent = container

    -- NameTag
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "NameTag"
    billboard.Adornee = head
    billboard.Size = UDim2.new(0, 100, 0, 20)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = container

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.new(1, 1, 1) -- Putih
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextScaled = true
    nameLabel.Parent = billboard
end

-- Hapus semua ESP
local function ClearESP()
    ESPFolder:ClearAllChildren()
end

-- Mulai ESP loop
local connection
local function StartESP()
    if connection then return end
    connection = RunService.Heartbeat:Connect(function()
        if playerESPEnabled then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    if not ESPFolder:FindFirstChild(player.Name) then
                        CreatePlayerESP(player)
                    end
                end
            end
        else
            ClearESP()
            if connection then
                connection:Disconnect()
                connection = nil
            end
        end
    end)
end

-- Toggle GUI
karakterTab:Toggle({
    Title = "Player ESP",
    Desc = "Show ESP for Other Players with Blue Outline and White NameTag",
    Value = false,
    Callback = function(state)
        playerESPEnabled = state
        if state then
            StartESP()
        else
            ClearESP()
            if connection then
                connection:Disconnect()
                connection = nil
            end
        end
    end
})

-- Hapus ESP saat pemain keluar
Players.PlayerRemoving:Connect(function(player)
    local esp = ESPFolder:FindFirstChild(player.Name)
    if esp then esp:Destroy() end
end)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

-- Folder untuk ESP
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "PlayerESP"
ESPFolder.Parent = CoreGui

local playerESPEnabled = false
local hue = 0

-- Fungsi membuat ESP
local function CreatePlayerESP(player)
    if player == LocalPlayer or ESPFolder:FindFirstChild(player.Name) then return end
    local character = player.Character
    if not character then return end
    local head = character:FindFirstChild("Head")
    if not head then return end

    local container = Instance.new("Folder")
    container.Name = player.Name
    container.Parent = ESPFolder

    -- Highlight rainbow
    local highlight = Instance.new("Highlight")
    highlight.Adornee = character
    highlight.FillTransparency = 1
    highlight.OutlineColor = Color3.fromHSV(hue/360, 1, 1)
    highlight.OutlineTransparency = 0
    highlight.Parent = container

    -- NameTag
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "NameTag"
    billboard.Adornee = head
    billboard.Size = UDim2.new(0, 100, 0, 20)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = container

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextScaled = true
    nameLabel.Parent = billboard
end

-- Update warna ESP (rainbow)
local function UpdateESPColors()
    hue = (hue + 5) % 360
    for _, container in pairs(ESPFolder:GetChildren()) do
        local highlight = container:FindFirstChildWhichIsA("Highlight")
        if highlight then
            highlight.OutlineColor = Color3.fromHSV(hue/360, 1, 1)
        end
    end
end

-- Hapus semua ESP
local function ClearESP()
    ESPFolder:ClearAllChildren()
end

-- Mulai ESP loop
local connection
local function StartESP()
    if connection then return end
    connection = RunService.Heartbeat:Connect(function()
        if playerESPEnabled then
            UpdateESPColors()
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    if not ESPFolder:FindFirstChild(player.Name) then
                        CreatePlayerESP(player)
                    end
                end
            end
        else
            ClearESP()
            if connection then
                connection:Disconnect()
                connection = nil
            end
        end
    end)
end

-- Toggle GUI
karakterTab:Toggle({
    Title = "Player ESP",
    Desc = "Show ESP for Other Players with Rainbow Outline and White NameTag",
    Value = false,
    Callback = function(state)
        playerESPEnabled = state
        if state then
            StartESP()
        else
            ClearESP()
            if connection then
                connection:Disconnect()
                connection = nil
            end
        end
    end
})

-- Hapus ESP saat pemain keluar
Players.PlayerRemoving:Connect(function(player)
    local esp = ESPFolder:FindFirstChild(player.Name)
    if esp then esp:Destroy() end
end)

karakterTab:Paragraph({
    Title = "Trade",
})

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RemoteFunction langsung
local RFInitiateTrade = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RF/InitiateTrade"]

local selectedPlayer = nil
local playerDropdown = nil

-- Refresh dropdown player
local function refreshPlayerDropdown()
    if playerDropdown then
        playerDropdown:Remove()
    end

    local playerNames = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(playerNames, plr.Name)
        end
    end

    selectedPlayer = #playerNames > 0 and playerNames[1] or nil

    playerDropdown = karakterTab:Dropdown({
        Title = "Select Player",
        Values = playerNames,
        Value = selectedPlayer,
        Callback = function(value)
            selectedPlayer = value
            WindUI:Notify({Title="Player Selected", Content=value, Duration=3})
        end
    })
end

refreshPlayerDropdown()

-- Tombol trade langsung
karakterTab:Button({
    Title = "Give Item",
    Callback = function()
        if not selectedPlayer then
            WindUI:Notify({Title="Error", Content="Tidak ada player yang dipilih!", Duration=3})
            return
        end

        local targetPlayer = Players:FindFirstChild(selectedPlayer)
        if not targetPlayer then
            WindUI:Notify({Title="Error", Content="Player tidak ditemukan!", Duration=3})
            return
        end

        -- Invoke remote langsung
        local success, err = pcall(function()
            -- Ganti UUID item sesuai kebutuhanmu
            RFInitiateTrade:InvokeServer(targetPlayer.UserId, "36a63fb5-df50-4d51-9b05-9d226ccd3ce7")
        end)

        if success then
            WindUI:Notify({Title="Success", Content="Trade request dikirim ke "..selectedPlayer, Duration=3})
        else
            WindUI:Notify({Title="Error", Content="Trade gagal: "..tostring(err), Duration=3})
        end
    end
})

-- Loop refresh dropdown tiap detik
spawn(function()
    while true do
        wait(1)
        refreshPlayerDropdown()
    end
end)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RemoteFunction
local RFAwaitTradeResponse = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RF/AwaitTradeResponse"]

-- Toggle state
local autoAcceptEnabled = false

-- Toggle di GUI
karakterTab:Toggle({
    Title = "Auto Accept Trade",
    Callback = function(state)
        autoAcceptEnabled = state
        WindUI:Notify({Title="Auto Accept", Content=state and "ON" or "OFF", Duration=3})
    end
})

-- Hook Auto Accept Trade
RFAwaitTradeResponse.OnClientInvoke = newcclosure(function(itemData, fromPlayer, serverTime)
    if autoAcceptEnabled then
        -- Terima trade otomatis
        return true
    else
        -- Normal behavior (tidak auto accept)
        return false
    end
end)

karakterTab:Paragraph({
    Title = "Auto Sell Fish",
    Desc = "Comming Soon",
})

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RFSellItem = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RF/SellItem"]

-- UUID item
local itemUUID = "aad4dfaf-3144-4202-8dea-d7f7c7a9f33a"

-- Toggle
local autoSell = false
karakterTab:Toggle({
    Title = "Auto Sell Toggle",
    Value = false,
    Callback = function(val)
        autoSell = val
        WindUI:Notify({Title="Auto Sell", Content="Status: "..tostring(val), Duration=3})
    end
})

-- Loop auto sell
spawn(function()
    while true do
        wait(1)
        if autoSell then
            pcall(function()
                RFSellItem:InvokeServer(itemUUID)
            end)
        end
    end
end)

-- Settings Tab
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })

-- Paragraph Info
SettingsTab:Paragraph({
    Title = "Interface",
    Desc = "Customize your GUI appearance."
})

-- Ambil semua theme yang tersedia
local themes = {}
for themeName,_ in pairs(WindUI:GetThemes()) do
    table.insert(themes, themeName)
end
table.sort(themes)

-- Load saved config (jika ada)
local savedConfig
if Window.ConfigManager then
    savedConfig = Window.ConfigManager:CreateConfig("Sypher Hub"):Load()
end

-- Tentukan default values
local defaultTheme = (savedConfig and savedConfig.Theme) or WindUI:GetCurrentTheme()
local defaultTransparency = (savedConfig and savedConfig.TransparentMode ~= nil) and savedConfig.TransparentMode or true

-- Theme Dropdown
local themeDropdown = SettingsTab:Dropdown({
    Title = "Select Theme",
    Values = themes,
    Value = defaultTheme,
    Callback = function(theme)
        WindUI:SetTheme(theme)
        WindUI:Notify({
            Title = "Theme Applied",
            Content = theme,
            Icon = "palette",
            Duration = 2
        })

        -- Auto-save theme
        if Window.ConfigManager then
            local config = Window.ConfigManager:CreateConfig("Sypher Hub")
            config:Set("Theme", theme)
            config:Set("TransparentMode", Window.TransparencyEnabled) -- simpan transparency juga
            config:Save()
        end
    end
})

-- Toggle Transparency
local transparentToggle = SettingsTab:Toggle({
    Title = "Transparency",
    Desc = "Makes the interface slightly transparent.",
    Value = defaultTransparency,
    Callback = function(state)
        Window:ToggleTransparency(state)
        WindUI.TransparencyValue = state and 0.1 or 1
        WindUI:Notify({
            Title = "Transparency",
            Content = state and "Transparency ON" or "Transparency OFF",
            Duration = 2
        })

        -- Auto-save transparency
        if Window.ConfigManager then
            local config = Window.ConfigManager:CreateConfig("Sypher Hub")
            config:Set("Theme", WindUI:GetCurrentTheme()) -- simpan theme juga
            config:Set("TransparentMode", state)
            config:Save()
        end
    end
})

-- Apply default values saat GUI load
WindUI:SetTheme(defaultTheme)
Window:ToggleTransparency(defaultTransparency)
WindUI.TransparencyValue = defaultTransparency and 0.1 or 1

SettingsTab:Keybind({
    Title = "Toggle UI",
    Desc = "Press a key to open/close the UI",
    Value = "G", -- gunakan string nama key
    Callback = function(keyName)
        Window:SetToggleKey(Enum.KeyCode[keyName]) -- konversi ke Enum
        --print("Keybind set to:", keyName)
    end
})

-- Optional: paragraph untuk info
SettingsTab:Paragraph({
    Title = "Configuration",
    Desc = "Theme and Transparency are auto-saved and auto-loaded."
})

local configName = ""

SettingsTab:Input({
    Title = "Config Name",
    Placeholder = "Enter config name",
    Callback = function(text)
        configName = text
    end
})

local filesDropdown
local function listConfigFiles()
    local files = {}
    local path = "WindUI/" .. Window.Folder .. "/config"
    if not isfolder(path) then
        makefolder(path)
    end
    for _, file in ipairs(listfiles(path)) do
        local name = file:match("([^/]+)%.json$")
        if name then table.insert(files, name) end
    end
    return files
end

filesDropdown = SettingsTab:Dropdown({
    Title = "Select Config",
    Values = listConfigFiles(),
    Multi = false,
    AllowNone = true,
    Callback = function(selection)
        configName = selection
    end
})

SettingsTab:Button({
    Title = "Refresh List",
    Callback = function()
        filesDropdown:Refresh(listConfigFiles())
    end
})

SettingsTab:Button({
    Title = "Save Config",
    Desc = "Save current theme and transparency",
    Callback = function()
        if configName ~= "" then
            local config = Window.ConfigManager:CreateConfig(configName)
            config:Register("Theme", themeDropdown)
            config:Register("Transparency", transparentToggle)
            config:Save()
            WindUI:Notify({
                Title = "Config Saved",
                Content = configName,
                Duration = 3
            })
        end
    end
})

SettingsTab:Button({
    Title = "Load Config",
    Desc = "Load saved configuration",
    Callback = function()
        if configName ~= "" then
            local config = Window.ConfigManager:CreateConfig(configName)
            local data = config:Load()
            if data then
                if data.Theme and table.find(themes, data.Theme) then
                    themeDropdown:Select(data.Theme)
                    WindUI:SetTheme(data.Theme)
                end
                if data.Transparency ~= nil then
                    transparentToggle:Set(data.Transparency)
                    Window:ToggleTransparency(data.Transparency)
                    WindUI.TransparencyValue = data.Transparency and 0.1 or 1
                end
                WindUI:Notify({
                    Title = "Config Loaded",
                    Content = configName,
                    Duration = 3
                })
            else
                WindUI:Notify({
                    Title = "Config Error",
                    Content = "Config file not found",
                    Duration = 3
                })
            end
        end
    end
})

-- Select first tab on GUI open
Window:SelectTab(1)
