local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local cfg = {
enabled = true,
metrics = true,
fps = 60,
gfx = 10,
mem = 850,
jitter = false,
j_fps = 5,
j_mem = 50,
j_gfx = 0,
spoof_ping = false,
ping = 1
}

local executor_name = (identifyexecutor and identifyexecutor()) or "Unknown"

local meow = ReplicatedStorage:WaitForChild("meow", 15)
local nya = ReplicatedStorage:WaitForChild("nya", 15)

local meow_conns
repeat
task.wait(0.1)
meow_conns = getconnections(meow.OnClientEvent)
until #meow_conns > 0

local orig_handler = meow_conns[1].Function

local pr_conns = getconnections(RunService.PreRender)
if #pr_conns > 0 then
pcall(function() pr_conns[1]:Disable() end)
pcall(function() hookfunction(pr_conns[1].Function, function() end) end)
end

local last_metric_time = os.clock()
local old_fn
old_fn = hookfunction(orig_handler, function(packet)
if type(packet) == "table" and cfg.enabled then
if packet.t == "metrics" and cfg.metrics then
local now = os.clock()
local dt = now - last_metric_time
last_metric_time = now

local target_fps = tonumber(cfg.fps) or 60
if cfg.jitter then
target_fps = target_fps + math.random(-cfg.j_fps, cfg.j_fps)
end
target_fps = math.clamp(target_fps, 1, 1000000)

if dt > 0 and dt < 10 then
debug.setupvalue(old_fn, 15, math.floor(target_fps * dt + 0.5))
else
debug.setupvalue(old_fn, 15, target_fps)
end
debug.setupvalue(old_fn, 17, target_fps)
end
end
return old_fn(packet)
end)

debug.setupvalue(old_fn, 18, function(...)
if cfg.enabled and cfg.metrics then
local target_mem = tonumber(cfg.mem) or 850
if cfg.jitter then
target_mem = target_mem + math.random(-cfg.j_mem, cfg.j_mem)
end
return math.clamp(target_mem, 1, 65536)
end
return Stats:GetTotalMemoryUsageMb()
end)

debug.setupvalue(old_fn, 20, function(...)
if cfg.enabled and cfg.metrics then
local target_gfx = tonumber(cfg.gfx) or 10
if cfg.jitter then
target_gfx = target_gfx + math.random(-cfg.j_gfx, cfg.j_gfx)
end
return math.clamp(math.floor(target_gfx), 1, 10)
end
local s = UserSettings():GetService("UserGameSettings").SavedQualityLevel
if s == Enum.SavedQualitySetting.Automatic then return 11 end
return math.clamp(tonumber(tostring(s.Name):match("%d+")) or 11, 1, 11)
end)

debug.setupvalue(old_fn, 21, function()
return 0
end)

task.spawn(function()
while true do
task.wait(0.2)
if cfg.enabled and cfg.spoof_ping then
local lp = Players.LocalPlayer
local char = lp and lp.Character
local head = char and char:FindFirstChild("Head")
local fpsGui = head and head:FindFirstChild("fpsGui")
local pingLabel = fpsGui and fpsGui:FindFirstChild("Ping")
if pingLabel then
pingLabel.Text = "Ping: " .. string.format("%.2f", tonumber(cfg.ping) or 1)
end
end
end
end)

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
Name = "FPS Spoofer | By noxi",
LoadingTitle = "Spoofing",
LoadingSubtitle = "By noxi",
ConfigurationSaving = { Enabled = false },
KeySystem = false
})

local TabMain = Window:CreateTab("Main", "home")
local TabMetrics = Window:CreateTab("Metrics", "bar-chart-2")
local TabPing = Window:CreateTab("Ping", "activity")
local TabJitter = Window:CreateTab("Jitter", "shuffle")
local TabCredits = Window:CreateTab("Credits", "user")

TabMain:CreateLabel("Executor: " .. executor_name)
TabMain:CreateSection("Status")
TabMain:CreateToggle({Name = "Enable Spoofer", CurrentValue = cfg.enabled, Callback = function(v) cfg.enabled = v end})
TabMain:CreateToggle({Name = "Spoof Metrics", CurrentValue = cfg.metrics, Callback = function(v) cfg.metrics = v end})

TabMetrics:CreateSection("Metrics Settings")
TabMetrics:CreateInput({Name = "FPS", PlaceholderText = tostring(cfg.fps), RemoveTextAfterFocusLost = false, Callback = function(v) cfg.fps = tonumber(v) or cfg.fps end})
TabMetrics:CreateInput({Name = "RAM (MB)", PlaceholderText = tostring(cfg.mem), RemoveTextAfterFocusLost = false, Callback = function(v) cfg.mem = tonumber(v) or cfg.mem end})
TabMetrics:CreateSlider({Name = "Graphics Level", Range = {1, 10}, Increment = 1, Suffix = " Level", CurrentValue = cfg.gfx, Callback = function(v) cfg.gfx = v end})

TabPing:CreateSection("Visual Ping")
TabPing:CreateToggle({Name = "Enable Ping Spoof", CurrentValue = cfg.spoof_ping, Callback = function(v) cfg.spoof_ping = v end})
TabPing:CreateInput({Name = "Ping Value (ms)", PlaceholderText = tostring(cfg.ping), RemoveTextAfterFocusLost = false, Callback = function(v) cfg.ping = tonumber(v) or cfg.ping end})

TabJitter:CreateSection("Jitter Settings")
TabJitter:CreateToggle({Name = "Enable Jitter", CurrentValue = cfg.jitter, Callback = function(v) cfg.jitter = v end})
TabJitter:CreateInput({Name = "FPS Spread", PlaceholderText = tostring(cfg.j_fps), RemoveTextAfterFocusLost = false, Callback = function(v) cfg.j_fps = math.abs(tonumber(v) or 0) end})
TabJitter:CreateInput({Name = "RAM Spread (MB)", PlaceholderText = tostring(cfg.j_mem), RemoveTextAfterFocusLost = false, Callback = function(v) cfg.j_mem = math.abs(tonumber(v) or 0) end})
TabJitter:CreateInput({Name = "Graphics Spread", PlaceholderText = tostring(cfg.j_gfx), RemoveTextAfterFocusLost = false, Callback = function(v) cfg.j_gfx = math.abs(tonumber(v) or 0) end})

TabCredits:CreateSection("Credits")
TabCredits:CreateLabel("Created by noxi")
TabCredits:CreateButton({
Name = "Rejoin Server",
Callback = function()
if #Players:GetPlayers() <= 1 then
Players.LocalPlayer:Kick("\nRejoining...")
task.wait()
TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
else
TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Players.LocalPlayer)
end
end
})
