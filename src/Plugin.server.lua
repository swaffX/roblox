-- MINIMAL TEST VERSION
-- Testing if basic plugin loads without crashing

print("🔍 [Neurovia Coder] Step 1: Plugin script started")

-- Create minimal toolbar
local toolbar = plugin:CreateToolbar("Neurovia Coder")
print("🔍 [Neurovia Coder] Step 2: Toolbar created")

local button = toolbar:CreateButton(
	"Neurovia Coder",
	"AI-powered coding assistant",
	"rbxassetid://0"
)
print("🔍 [Neurovia Coder] Step 3: Button created")

button.Click:Connect(function()
	print("✅ Button clicked! Plugin is working.")
end)

print("✅ [Neurovia Coder] MINIMAL PLUGIN LOADED SUCCESSFULLY!")
print("📝 If you see this, the crash is caused by module loading, not basic plugin structure.")
