--[[
    WillHub - Growblox Auto Farm
    Game : https://www.roblox.com/games/112863874972771/Growblox
    Repo : willhub/
    Load : loader.lua via loadstring(game:HttpGet(...))
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui        = game:GetService("StarterGui")
local player            = Players.LocalPlayer

local CONFIG = {
    AUTO_PLANT   = true,
    AUTO_HARVEST = true,
    AUTO_WATER   = true,
    AUTO_SELL    = true,
    SEED_NAME    = "Hay",
    WALK_SPEED   = 60,
    SELL_DELAY   = 8,
    FARM_DELAY   = 1.5,
    OUTBOX       = false,
}

local Remotes = {
    ManipulateCrop = ReplicatedStorage:WaitForChild("ManipulateCrop"),
    UseMarket      = ReplicatedStorage:WaitForChild("UseMarket"),
    CropSold       = ReplicatedStorage:WaitForChild("CropSold"),
    UseItem        = ReplicatedStorage:WaitForChild("UseItem"),
}
local PlayerData = require(ReplicatedStorage:WaitForChild("PlayerData"))

local farm      = nil
local plots     = {}
local isSelling = false
local running   = true

local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title, Text = text, Duration = 5,
        })
    end)
end

local function findFarm()
    for i = 1, 8 do
        local f = workspace:FindFirstChild("Farm" .. i)
        if f and f:FindFirstChild("Owner") and f.Owner.Value == player then
            farm = f
            break
        end
    end
    if not farm then
        warn("[WillHub] Farm tidak ditemukan!")
        return
    end
    plots = {}
    for i = 1, 6 do
        local plot = farm:FindFirstChild("Plot" .. i)
        if plot then table.insert(plots, plot) end
    end
    print(("[WillHub] Farm: %s | Plot: %d"):format(farm.Name, #plots))
end

local function setSpeed()
    local char = player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = CONFIG.WALK_SPEED end
    end
end

local function sellCrops()
    if not CONFIG.AUTO_SELL or isSelling then return end
    local data = PlayerData.get()
    if not data or data.weight <= 0 then return end

    isSelling = true
    if not CONFIG.OUTBOX and player.Character then
        player.Character:MoveTo(Vector3.new(52, 5, -453))
        task.wait(2)
    end

    for cropType in pairs(data.crops) do
        local qty = data.crops[cropType] or 0
        if qty > 0 then
            pcall(function()
                Remotes.UseMarket:FireServer("SellCrop", cropType, qty, CONFIG.OUTBOX)
                Remotes.CropSold:Fire(cropType, qty, CONFIG.OUTBOX)
            end)
        end
    end
    isSelling = false
    print("[WillHub] Sell done.")
end

local function waterCrop(crop)
    if not CONFIG.AUTO_WATER then return end
    if not crop:FindFirstChild("WaterContent") then return end
    if crop.WaterContent.Value <= 2 then
        Remotes.ManipulateCrop:FireServer(crop, "Water")
        if farm then
            local well = farm:FindFirstChild("Well")
            if well then Remotes.UseItem:FireServer(well) end
        end
    end
end

local function processPlot(plot)
    for _, crop in pairs(plot:GetChildren()) do
        if crop.Name ~= "Camera1" and crop.Name ~= "Camera2"
            and crop.Name ~= "Plot" and crop.Name ~= "HasGreenhouse"
            and crop:FindFirstChild("CropType")
        then
            local cropType = crop.CropType.Value

            if CONFIG.AUTO_HARVEST and cropType ~= "none" then
                local stage    = crop.CropStage and crop.CropStage.Value or 0
                local reqStage = PlayerData.get().crops[cropType] or 99
                if stage >= reqStage then
                    pcall(function()
                        Remotes.ManipulateCrop:FireServer(crop, "Harvest")
                    end)
                    task.wait(0.1)
                end
            end

            if CONFIG.AUTO_PLANT and cropType == "none" then
                local data = PlayerData.get()
                if data.seeds[CONFIG.SEED_NAME] and data.seeds[CONFIG.SEED_NAME] > 0 then
                    pcall(function()
                        Remotes.ManipulateCrop:FireServer(crop, "PlantSeed", CONFIG.SEED_NAME)
                    end)
                    task.wait(0.1)
                end
            end

            waterCrop(crop)
        end
    end
end

task.spawn(function()
    findFarm()
    task.wait(1)
    while running do
        pcall(function()
            setSpeed()
            if #plots == 0 then findFarm() end
            for _, plot in pairs(plots) do
                if not running then break end
                processPlot(plot)
                task.wait(0.05)
            end
            sellCrops()
        end)
        task.wait(CONFIG.FARM_DELAY)
    end
end)

notify("WillHub - Growblox", "Auto Farm aktif! 🥀")