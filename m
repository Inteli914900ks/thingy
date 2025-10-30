local tail = true
local wag = true

local hum = game.Players.LocalPlayer.Character:WaitForChild("Humanoid")

if hum.RigType ~= Enum.HumanoidRigType.R15 then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Incompatible!";
        Text = "Incompatible with R6!";
        Duration = 5
    })
    return
end

local lowertorso = hum.Parent:WaitForChild("LowerTorso")

if tail == true then 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Inteli914900ks/thingy/refs/heads/main/t"))()
end

if wag == true then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Inteli914900ks/thingy/refs/heads/main/w"))()
end
