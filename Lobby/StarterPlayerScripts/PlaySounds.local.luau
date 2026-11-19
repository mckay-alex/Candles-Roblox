local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = game.Players.LocalPlayer

Player.CharacterAdded:Wait()

ReplicatedStorage:WaitForChild("Sounds").Lobby:Play()
