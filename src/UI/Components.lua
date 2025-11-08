--[[
	Components - Modern UI Bileşenleri Kütüphanesi
	
	Yeniden kullanılabilir, modern görünümlü UI bileşenleri
]]

local Config = require(script.Parent.Parent.Config)

local Components = {}

-- Helper: Corner radius ekle
local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or Config.UI.BORDER_RADIUS)
	corner.Parent = parent
	return corner
end

-- Helper: Padding ekle
local function addPadding(parent, all)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, all or Config.UI.PADDING)
	padding.PaddingBottom = UDim.new(0, all or Config.UI.PADDING)
	padding.PaddingLeft = UDim.new(0, all or Config.UI.PADDING)
	padding.PaddingRight = UDim.new(0, all or Config.UI.PADDING)
	padding.Parent = parent
	return padding
end

-- Modern Button
function Components.Button(props)
	local button = Instance.new("TextButton")
	button.Name = props.Name or "Button"
	button.Text = props.Text or "Button"
	button.Font = Enum.Font.GothamBold
	button.TextSize = props.TextSize or 14
	button.TextColor3 = props.TextColor or Config.COLORS.TEXT_PRIMARY
	button.BackgroundColor3 = props.BackgroundColor or Config.COLORS.ACCENT_PRIMARY
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Size = props.Size or UDim2.new(0, 120, 0, 36)
	button.Position = props.Position or UDim2.new(0, 0, 0, 0)
	button.Parent = props.Parent
	
	addCorner(button, 6)
	
	-- Hover effect
	button.MouseEnter:Connect(function()
		button.BackgroundColor3 = props.HoverColor or Config.COLORS.ACCENT_SECONDARY
	end)
	
	button.MouseLeave:Connect(function()
		button.BackgroundColor3 = props.BackgroundColor or Config.COLORS.ACCENT_PRIMARY
	end)
	
	-- Click callback
	if props.OnClick then
		button.MouseButton1Click:Connect(props.OnClick)
	end
	
	return button
end

-- Secondary Button (outlined style)
function Components.SecondaryButton(props)
	props.BackgroundColor = props.BackgroundColor or Config.COLORS.SURFACE_DEFAULT
	props.HoverColor = props.HoverColor or Config.COLORS.SURFACE_HOVER
	props.TextColor = props.TextColor or Config.COLORS.TEXT_PRIMARY
	
	local button = Components.Button(props)
	
	-- Border
	local stroke = Instance.new("UIStroke")
	stroke.Color = Config.COLORS.BORDER_DEFAULT
	stroke.Thickness = 1
	stroke.Parent = button
	
	return button
end

-- TextBox
function Components.TextBox(props)
	local container = Instance.new("Frame")
	container.Name = props.Name or "TextBoxContainer"
	container.BackgroundColor3 = Config.COLORS.SURFACE_DEFAULT
	container.BorderSizePixel = 0
	container.Size = props.Size or UDim2.new(1, 0, 0, 40)
	container.Position = props.Position or UDim2.new(0, 0, 0, 0)
	container.Parent = props.Parent
	
	addCorner(container, 6)
	
	-- Border
	local stroke = Instance.new("UIStroke")
	stroke.Color = Config.COLORS.BORDER_DEFAULT
	stroke.Thickness = 1
	stroke.Parent = container
	
	local textBox = Instance.new("TextBox")
	textBox.Name = "TextBox"
	textBox.BackgroundTransparency = 1
	textBox.Size = UDim2.new(1, -20, 1, 0)
	textBox.Position = UDim2.new(0, 10, 0, 0)
	textBox.Font = Enum.Font.Gotham
	textBox.TextSize = props.TextSize or 14
	textBox.TextColor3 = Config.COLORS.TEXT_PRIMARY
	textBox.PlaceholderText = props.Placeholder or ""
	textBox.PlaceholderColor3 = Config.COLORS.TEXT_TERTIARY
	textBox.Text = props.Text or ""
	textBox.TextXAlignment = Enum.TextXAlignment.Left
	textBox.TextYAlignment = Enum.TextYAlignment.Center
	textBox.ClearTextOnFocus = props.ClearOnFocus or false
	textBox.MultiLine = props.MultiLine or false
	textBox.Parent = container
	
	-- Focus effects
	textBox.Focused:Connect(function()
		stroke.Color = Config.COLORS.BORDER_FOCUS
	end)
	
	textBox.FocusLost:Connect(function(enterPressed)
		stroke.Color = Config.COLORS.BORDER_DEFAULT
		if enterPressed and props.OnEnter then
			props.OnEnter(textBox.Text)
		end
	end)
	
	if props.OnChange then
		textBox:GetPropertyChangedSignal("Text"):Connect(function()
			props.OnChange(textBox.Text)
		end)
	end
	
	return container, textBox
end

-- Multi-line TextBox
function Components.MultiLineTextBox(props)
	props.MultiLine = true
	props.Size = props.Size or UDim2.new(1, 0, 0, 100)
	
	local container, textBox = Components.TextBox(props)
	textBox.TextYAlignment = Enum.TextYAlignment.Top
	textBox.TextWrapped = true
	
	addPadding(textBox.Parent, 10)
	textBox.Size = UDim2.new(1, 0, 1, 0)
	textBox.Position = UDim2.new(0, 0, 0, 0)
	
	return container, textBox
end

-- Label
function Components.Label(props)
	local label = Instance.new("TextLabel")
	label.Name = props.Name or "Label"
	label.Text = props.Text or ""
	label.Font = props.Font or Enum.Font.Gotham
	label.TextSize = props.TextSize or 14
	label.TextColor3 = props.TextColor or Config.COLORS.TEXT_PRIMARY
	label.BackgroundTransparency = 1
	label.Size = props.Size or UDim2.new(1, 0, 0, 20)
	label.Position = props.Position or UDim2.new(0, 0, 0, 0)
	label.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	label.TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Top
	label.TextWrapped = props.TextWrapped or true
	label.Parent = props.Parent
	
	return label
end

-- ScrollingFrame
function Components.ScrollFrame(props)
	local frame = Instance.new("ScrollingFrame")
	frame.Name = props.Name or "ScrollFrame"
	frame.BackgroundColor3 = props.BackgroundColor or Config.COLORS.BACKGROUND_SECONDARY
	frame.BorderSizePixel = 0
	frame.Size = props.Size or UDim2.new(1, 0, 1, 0)
	frame.Position = props.Position or UDim2.new(0, 0, 0, 0)
	frame.CanvasSize = UDim2.new(0, 0, 0, 0)
	frame.ScrollBarThickness = Config.UI.SCROLL_BAR_WIDTH
	frame.ScrollBarImageColor3 = Config.COLORS.SURFACE_ELEVATED
	frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	frame.Parent = props.Parent
	
	-- UIListLayout for auto-sizing
	if not props.NoLayout then
		local layout = Instance.new("UIListLayout")
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, props.Spacing or Config.UI.SPACING)
		layout.Parent = frame
	end
	
	if not props.NoCorner then
		addCorner(frame, 8)
	end
	
	if props.Padding then
		addPadding(frame, props.Padding)
	end
	
	return frame
end

-- Chat Message Bubble (Modern Design)
function Components.ChatMessage(props)
	local isUser = props.Role == "user"
	
	local container = Instance.new("Frame")
	container.Name = "ChatMessage"
	container.BackgroundTransparency = 1
	container.Size = UDim2.new(1, 0, 0, 0)
	container.AutomaticSize = Enum.AutomaticSize.Y
	container.Parent = props.Parent
	
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 6)
	layout.Parent = container
	
	addPadding(container, 8)
	
	-- Header row (icon/avatar + name + timestamp)
	local headerRow = Instance.new("Frame")
	headerRow.Name = "HeaderRow"
	headerRow.BackgroundTransparency = 1
	headerRow.Size = UDim2.new(1, 0, 0, 20)
	headerRow.LayoutOrder = 1
	headerRow.Parent = container
	
	-- Avatar/Icon (User or Roblox logo)
	if isUser then
		-- User emoji
		local userIcon = Instance.new("TextLabel")
		userIcon.Name = "UserIcon"
		userIcon.Text = "👤"
		userIcon.Font = Enum.Font.Gotham
		userIcon.TextSize = 16
		userIcon.BackgroundTransparency = 1
		userIcon.Size = UDim2.new(0, 20, 0, 20)
		userIcon.Position = UDim2.new(0, 0, 0, 0)
		userIcon.TextXAlignment = Enum.TextXAlignment.Center
		userIcon.TextYAlignment = Enum.TextYAlignment.Center
		userIcon.Parent = headerRow
	else
		-- Roblox logo (red square emoji as placeholder)
		local robloxIcon = Instance.new("TextLabel")
		robloxIcon.Name = "RobloxIcon"
		robloxIcon.Text = "🟥" -- Roblox red square
		robloxIcon.Font = Enum.Font.Gotham
		robloxIcon.TextSize = 16
		robloxIcon.BackgroundTransparency = 1
		robloxIcon.Size = UDim2.new(0, 20, 0, 20)
		robloxIcon.Position = UDim2.new(0, 0, 0, 0)
		robloxIcon.TextXAlignment = Enum.TextXAlignment.Center
		robloxIcon.TextYAlignment = Enum.TextYAlignment.Center
		robloxIcon.Parent = headerRow
	end
	
	-- Name label
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Text = isUser and "You" or "AI Assistant"
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 12
	nameLabel.TextColor3 = isUser and Config.COLORS.USER_MESSAGE or Config.COLORS.AI_MESSAGE
	nameLabel.BackgroundTransparency = 1
	nameLabel.Size = UDim2.new(0, 100, 0, 20)
	nameLabel.Position = UDim2.new(0, 26, 0, 0)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextYAlignment = Enum.TextYAlignment.Center
	nameLabel.Parent = headerRow
	
	-- Timestamp
	local timestamp = Instance.new("TextLabel")
	timestamp.Name = "Timestamp"
	timestamp.Text = os.date("%H:%M:%S")
	timestamp.Font = Enum.Font.Gotham
	timestamp.TextSize = 10
	timestamp.TextColor3 = Color3.fromRGB(150, 150, 150)
	timestamp.BackgroundTransparency = 1
	timestamp.Size = UDim2.new(0, 60, 0, 20)
	timestamp.Position = UDim2.new(0, 130, 0, 0)
	timestamp.TextXAlignment = Enum.TextXAlignment.Left
	timestamp.TextYAlignment = Enum.TextYAlignment.Center
	timestamp.Parent = headerRow
	
	-- Message bubble
	local bubble = Instance.new("Frame")
	bubble.Name = "Bubble"
	bubble.BackgroundColor3 = isUser and Config.COLORS.SURFACE_ELEVATED or Config.COLORS.SURFACE_DEFAULT
	bubble.BorderSizePixel = 0
	bubble.Size = UDim2.new(1, -20, 0, 0)
	bubble.AutomaticSize = Enum.AutomaticSize.Y
	bubble.LayoutOrder = 2
	bubble.Parent = container
	
	-- Modern rounded corners
	addCorner(bubble, 12)
	
	-- More padding for better readability
	local bubblePadding = Instance.new("UIPadding")
	bubblePadding.PaddingLeft = UDim.new(0, 14)
	bubblePadding.PaddingRight = UDim.new(0, 14)
	bubblePadding.PaddingTop = UDim.new(0, 12)
	bubblePadding.PaddingBottom = UDim.new(0, 12)
	bubblePadding.Parent = bubble
	
	-- Subtle shadow effect
	local shadow = Instance.new("UIStroke")
	shadow.Name = "Shadow"
	shadow.Color = Color3.fromRGB(0, 0, 0)
	shadow.Thickness = 1
	shadow.Transparency = 0.85
	shadow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	shadow.Parent = bubble
	
	-- Message text
	local message = Instance.new("TextLabel")
	message.Name = "Message"
	message.Text = props.Message or ""
	message.Font = Enum.Font.Gotham
	message.TextSize = 14
	message.TextColor3 = Config.COLORS.TEXT_PRIMARY
	message.BackgroundTransparency = 1
	message.Size = UDim2.new(1, 0, 0, 0)
	message.AutomaticSize = Enum.AutomaticSize.Y
	message.TextWrapped = true -- Enable text wrapping for long messages
	message.TextXAlignment = Enum.TextXAlignment.Left
	message.TextYAlignment = Enum.TextYAlignment.Top
	message.RichText = true
	message.Parent = bubble
	
	return container
end

-- Code Preview Block
function Components.CodeBlock(props)
	local container = Instance.new("Frame")
	container.Name = "CodeBlock"
	container.BackgroundColor3 = Config.COLORS.BACKGROUND_TERTIARY
	container.BorderSizePixel = 0
	container.Size = props.Size or UDim2.new(1, 0, 0, 200)
	container.Parent = props.Parent
	
	addCorner(container, 6)
	
	-- Header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.BackgroundColor3 = Config.COLORS.BACKGROUND_MODAL
	header.BorderSizePixel = 0
	header.Size = UDim2.new(1, 0, 0, 30)
	header.Parent = container
	
	addCorner(header, 6)
	
	local headerLabel = Components.Label({
		Parent = header,
		Text = props.Language or "lua",
		TextColor = Config.COLORS.TEXT_SECONDARY,
		TextSize = 12,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(1, -20, 1, 0),
		Font = Enum.Font.GothamBold
	})
	
	-- Code scroll frame
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "CodeScroll"
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.Position = UDim2.new(0, 0, 0, 35)
	scrollFrame.Size = UDim2.new(1, 0, 1, -35)
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollFrame.Parent = container
	
	addPadding(scrollFrame, 10)
	
	-- Code text
	local codeLabel = Instance.new("TextLabel")
	codeLabel.Name = "Code"
	codeLabel.Text = props.Code or ""
	codeLabel.Font = Enum.Font.Code
	codeLabel.TextSize = 13
	codeLabel.TextColor3 = Config.COLORS.TEXT_PRIMARY
	codeLabel.BackgroundTransparency = 1
	codeLabel.Size = UDim2.new(1, 0, 0, 0)
	codeLabel.AutomaticSize = Enum.AutomaticSize.Y
	codeLabel.TextWrapped = false
	codeLabel.TextXAlignment = Enum.TextXAlignment.Left
	codeLabel.TextYAlignment = Enum.TextYAlignment.Top
	codeLabel.Parent = scrollFrame
	
	return container
end

-- Separator Line
function Components.Separator(props)
	local line = Instance.new("Frame")
	line.Name = "Separator"
	line.BackgroundColor3 = Config.COLORS.BORDER_DEFAULT
	line.BorderSizePixel = 0
	line.Size = props.Size or UDim2.new(1, 0, 0, 1)
	line.Position = props.Position or UDim2.new(0, 0, 0, 0)
	line.Parent = props.Parent
	
	return line
end

-- Loading Spinner
function Components.LoadingSpinner(props)
	local container = Instance.new("Frame")
	container.Name = "LoadingSpinner"
	container.BackgroundTransparency = 1
	container.Size = props.Size or UDim2.new(0, 40, 0, 40)
	container.Position = props.Position or UDim2.new(0.5, -20, 0.5, -20)
	container.Parent = props.Parent
	
	local spinner = Instance.new("ImageLabel")
	spinner.Name = "Spinner"
	spinner.BackgroundTransparency = 1
	spinner.Size = UDim2.new(1, 0, 1, 0)
	spinner.Image = "rbxasset://textures/ui/LoadingCircle.png"
	spinner.ImageColor3 = Config.COLORS.ACCENT_PRIMARY
	spinner.Parent = container
	
	-- Rotation animation
	local rotation = 0
	task.spawn(function()
		while spinner.Parent do
			rotation = rotation + 5
			spinner.Rotation = rotation
			task.wait(0.03)
		end
	end)
	
	return container
end

-- Icon Button
function Components.IconButton(props)
	local button = Instance.new("ImageButton")
	button.Name = props.Name or "IconButton"
	button.BackgroundColor3 = props.BackgroundColor or Config.COLORS.SURFACE_DEFAULT
	button.BorderSizePixel = 0
	button.Size = props.Size or UDim2.new(0, 32, 0, 32)
	button.Position = props.Position or UDim2.new(0, 0, 0, 0)
	button.Image = props.Icon or ""
	button.ImageColor3 = props.IconColor or Config.COLORS.TEXT_PRIMARY
	button.AutoButtonColor = false
	button.Parent = props.Parent
	
	addCorner(button, 6)
	
	-- Hover effect
	button.MouseEnter:Connect(function()
		button.BackgroundColor3 = props.HoverColor or Config.COLORS.SURFACE_HOVER
	end)
	
	button.MouseLeave:Connect(function()
		button.BackgroundColor3 = props.BackgroundColor or Config.COLORS.SURFACE_DEFAULT
	end)
	
	if props.OnClick then
		button.MouseButton1Click:Connect(props.OnClick)
	end
	
	return button
end

-- Dropdown Menu
function Components.Dropdown(props)
	local container = Instance.new("Frame")
	container.Name = props.Name or "Dropdown"
	container.BackgroundColor3 = Config.COLORS.SURFACE_DEFAULT
	container.BorderSizePixel = 0
	container.Size = props.Size or UDim2.new(0, 200, 0, 36)
	container.Position = props.Position or UDim2.new(0, 0, 0, 0)
	container.Parent = props.Parent
	
	addCorner(container, 6)
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Config.COLORS.BORDER_DEFAULT
	stroke.Thickness = 1
	stroke.Parent = container
	
	local button = Instance.new("TextButton")
	button.Name = "DropdownButton"
	button.BackgroundTransparency = 1
	button.Size = UDim2.new(1, 0, 1, 0)
	button.Font = Enum.Font.Gotham
	button.TextSize = 14
	button.TextColor3 = Config.COLORS.TEXT_PRIMARY
	button.Text = props.DefaultText or "Select..."
	button.TextXAlignment = Enum.TextXAlignment.Left
	button.Parent = container
	
	addPadding(button, 10)
	
	-- Arrow indicator
	local arrow = Components.Label({
		Parent = container,
		Text = "▼",
		TextSize = 10,
		Position = UDim2.new(1, -25, 0, 0),
		Size = UDim2.new(0, 20, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center
	})
	
	-- Dropdown list (hidden by default)
	local listContainer = Instance.new("Frame")
	listContainer.Name = "DropdownList"
	listContainer.BackgroundColor3 = Config.COLORS.SURFACE_ELEVATED
	listContainer.BorderSizePixel = 0
	listContainer.Position = UDim2.new(0, 0, 1, 5)
	listContainer.Size = UDim2.new(1, 0, 0, 0)
	listContainer.Visible = false
	listContainer.ZIndex = 10
	listContainer.Parent = container
	
	addCorner(listContainer, 6)
	
	local listStroke = Instance.new("UIStroke")
	listStroke.Color = Config.COLORS.BORDER_DEFAULT
	listStroke.Thickness = 1
	listStroke.Parent = listContainer
	
	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = listContainer
	
	-- Toggle dropdown
	button.MouseButton1Click:Connect(function()
		listContainer.Visible = not listContainer.Visible
	end)
	
	-- Add items
	local dropdownAPI = {}
	
	function dropdownAPI:AddItem(text, value)
		local item = Instance.new("TextButton")
		item.Name = "Item_" .. text
		item.BackgroundColor3 = Config.COLORS.SURFACE_ELEVATED
		item.BorderSizePixel = 0
		item.Size = UDim2.new(1, 0, 0, 30)
		item.Font = Enum.Font.Gotham
		item.TextSize = 13
		item.TextColor3 = Config.COLORS.TEXT_PRIMARY
		item.Text = text
		item.TextXAlignment = Enum.TextXAlignment.Left
		item.AutoButtonColor = false
		item.Parent = listContainer
		
		addPadding(item, 8)
		
		item.MouseEnter:Connect(function()
			item.BackgroundColor3 = Config.COLORS.SURFACE_HOVER
		end)
		
		item.MouseLeave:Connect(function()
			item.BackgroundColor3 = Config.COLORS.SURFACE_ELEVATED
		end)
		
		item.MouseButton1Click:Connect(function()
			button.Text = text
			listContainer.Visible = false
			if props.OnSelect then
				props.OnSelect(value or text)
			end
		end)
		
		-- Update list size
		listContainer.Size = UDim2.new(1, 0, 0, #listContainer:GetChildren() * 30)
	end
	
	function dropdownAPI:SetValue(text)
		button.Text = text
	end
	
	function dropdownAPI:GetValue()
		return button.Text
	end
	
	return container, dropdownAPI
end

return Components
