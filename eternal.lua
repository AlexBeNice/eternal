-- Booting the Library
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()

-- Creating a Window
local Window = OrionLib:MakeWindow({
    Name = "Admin Menu",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "OrionTest"
})

local players = game:GetService("Players")
local runService = game:GetService('RunService')
local localPlayer = players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local workspace = game:GetService("Workspace")
local camera = workspace.CurrentCamera

-- Variables for spectating functionality
local loopViewActive = false
local selectedPlayerToView

-- Function to handle spectating
local function spectatePlayer()
    if selectedPlayerToView then
        local targetPlayer = players:FindFirstChild(selectedPlayerToView)
        if targetPlayer and targetPlayer.Character then
            workspace.CurrentCamera.CameraSubject = targetPlayer.Character.Humanoid
            loopViewActive = true
        end
    end
end

-- Function to stop spectating
local function stopSpectating()
    if localPlayer and localPlayer.Character then
        workspace.CurrentCamera.CameraSubject = localPlayer.Character.Humanoid
        loopViewActive = false
    end
end

-- Update function that's connected to RunService.Stepped
runService.Stepped:Connect(function()
    if loopViewActive then
        spectatePlayer()  -- Keeps spectating the selected player
    end
end)

-- View Tab
local ViewTab = Window:MakeTab({
    Name = "View",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- Dropdown for selecting players to view
local playerViewDropdown = ViewTab:AddDropdown({
    Name = "Player List",
    Default = "Select a player",
    Options = {},
    Callback = function(value)
        selectedPlayerToView = value
    end    
})

-- Function to update dropdown options as players join or leave
local function updatePlayerViewDropdown()
    local playerNames = {}
    for _, player in pairs(players:GetPlayers()) do
        if player ~= localPlayer then -- Exclude the local player
            table.insert(playerNames, player.Name)
        end
    end
    playerViewDropdown:Refresh(playerNames, true)
end

-- Initial update of player view dropdown
updatePlayerViewDropdown()

-- Subscribe to player addition and removal events
players.PlayerAdded:Connect(updatePlayerViewDropdown)
players.PlayerRemoving:Connect(updatePlayerViewDropdown)

-- Toggle for enabling/disabling view spectate
ViewTab:AddToggle({
    Name = "Toggle View",
    Default = false,
    Callback = function(value)
        if value then
            spectatePlayer() -- Start spectating the selected player
        else
            stopSpectating() -- Stop spectating
        end
    end    
})

-- Flying functionality variables
local flying = false
local flySpeed = 1
local CONTROL = {F = 0, B = 0, L = 0, R = 0}
local lCONTROL = {F = 0, B = 0, L = 0, R = 0}
local SPEED = 0

local function fly()
    local BG = Instance.new('BodyGyro', localPlayer.Character.HumanoidRootPart)
    local BV = Instance.new('BodyVelocity', localPlayer.Character.HumanoidRootPart)
    BG.P = 9e4
    BG.maxTorque = Vector3.new(9e9, 9e9, 9e9)
    BG.cframe = localPlayer.Character.HumanoidRootPart.CFrame
    BV.velocity = Vector3.new(0, 0.1, 0)
    BV.maxForce = Vector3.new(9e9, 9e9, 9e9)
    localPlayer.Character.Humanoid.PlatformStand = true
    repeat
        wait()
        if CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 then
            SPEED = 50 * flySpeed  -- Adjusting speed based on slider
        else
            SPEED = 0
        end
        if SPEED ~= 0 then
            BV.velocity = ((camera.CoordinateFrame.lookVector * (CONTROL.F + CONTROL.B)) + ((camera.CoordinateFrame * CFrame.new(CONTROL.L + CONTROL.R, (CONTROL.F + CONTROL.B) * 0.2, 0).p) - camera.CoordinateFrame.p)) * SPEED
        else
            BV.velocity = Vector3.new(0, 0.1, 0)
        end
        BG.cframe = camera.CoordinateFrame
    until not flying
    localPlayer.Character.Humanoid.PlatformStand = false
    BG:Destroy()
    BV:Destroy()
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    local key = input.KeyCode
    if key == Enum.KeyCode.W then CONTROL.F = 1
    elseif key == Enum.KeyCode.S then CONTROL.B = -1
    elseif key == Enum.KeyCode.A then CONTROL.L = -1
    elseif key == Enum.KeyCode.D then CONTROL.R = 1
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    local key = input.KeyCode
    if key == Enum.KeyCode.W then CONTROL.F = 0
    elseif key == Enum.KeyCode.S then CONTROL.B = 0
    elseif key == Enum.KeyCode.A then CONTROL.L = 0
    elseif key == Enum.KeyCode.D then CONTROL.R = 0
    end
end)

-- Home Base Tab
local HomeBaseTab = Window:MakeTab({
    Name = "Home Base",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local homeBasePosition = Vector3.new(52.603, -413.456, 55.759) -- Home base coordinates
local homeBasePlate = nil

HomeBaseTab:AddButton({
    Name = "Set Home Base",
    Callback = function()
        if not homeBasePlate then
            homeBasePlate = Instance.new("Part", workspace)
            homeBasePlate.Size = Vector3.new(100, 1, 100)
            homeBasePlate.Position = homeBasePosition + Vector3.new(0, -0.5, 0) -- Adjusting y to sit on terrain
            homeBasePlate.Anchored = true
            homeBasePlate.Name = "HomeBasePlate"
        end
        OrionLib:MakeNotification({
            Name = "Home Base Set",
            Content = "Your home base has been set at the specified coordinates.",
            Duration = 5
        })
    end
})

HomeBaseTab:AddButton({
    Name = "Teleport to Home Base",
    Callback = function()
        if localPlayer.Character then
            localPlayer.Character:SetPrimaryPartCFrame(CFrame.new(homeBasePosition))
        end
    end
})

-- Teleport Tab
local TeleportTab = Window:MakeTab({
    Name = "Teleportation",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local clickTpActive = false
local teleportHotkey -- No default key, it will be set by the user
local connection -- This will hold the connection to the hotkey event

-- Function to initiate the hotkey setting process
local function waitForHotkey()
    OrionLib:MakeNotification({
        Name = "Hotkey Setup",
        Content = "Press any key to set it as your teleport hotkey.",
        Time = 5
    })

    if connection then
        connection:Disconnect() -- Disconnect any previous hotkey listener
    end

    -- Wait for the user to press a key, then set it as the hotkey
    connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode ~= Enum.KeyCode.Unknown then
            teleportHotkey = input.KeyCode
            connection:Disconnect() -- Stop listening for key presses after setting the hotkey
            connection = nil

            OrionLib:MakeNotification({
                Name = "Hotkey Set",
                Content = "Teleport hotkey set to: " .. teleportHotkey.Name,
                Time = 5
            })
        end
    end)
end

-- Function that handles teleportation
local function teleportToCursor()
    local mouseLocation = UserInputService:GetMouseLocation()
    local ray = camera:ScreenPointToRay(mouseLocation.X, mouseLocation.Y)
    local raycastParams = RaycastParams.new()
    raycastParams.IgnoreWater = true
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {localPlayer.Character}
    local raycastResult = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)

    if raycastResult then
        local teleportDestination = CFrame.new(raycastResult.Position + Vector3.new(0, 3, 0))
        localPlayer.Character:SetPrimaryPartCFrame(teleportDestination)
    end
end

-- Adding Button for Hotkey setup in the Teleportation tab
TeleportTab:AddButton({
    Name = "Set Teleport Hotkey",
    Callback = waitForHotkey
})

-- Toggle for enabling/disabling Click TP
TeleportTab:AddToggle({
    Name = "Toggle Click TP",
    Default = false,
    Callback = function(value)
        clickTpActive = value
        if value and not teleportHotkey then
            waitForHotkey() -- Prompt for hotkey setup if not yet defined
        end
    end    
})

-- Listener for the teleportation hotkey press
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if teleportHotkey and input.KeyCode == teleportHotkey and clickTpActive then
        teleportToCursor()
    end
end)


-- Dropdown for selecting players
local playerDropdown = TeleportTab:AddDropdown({
    Name = "Player List",
    Default = "Select a player",
    Options = {}, -- Start with an empty list
    Callback = function(value)
        local selectedPlayer = players:FindFirstChild(value)
        if selectedPlayer and selectedPlayer.Character then
            localPlayer.Character:SetPrimaryPartCFrame(selectedPlayer.Character.PrimaryPart.CFrame)
        end
    end    
})

-- Update dropdown options as players join or leave
local function updatePlayerDropdown()
    local playerNames = {}
    for _, player in pairs(players:GetPlayers()) do
        if player ~= localPlayer then -- Ensure not to include the local player
            table.insert(playerNames, player.Name)
        end
    end
    playerDropdown:Refresh(playerNames, true) -- Refresh the dropdown with new player list, reset to first player
end

-- Initial update of player dropdown
updatePlayerDropdown()

-- Subscribe to player addition and removal events
players.PlayerAdded:Connect(updatePlayerDropdown)
players.PlayerRemoving:Connect(updatePlayerDropdown)

-- Player Modifications Tab
local PlayerModsTab = Window:MakeTab({
    Name = "Player Mods",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- Fly Toggle
PlayerModsTab:AddToggle({
    Name = "Toggle Fly",
    Default = false,
    Callback = function(enabled)
        flying = enabled
        if flying then
            fly()
        else
            flying = false
            localPlayer.Character.Humanoid.PlatformStand = false
        end
    end
})

-- Fly Speed Slider
PlayerModsTab:AddSlider({
    Name = "Fly Speed",
    Min = 1,
    Max = 100,
    Default = 1,
    Callback = function(value)
        flySpeed = value
    end
})

-- Walk Speed Slider
PlayerModsTab:AddSlider({
    Name = "Walk Speed",
    Min = 1,
    Max = 100,
    Default = 20,
    Callback = function(value)
        local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = value
        end
    end
})


-- Destroy UI Tab
local DestroyUITab = Window:MakeTab({
    Name = "Destroy UI",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

DestroyUITab:AddButton({
    Name = "Destroy UI",
    Callback = function()
        OrionLib:Destroy()
    end
})

-- Finalize your script
OrionLib:Init()