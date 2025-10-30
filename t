local plr = game.Players.LocalPlayer
local chr = plr.Character

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local accessory = Instance.new("Accessory")
accessory.AttachmentPoint = CFrame.new(0, 0.562, -1.179)
accessory.Name = "Tail"
accessory.AccessoryType = Enum.AccessoryType.Waist
accessory.Parent = chr

local handle = Instance.new("Part")
handle.Size = Vector3.new(1, 1, 1)
handle.CanCollide = false
handle.Name = "Handle"
handle.Parent = accessory

local weld = Instance.new("Weld")
weld.Parent = handle
weld.Part0 = handle
weld.Part1 = chr:WaitForChild("LowerTorso")
weld.C0 = CFrame.new(0, 0.562, -1.179)
weld.C1 = CFrame.new(-0, -0.2, 0.5)
weld.Name = "AccessoryWeld"

local attachment = Instance.new("Attachment")
attachment.CFrame = CFrame.new(0, 0.562, -1.179)
attachment.Parent = handle

local mesh = Instance.new("SpecialMesh")
mesh.MeshId = "rbxassetid://98742472780035"
mesh.TextureId = "rbxassetid://94104831701474"
mesh.Parent = handle
