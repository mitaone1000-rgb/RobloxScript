-- HealthHandler.lua (Script)
-- Path: ServerScriptService/Script/HealthHandler.lua

game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		-- Cari script bawaan Health dan hapus
		local healthScript = char:FindFirstChild("Health")
		if healthScript then
			healthScript:Destroy()
		end
	end)
end)