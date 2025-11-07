-- Simple test plugin to verify structure
print("AI Coder Plugin: Loading...")

local toolbar = plugin:CreateToolbar("AI Coder")
local button = toolbar:CreateButton(
	"AI Coder",
	"AI-powered coding assistant",
	"rbxassetid://0"
)

button.Click:Connect(function()
	print("AI Coder button clicked!")
	warn("AI Coder Plugin is working!")
end)

print("AI Coder Plugin: Loaded successfully!")


