-- Test Plugin - Minimal
print("=== TEST PLUGIN LOADING ===")

local toolbar = plugin:CreateToolbar("Test Plugin")
local button = toolbar:CreateButton(
	"Test",
	"Test button",
	""
)

button.Click:Connect(function()
	print("Test button clicked!")
	warn("Plugin is working!")
end)

print("=== TEST PLUGIN LOADED ===")
