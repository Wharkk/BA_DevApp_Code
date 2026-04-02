local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local ProfileManager = require(ServerStorage.DatastoreUtils.ProfileManager)

local lastDuckStates: { [Player]: { [string]: { cframe: CFrame, time: number } } } = {}

local MAX_SPEED = 100
local MAX_TELEPORT = 200

Players.PlayerRemoving:Connect(function(player: Player)
	lastDuckStates[player] = nil
end)

ReplicatedStorage.GetPlayerDucks.OnServerInvoke = function(player: Player): {}
	return ProfileManager:GetEquippedDucks(player)
end

ReplicatedStorage.UpdateDuckCFrame.OnServerEvent:Connect(function(player, duckInfo)
	duckInfo.Player = player
	local now = tick()
	
	lastDuckStates[player] = lastDuckStates[player] or {}
	local last = lastDuckStates[player][duckInfo.Name]

	if last then
		local dist = (duckInfo.CurrentCFrame.Position - last.cframe.Position).Magnitude
		local dt = math.max(now - last.time, 0.01)
		local speed = dist / dt
		
		if speed > MAX_SPEED or dist > MAX_TELEPORT then
			warn(("[Duck AntiCheat] %s's %s moved too fast (%.1f studs/s)"):format(player.Name, duckInfo.Name, speed))
			return
		end
	end
	
	lastDuckStates[player][duckInfo.Name] = { cframe = duckInfo.CurrentCFrame, time = now }
	
	local duck = player.Character and player.Character:FindFirstChild(duckInfo.Name)
	if duck then
		duck:PivotTo(duckInfo.CurrentCFrame)
	end
	
	ReplicatedStorage.UpdateDuckCFrame:FireAllClients(duckInfo)
end)
