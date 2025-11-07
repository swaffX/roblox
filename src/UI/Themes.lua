--[[
	Themes - Modern Dark Theme ve UI Helper'lar
]]

local Config = require(script.Parent.Parent.Config)

local Themes = {}

-- Create rounded frame helper
function Themes.createFrame(parent, props)
	local frame = Instance.new("Frame")
	frame.Parent = parent
	frame.BackgroundColor3 = props.backgroundColor or Config.COLORS.SURFACE_DEFAULT
	frame.BorderSizePixel = 0
	frame.Size = props.size or UDim2.new(1, 0, 1, 0)
	frame.Position = props.position or UDim2.new(0, 0, 0, 0)
	
	-- Rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Config.UI.BORDER_RADIUS)
	corner.Parent = frame
	
	return frame
end

-- Create text label helper
function Themes.createLabel(parent, text, props)
	props = props or {}
	local label = Instance.new("TextLabel")
	label.Parent = parent
	label.Text = text
	label.TextColor3 = props.textColor or Config.COLORS.TEXT_PRIMARY
	label.Font = Enum.Font.Gotham
	label.TextSize = props.textSize or 14
	label.BackgroundTransparency = 1
	label.Size = props.size or UDim2.new(1, 0, 0, 30)
	label.TextXAlignment = props.xAlignment or Enum.TextXAlignment.Left
	
	return label
end

-- Create button helper
function Themes.createButton(parent, text, callback)
	local button = Instance.new("TextButton")
	button.Parent = parent
	button.Text = text
	button.TextColor3 = Config.COLORS.TEXT_PRIMARY
	button.Font = Enum.Font.GothamBold
	button.TextSize = 14
	button.BackgroundColor3 = Config.COLORS.ACCENT_PRIMARY
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Config.UI.BORDER_RADIUS)
	corner.Parent = button
	
	if callback then
		button.MouseButton1Click:Connect(callback)
	end
	
	-- Hover effect
	button.MouseEnter:Connect(function()
		button.BackgroundColor3 = Config.COLORS.ACCENT_SECONDARY
	end)
	
	button.MouseLeave:Connect(function()
		button.BackgroundColor3 = Config.COLORS.ACCENT_PRIMARY
	end)
	
	return button
end

-- Create text input helper
function Themes.createTextBox(parent, placeholder, props)
	props = props or {}
	local textbox = Instance.new("TextBox")
	textbox.Parent = parent
	textbox.PlaceholderText = placeholder
	textbox.Text = ""
	textbox.TextColor3 = Config.COLORS.TEXT_PRIMARY
	textbox.PlaceholderColor3 = Config.COLORS.TEXT_TERTIARY
	textbox.Font = Enum.Font.Gotham
	textbox.TextSize = 14
	textbox.BackgroundColor3 = Config.COLORS.SURFACE_DEFAULT
	textbox.BorderSizePixel = 0
	textbox.ClearTextOnFocus = false
	textbox.TextXAlignment = Enum.TextXAlignment.Left
	textbox.TextWrapped = props.multiline or false
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Config.UI.BORDER_RADIUS)
	corner.Parent = textbox
	
	return textbox
end

-- Create scrolling frame helper
function Themes.createScrollingFrame(parent)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Parent = parent
	scroll.BackgroundColor3 = Config.COLORS.BACKGROUND_SECONDARY
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = Config.UI.SCROLL_BAR_WIDTH
	scroll.ScrollBarImageColor3 = Config.COLORS.SURFACE_HOVER
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	
	local layout = Instance.new("UIListLayout")
	layout.Parent = scroll
	layout.Padding = UDim.new(0, Config.UI.SPACING)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	
	return scroll
end

return Themes
