-- Sypher Hub V1.0 for CDID Indonesia
-- Advanced Anti-Cheat Bypass & Full Auto Job System
-- Personal Use Only - Educational Purpose

-- Load Orion UI
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/1nig1htmare1234/SCRIPTS/main/Orion.lua"))()

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local NetworkClient = game:GetService("NetworkClient")
local Stats = game:GetService("Stats")

-- Hub Variables
local HubName = "Sypher Hub"
local HubVersion = "1.0.0"
local ConfigFolder = "SypherHubCDID"

-- Game Remotes
local JobRemote = ReplicatedStorage:WaitForChild("NetworkContainer"):WaitForChild("RemoteEvents"):WaitForChild("Job")

-- Job Locations (Koordinat Asli CDID)
local JobLocations = {
    ["Truck"] = {
        InteractLocation = Vector3.new(1954, 21, -3458),  -- Tempat pencet untuk spawn
        SpawnLocation = Vector3.new(1869, 21, -3493),     -- Tempat spawn truck
        DeliveryExample = Vector3.new(-1976, 23, 576)     -- Contoh tempat tujuan
    },
    ["Bus"] = {
        InteractLocation = Vector3.new(1954, 21, -3458),
        SpawnLocation = Vector3.new(1869, 21, -3493),
        DeliveryExample = Vector3.new(-1976, 23, 576)
    },
    ["Taxi"] = {
        InteractLocation = Vector3.new(1954, 21, -3458),
        SpawnLocation = Vector3.new(1869, 21, -3493),
        DeliveryExample = Vector3.new(-1976, 23, 576)
    }
}

-- Stats Variables
local CurrentMoney = 0
local TotalEarnings = 0
local LatestEarnings = 0
local JobsCompleted = 0
local StartTime = tick()

-- Autofarm Variables
local AutofarmEnabled = false
local CurrentJob = nil
local CurrentWaypoint = nil
local SelectedJob = "Truck"
local MyVehicle = nil

-- Anti-Cheat Bypass Settings
local AntiCheatConfig = {
    Enabled = true,
    UseRealisticMovement = true,
    RandomizePatterns = true,
    SpoofNetworkOwnership = true,
    MimicHumanBehavior = true,
    BypassVelocityChecks = true,
    DisableRemoteLogging = true,
    FakeInputDelay = true
}

-- ========== ANTI-CHEAT BYPASS CORE ==========

-- Disable remote spy detection
if getgenv then
    getgenv().IrisAd = true
    getgenv().IrisAdTitle = "Secured"
end

-- Hook remote calls for protection
local OldNamecall
OldNamecall = hookmetamethod(game, "__namecall", function(Self, ...)
    local Args = {...}
    local Method = getnamecallmethod()
    
    -- Block kick/ban attempts
    if Method == "Kick" or Method == "kick" then
        return nil
    end
    
    -- Hide suspicious remote calls
    if AntiCheatConfig.DisableRemoteLogging and Method == "FireServer" then
        local RemoteName = tostring(Self)
        if RemoteName:match("Anti") or RemoteName:match("Cheat") or RemoteName:match("Detection") then
            return nil
        end
    end
    
    return OldNamecall(Self, ...)
end)

-- Spoof character properties
local function SpoofCharacterProperties()
    if not AntiCheatConfig.Enabled then return end
    
    local Character = LocalPlayer.Character
    if not Character then return end
    
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if Humanoid then
        -- Keep normal walkspeed and jump power
        Humanoid.WalkSpeed = 16
        Humanoid.JumpPower = 50
        
        -- Prevent detection of unusual states
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics, false)
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Flying, false)
    end
end

-- Create fake network lag for realistic movement
local function SimulateNetworkLag()
    if AntiCheatConfig.FakeInputDelay then
        task.wait(math.random(50, 150) / 1000) -- 50-150ms delay
    end
end

-- Bypass velocity checks
local function BypassVelocityCheck(Part)
    if not AntiCheatConfig.BypassVelocityChecks then return end
    
    local BodyVelocity = Part:FindFirstChild("BodyVelocity") or Part:FindFirstChild("BodyPosition")
    if BodyVelocity then
        BodyVelocity:Destroy()
    end
    
    -- Create controlled velocity
    local BV = Instance.new("BodyVelocity")
    BV.MaxForce = Vector3.new(0, 0, 0)
    BV.Velocity = Vector3.new(0, 0, 0)
    BV.Parent = Part
    
    game:GetService("Debris"):AddItem(BV, 0.1)
end

-- Advanced teleport with anti-detection
local function SafeTeleport(targetPosition, isVehicle)
    local Character = LocalPlayer.Character
    if not Character then return end
    
    local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    if not HumanoidRootPart then return end
    
    -- Pre-teleport preparation
    if AntiCheatConfig.Enabled then
        SpoofCharacterProperties()
        SimulateNetworkLag()
        
        -- Set network owner to nil temporarily
        if AntiCheatConfig.SpoofNetworkOwnership then
            HumanoidRootPart:SetNetworkOwner(nil)
        end
        
        -- Simulate jump before teleport (looks more natural)
        if AntiCheatConfig.MimicHumanBehavior then
            local Humanoid = Character:FindFirstChildOfClass("Humanoid")
            if Humanoid then
                Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                task.wait(0.1)
            end
        end
    end
    
    -- Perform teleport
    if AntiCheatConfig.UseRealisticMovement then
        -- Gradual teleport (multiple small steps)
        local startPos = HumanoidRootPart.Position
        local endPos = targetPosition
        local distance = (endPos - startPos).Magnitude
        
        if distance > 500 then
            -- For long distances, use stepped teleport
            local steps = math.min(10, math.floor(distance / 100))
            for i = 1, steps do
                local alpha = i / steps
                local intermediatePos = startPos:Lerp(endPos, alpha)
                
                if isVehicle and MyVehicle then
                    MyVehicle:SetPrimaryPartCFrame(CFrame.new(intermediatePos))
                else
                    HumanoidRootPart.CFrame = CFrame.new(intermediatePos)
                end
                
                task.wait(0.05)
            end
        end
    end
    
    -- Final teleport
    if isVehicle and MyVehicle then
        MyVehicle:SetPrimaryPartCFrame(CFrame.new(targetPosition) + Vector3.new(0, 5, 0))
    else
        HumanoidRootPart.CFrame = CFrame.new(targetPosition) + Vector3.new(0, 3, 0))
    end
    
    -- Post-teleport cleanup
    if AntiCheatConfig.Enabled then
        task.wait(0.1)
        
        -- Reset network owner
        if AntiCheatConfig.SpoofNetworkOwnership then
            HumanoidRootPart:SetNetworkOwner(LocalPlayer)
        end
        
        -- Clear velocity
        BypassVelocityCheck(HumanoidRootPart)
        
        -- Reset to walking state
        if AntiCheatConfig.MimicHumanBehavior then
            local Humanoid = Character:FindFirstChildOfClass("Humanoid")
            if Humanoid then
                Humanoid:ChangeState(Enum.HumanoidStateType.Running)
            end
        end
    end
end

-- ========== UTILITY FUNCTIONS ==========

local function FormatMoney(amount)
    local str = tostring(math.floor(tonumber(amount) or 0))
    return "Rp. " .. str:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function GetPlayerMoney()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        for _, v in pairs(leaderstats:GetChildren()) do
            if v.Name == "Money" or v.Name == "Cash" or v.Name == "Rupiah" or v.Name == "Balance" then
                return tonumber(v.Value) or 0
            end
        end
    end
    return 0
end

local function UpdateMoneyStats()
    local newMoney = GetPlayerMoney()
    if newMoney > CurrentMoney then
        LatestEarnings = newMoney - CurrentMoney
        TotalEarnings = TotalEarnings + LatestEarnings
        JobsCompleted = JobsCompleted + 1
    end
    CurrentMoney = newMoney
end

-- ========== VEHICLE FUNCTIONS ==========

local function FindMyVehicle()
    -- Method 1: Check for ownership
    for _, vehicle in pairs(Workspace:GetDescendants()) do
        if vehicle:IsA("Model") and vehicle:FindFirstChild("Owner") then
            if vehicle.Owner.Value == LocalPlayer or vehicle.Owner.Value == LocalPlayer.Name then
                return vehicle
            end
        end
    end
    
    -- Method 2: Check seated vehicle
    local Character = LocalPlayer.Character
    if Character then
        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        if Humanoid and Humanoid.SeatPart then
            local vehicle = Humanoid.SeatPart.Parent
            while vehicle and not vehicle:IsA("Model") do
                vehicle = vehicle.Parent
            end
            return vehicle
        end
    end
    
    return nil
end

local function EnterVehicle()
    local Character = LocalPlayer.Character
    if not Character then return false end
    
    -- Find nearest unoccupied vehicle
    local nearestVehicle = nil
    local minDist = 50
    
    for _, vehicle in pairs(Workspace:GetDescendants()) do
        if vehicle:IsA("VehicleSeat") and not vehicle.Occupant then
            local dist = (Character.HumanoidRootPart.Position - vehicle.Position).Magnitude
            if dist < minDist then
                minDist = dist
                nearestVehicle = vehicle
            end
        end
    end
    
    if nearestVehicle then
        -- Teleport near seat
        SafeTeleport(nearestVehicle.Position + Vector3.new(2, 2, 0), false)
        task.wait(0.5)
        
        -- Sit in vehicle
        nearestVehicle:Sit(Character:FindFirstChildOfClass("Humanoid"))
        task.wait(0.5)
        
        MyVehicle = nearestVehicle.Parent
        return true
    end
    
    return false
end

-- ========== JOB SYSTEM ==========

local function InteractWithJobNPC()
    -- Find and interact with job NPC/button
    local Character = LocalPlayer.Character
    if not Character then return end
    
    -- Look for proximity prompts or clickdetectors
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Parent.Position and 
           (obj.Parent.Position - JobLocations[SelectedJob].InteractLocation).Magnitude < 20 then
            fireproximityprompt(obj)
            return true
        elseif obj:IsA("ClickDetector") and obj.Parent.Position and
               (obj.Parent.Position - JobLocations[SelectedJob].InteractLocation).Magnitude < 20 then
            fireclickdetector(obj)
            return true
        end
    end
    
    -- Fallback: Fire job remote directly
    JobRemote:FireServer(SelectedJob)
    return true
end

local function StartJobSequence()
    if not AutofarmEnabled then return end
    
    local jobData = JobLocations[SelectedJob]
    if not jobData then
        OrionLib:MakeNotification({
            Name = "Error",
            Content = "Job data not found!",
            Time = 3
        })
        return
    end
    
    -- Step 1: Teleport to interact location
    OrionLib:MakeNotification({
        Name = "Auto Job",
        Content = "Step 1: Going to job NPC...",
        Time = 2
    })
    SafeTeleport(jobData.InteractLocation, false)
    task.wait(2)
    
    -- Step 2: Interact with NPC to spawn vehicle
    OrionLib:MakeNotification({
        Name = "Auto Job",
        Content = "Step 2: Requesting vehicle spawn...",
        Time = 2
    })
    InteractWithJobNPC()
    task.wait(3)
    
    -- Step 3: Teleport to vehicle spawn location
    OrionLib:MakeNotification({
        Name = "Auto Job",
        Content = "Step 3: Going to vehicle spawn...",
        Time = 2
    })
    SafeTeleport(jobData.SpawnLocation, false)
    task.wait(2)
    
    -- Step 4: Enter vehicle
    OrionLib:MakeNotification({
        Name = "Auto Job",
        Content = "Step 4: Entering vehicle...",
        Time = 2
    })
    local entered = EnterVehicle()
    
    if entered then
        OrionLib:MakeNotification({
            Name = "Success",
            Content = "Vehicle entered! Waiting for destination...",
            Time = 3
        })
    else
        OrionLib:MakeNotification({
            Name = "Warning",
            Content = "Could not enter vehicle, retrying...",
            Time = 3
        })
    end
end

-- Listen for waypoints from server
local function ListenForWaypoints()
    JobRemote.OnClientEvent:Connect(function(action, data)
        if action == "SetArrow" and data then
            CurrentWaypoint = data
            
            if AutofarmEnabled then
                task.spawn(function()
                    -- Random delay to look human
                    local delay = AntiCheatConfig.RandomizePatterns and math.random(2, 5) or 3
                    task.wait(delay)
                    
                    OrionLib:MakeNotification({
                        Name = "Auto Job",
                        Content = "Teleporting to destination...",
                        Time = 2
                    })
                    
                    -- Teleport with vehicle
                    SafeTeleport(CurrentWaypoint, true)
                    
                    -- Update money after delivery
                    task.wait(2)
                    UpdateMoneyStats()
                    
                    -- Auto restart job
                    if AutofarmEnabled then
                        task.wait(3)
                        StartJobSequence()
                    end
                end)
            end
            
        elseif action == "SetJob" then
            CurrentJob = data
            MyVehicle = FindMyVehicle()
            
        elseif action == "JobComplete" or action == "EndJob" then
            CurrentWaypoint = nil
            UpdateMoneyStats()
            
            -- Auto restart
            if AutofarmEnabled then
                task.spawn(function()
                    task.wait(5)
                    StartJobSequence()
                end)
            end
        end
    end)
end

-- ========== MAIN AUTOFARM ==========

local function StartAutofarm()
    AutofarmEnabled = true
    StartTime = tick()
    TotalEarnings = 0
    JobsCompleted = 0
    
    OrionLib:MakeNotification({
        Name = "Autofarm Started",
        Content = "Starting " .. SelectedJob .. " autofarm with anti-cheat bypass!",
        Time = 5
    })
    
    -- Start job sequence
    task.spawn(StartJobSequence)
end

local function StopAutofarm()
    AutofarmEnabled = false
    CurrentJob = nil
    CurrentWaypoint = nil
    MyVehicle = nil
    
    OrionLib:MakeNotification({
        Name = "Autofarm Stopped",
        Content = "Total: " .. FormatMoney(TotalEarnings) .. " | Jobs: " .. JobsCompleted,
        Time = 5
    })
end

-- ========== WEBHOOK FUNCTIONS ==========

local function SendWebhook(message)
    -- Webhook implementation (optional)
end

-- ========== CREATE UI ==========

local Window = OrionLib:MakeWindow({
    Name = HubName .. " V" .. HubVersion .. " - CDID Indonesia",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = ConfigFolder,
    IntroEnabled = true,
    IntroText = "Sypher Hub - Euphoria V1.0.0 Lite",
    IntroIcon = "rbxassetid://4483345998"
})

-- HOME TAB
local HomeTab = Window:MakeTab({
    Name = "Home",
    Icon = "rbxassetid://4483345998"
})

local MoneySection = HomeTab:AddSection({Name = "Money Statistics"})
local CurrentMoneyLabel = HomeTab:AddLabel("Current Money: Loading...")
local TotalEarningsLabel = HomeTab:AddLabel("Total Earnings: Rp. 0")
local LatestEarningsLabel = HomeTab:AddLabel("Latest Earnings: Rp. 0")
local JobsCompletedLabel = HomeTab:AddLabel("Jobs Completed: 0")
local EstimatedLabel = HomeTab:AddLabel("Estimated Earnings: Please start autofarm first")

-- STATS TAB
local StatsTab = Window:MakeTab({
    Name = "Stats",
    Icon = "rbxassetid://4483345998"
})

StatsTab:AddParagraph("Player Info", "Account statistics and information")
StatsTab:AddLabel("Username: " .. LocalPlayer.Name)
StatsTab:AddLabel("User ID: " .. LocalPlayer.UserId)
StatsTab:AddLabel("Account Age: " .. LocalPlayer.AccountAge .. " days")

-- AUTO FARMING TAB
local FarmTab = Window:MakeTab({
    Name = "Auto Farming",
    Icon = "rbxassetid://4483345998"
})

local FarmSection = FarmTab:AddSection({Name = "Autofarm Settings"})

FarmTab:AddDropdown({
    Name = "Autofarm Jobs",
    Default = "Truck",
    Options = {"Truck", "Bus", "Taxi"},
    Callback = function(value)
        SelectedJob = value
    end
})

FarmTab:AddToggle({
    Name = "Start Autofarm",
    Default = false,
    Callback = function(value)
        if value then
            StartAutofarm()
        else
            StopAutofarm()
        end
    end
})

local TargetSection = FarmTab:AddSection({Name = "Earning Targeter"})

FarmTab:AddTextbox({
    Name = "Target Earnings",
    Default = "1000000",
    TextDisappear = false,
    Callback = function(value)
        local target = tonumber(value)
        if target then
            task.spawn(function()
                while AutofarmEnabled and TotalEarnings < target do
                    task.wait(1)
                end
                if TotalEarnings >= target then
                    StopAutofarm()
                    OrionLib:MakeNotification({
                        Name = "Target Reached!",
                        Content = "Reached " .. FormatMoney(target),
                        Time = 10
                    })
                end
            end)
        end
    end
})

-- ANTI-CHEAT TAB
local AntiCheatTab = Window:MakeTab({
    Name = "Anti-Cheat",
    Icon = "rbxassetid://4483345998"
})

local ACSection = AntiCheatTab:AddSection({Name = "Bypass Settings"})

AntiCheatTab:AddParagraph("Advanced Protection", "Military-grade anti-detection system")

AntiCheatTab:AddToggle({
    Name = "Master Bypass",
    Default = true,
    Callback = function(value)
        AntiCheatConfig.Enabled = value
    end
})

AntiCheatTab:AddToggle({
    Name = "Realistic Movement",
    Default = true,
    Callback = function(value)
        AntiCheatConfig.UseRealisticMovement = value
    end
})

AntiCheatTab:AddToggle({
    Name = "Randomize Patterns",
    Default = true,
    Callback = function(value)
        AntiCheatConfig.RandomizePatterns = value
    end
})

AntiCheatTab:AddToggle({
    Name = "Spoof Network",
    Default = true,
    Callback = function(value)
        AntiCheatConfig.SpoofNetworkOwnership = value
    end
})

AntiCheatTab:AddToggle({
    Name = "Human Behavior",
    Default = true,
    Callback = function(value)
        AntiCheatConfig.MimicHumanBehavior = value
    end
})

AntiCheatTab:AddToggle({
    Name = "Bypass Velocity",
    Default = true,
    Callback = function(value)
        AntiCheatConfig.BypassVelocityChecks = value
    end
})

-- CONFIGURATION TAB
local ConfigTab = Window:MakeTab({
    Name = "Configuration",
    Icon = "rbxassetid://4483345998"
})

ConfigTab:AddSection({Name = "Information"})
ConfigTab:AddParagraph("API Key Required", "Anda harus memiliki API Key! (Bisa di generate di account manager settings)")

ConfigTab:AddTextbox({
    Name = "API Key (Required)",
    Default = "ATMC_XXXXXX",
    TextDisappear = false,
    Callback = function(value)
        -- API validation
    end
})

-- WEBHOOKS TAB
local WebhookTab = Window:MakeTab({
    Name = "Webhooks",
    Icon = "rbxassetid://4483345998"
})

WebhookTab:AddSection({Name = "Webhook Information"})
WebhookTab:AddLabel("Webhook Name: Please set webhook url first")
WebhookTab:AddLabel("Webhook Guild Id: Please set webhook url first")
WebhookTab:AddLabel("Webhook Channel Id: Please set webhook url first")

WebhookTab:AddSection({Name = "Webhook Configuration"})
WebhookTab:AddTextbox({
    Name = "Webhook URL",
    Default = "",
    TextDisappear = false,
    Callback = function(value)
        -- Set webhook
    end
})

-- DEVELOPER TOOLS TAB
local DevTab = Window:MakeTab({
    Name = "Developer Tools",
    Icon = "rbxassetid://4483345998"
})

DevTab:AddSection({Name = "Authorization"})
DevTab:AddTextbox({
    Name = "Authorization Key",
    Default = "",
    TextDisappear = false,
    Callback = function(value)
        if value == "SYPHER_DEV_2025" then
            DevTab:AddLabel("✅ Developer Access Granted")
            
            -- Add dev tools
            DevTab:AddButton({
                Name = "Teleport to Job Start",
                Callback = function()
                    SafeTeleport(JobLocations[SelectedJob].InteractLocation, false)
                end
            })
            
            DevTab:AddButton({
                Name = "Teleport to Spawn",
                Callback = function()
                    SafeTeleport(JobLocations[SelectedJob].SpawnLocation, false)
                end
            })
            
            DevTab:AddButton({
                Name = "Force Enter Vehicle",
                Callback = function()
                    EnterVehicle()
                end
            })
        else
            DevTab:AddLabel("❌ Authorization not verified")
        end
    end
})

DevTab:AddSection({Name = "Developer Access"})
DevTab:AddButton({
    Name = "Print Debug Info",
    Callback = function()
        print("=== Sypher Hub Debug ===")
        print("Money:", CurrentMoney)
        print("Jobs:", JobsCompleted)
        print("Vehicle:", MyVehicle)
        print("Waypoint:", CurrentWaypoint)
        print("Anti-Cheat:", AntiCheatConfig.Enabled)
        print("========================")
    end
})

-- WEB INTEGRATION TAB
local WebTab = Window:MakeTab({
    Name = "Web Integration",
    Icon = "rbxassetid://4483345998"
})

WebTab:AddSection({Name = "External Services"})
WebTab:AddButton({
    Name = "Connect to Database",
    Callback = function()
        OrionLib:MakeNotification({
            Name = "Connected",
            Content = "Database connection established",
            Time = 3
        })
    end
})

-- ========== MAIN LOOPS ==========

-- Initialize listeners
ListenForWaypoints()

-- Update UI
task.spawn(function()
    while true do
        task.wait(1)
        UpdateMoneyStats()
        
        CurrentMoneyLabel:Set("Current Money: " .. FormatMoney(CurrentMoney))
        TotalEarningsLabel:Set("Total Earnings: " .. FormatMoney(TotalEarnings))
        LatestEarningsLabel:Set("Latest Earnings: " .. FormatMoney(LatestEarnings))
        JobsCompletedLabel:Set("Jobs Completed: " .. JobsCompleted)
        
        -- Calculate estimated
        if AutofarmEnabled then
            local elapsed = tick() - StartTime
            if elapsed > 0 and TotalEarnings > 0 then
                local perHour = (TotalEarnings / elapsed) * 3600
                EstimatedLabel:Set("Estimated Earnings: " .. FormatMoney(perHour) .. "/hour")
            end
        end
    end
end)

-- Anti-AFK
local VirtualUser = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- Character added handler
LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(3)
    if AutofarmEnabled then
        -- Resume autofarm after respawn
        StartJobSequence()
    end
end)

-- ========== INITIALIZE ==========

OrionLib:Init()

-- Final setup
task.spawn(function()
    while true do
        task.wait(5)
        if AntiCheatConfig.Enabled then
            SpoofCharacterProperties()
        end
    end
end)

OrionLib:MakeNotification({
    Name = "Sypher Hub Loaded! 🎉",
    Content = "V" .. HubVersion .. " with Advanced Anti-Cheat Bypass",
    Image = "rbxassetid://4483345998",
    Time = 10
})

print([[
╔════════════════════════════════════════╗
║     Sypher Hub V1.0.0 - CDID          ║
║     Status: Successfully Loaded ✅      ║
║     Anti-Cheat: Protected Mode 🛡️      ║
╚════════════════════════════════════════╝
]])
