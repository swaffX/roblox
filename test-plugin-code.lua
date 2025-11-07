--[[
    ROBLOX STUDIO'DA YAPILACAKLAR:
    
    1. Roblox Studio'yu aç
    2. View › Output (çýktý penceresini aç)
    3. View › Command Bar (komut çubuðunu aç)
    4. Aþaðýdaki kodu Command Bar'a yapýþtýr ve Enter'a bas:
]]

-- Basit Test Plugin
local success, result = pcall(function()
    local toolbar = plugin:CreateToolbar("AI Coder Test")
    local button = toolbar:CreateButton(
        "Test",
        "Test plugin button",
        "rbxasset://textures/ui/TopBar/inventoryOn.png"
    )
    
    button.Click:Connect(function()
        print("? Plugin butonu çalýþýyor!")
    end)
    
    print("? Test plugin baþarýyla yüklendi!")
end)

if not success then
    warn("? Plugin hatasý:", result)
    warn("Bu kod ServerScriptService'e Script olarak eklenmeli!")
end
