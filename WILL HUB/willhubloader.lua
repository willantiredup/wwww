--[[
    WillHub Loader
    Ganti GITHUB_USER & REPO sesuai punya kamu.
    File utama yang di-fetch : willhub/willhub.lua
]]

local GITHUB_USER = "willantiredup"
local REPO        = "willhub"
local BRANCH      = "main"
local FILE        = "willhub.lua"

local URL = ("https://raw.githubusercontent.com/%s/%s/%s/%s")
    :format(GITHUB_USER, REPO, BRANCH, FILE)

local ok, err = pcall(function()
    local src = game:HttpGet(URL, true)
    if not src or #src < 100 then
        error("Fetch gagal / file kosong: " .. URL)
    end
    loadstring(src)()
end)

if not ok then
    warn("[WillHub Loader] " .. tostring(err))
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "WillHub Loader",
            Text  = "Gagal load: " .. tostring(err),
            Duration = 5,
        })
    end)
end
