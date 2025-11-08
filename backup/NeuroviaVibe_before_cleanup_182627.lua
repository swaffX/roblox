-- Neurovia Coder v2.0.0 - Super AI Comprehension
-- Advanced intent detection + premium modern UI

local HttpService = game:GetService("HttpService")
local Selection = game:GetService("Selection")

-- ============ SETTINGS ============
local Settings = {}
function Settings:get(k, d) 
  local ok,v=pcall(function() 
    local raw=plugin:GetSetting('neurovia_'..k) 
    return raw and HttpService:JSONDecode(raw) or nil 
  end) 
  return ok and (v~=nil and v or d) or d 
end
function Settings:set(k, v) plugin:SetSetting('neurovia_'..k, HttpService:JSONEncode(v)) end

-- Developer IDs
local DEVELOPERS = {1171755677, 734747479}

-- ============ COLORS ============
local C = {
  bg = Color3.fromRGB(30,30,30),
  surface = Color3.fromRGB(40,40,40),
  surfaceDark = Color3.fromRGB(25,25,25),
  bubbleAI = Color3.fromRGB(45,45,45),
  bubbleUser = Color3.fromRGB(55,55,60),
  accent = Color3.fromRGB(88,101,242),
  text = Color3.fromRGB(220,221,222),
  text2 = Color3.fromRGB(185,187,190),
  textMuted = Color3.fromRGB(140,142,145),
  border = Color3.fromRGB(50,50,50),
  danger = Color3.fromRGB(237,66,69),
  success = Color3.fromRGB(67,181,129),
}

local function font(inst, bold)
  if inst:IsA('TextLabel') or inst:IsA('TextButton') or inst:IsA('TextBox') then
    inst.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
  end
end
local function corner(ui, r) 
  local c=Instance.new('UICorner') 
  c.CornerRadius=UDim.new(0, r or 8) 
  c.Parent=ui 
  return c 
end
local function border(ui) 
  local s=Instance.new('UIStroke') 
  s.Color=C.border 
  s.Thickness=1 
  s.Transparency=0.5 
  s.Parent=ui 
  return s 
end

-- ============ STORAGE ============
local Store = {}
function Store:setKey(prov,key) Settings:set('key_'..prov,{d=key}) end
function Store:getKey(prov) local t=Settings:get('key_'..prov) return t and t.d or nil end
function Store:pushUndo(item)
  local st=Settings:get('undo',{}) 
  table.insert(st,1,item) 
  while #st>5 do table.remove(st) end 
  Settings:set('undo',st) 
end
function Store:popUndo() 
  local st=Settings:get('undo',{}) 
  local it=st[1] 
  if it then table.remove(st,1) Settings:set('undo',st) end 
  return it 
end

-- ============ AI PROVIDERS ============
local function providerOf(model)
  if not model or type(model) ~= 'string' or model == '' then 
    print('[DEBUG] providerOf: Invalid model:', model)
    return nil 
  end
  local modelLower = model:lower()
  if modelLower:find('gemini') then return 'Gemini' end
  if modelLower:find('claude') then return 'Anthropic' end
  if modelLower:find('haiku') then return 'Anthropic' end
  if modelLower:find('composer') then return 'Anthropic' end
  if modelLower:find('sonnet') then return 'Anthropic' end
  if modelLower:find('deepseek') then return 'DeepSeek' end
  if modelLower:find('grok') then return 'xAI' end
  return 'OpenAI'
end

local AI = {} AI.__index=AI
function AI.new(model) return setmetatable({model=model}, AI) end

local function httpRequest(req)
  local ok,res=pcall(function() return HttpService:RequestAsync(req) end)
  if not ok then return false,'Network error' end
  if res.StatusCode<200 or res.StatusCode>=300 then
    if res.StatusCode==401 or res.StatusCode==403 then return false,'Invalid API key' end
    if res.StatusCode==429 then return false,'Rate limited' end
    return false,'HTTP '..res.StatusCode
  end
  local ok2,data=pcall(function() return HttpService:JSONDecode(res.Body) end)
  return ok2 and true or false, ok2 and data or 'Invalid JSON'
end

function AI:chat(messages, key)
  local p = providerOf(self.model)
  if p=='Gemini' then
    -- Use v1 for Pro models to avoid 503
    local apiVersion = self.model:find('pro') and 'v1' or 'v1beta'
    local cleanModel = self.model:gsub("[^%w%-%.]+", "")  -- Remove emojis
    local url='https://generativelanguage.googleapis.com/'..apiVersion..'/models/'..cleanModel..':generateContent?key='..key
    local contents={}
    
    -- Gemini doesn't have system role, so inject system as first user message
    local sysMsg = ''
    for _,m in ipairs(messages) do 
      if m.role=='system' then 
        sysMsg = m.content
      else
        table.insert(contents,{role=(m.role=='assistant' and 'model' or 'user'),parts={{text=m.content}}}) 
      end 
    end
    
    -- Prepend system instructions to first user message
    if #contents > 0 and sysMsg ~= '' then
      local userText = contents[1].parts[1].text
      -- Check if user wants code
      if userText:lower():find('oluştur') or userText:lower():find('yap') or userText:lower():find('gui') then
        contents[1].parts[1].text = sysMsg .. '\\n\\n[USER REQUEST - OUTPUT CODE ONLY]\\n' .. userText
      else
        contents[1].parts[1].text = sysMsg .. '\\n\\n' .. userText
      end
    end
    
    -- Retry logic for 503 errors
    local maxRetries = 3
    local retryDelay = 2
    
    for attempt = 1, maxRetries do
      local ok,data=httpRequest({Url=url,Method='POST',Headers={['Content-Type']='application/json'},Body=HttpService:JSONEncode({contents=contents})})
      
      if ok then
        local text = (((data.candidates or {})[1] or {}).content or {}).parts
        text = text and text[1] and text[1].text or nil
        if not text or #text==0 then 
          return false,'Empty response from AI'
        end
        return true,text
      elseif data == 'HTTP 503' and attempt < maxRetries then
        -- Wait and retry
        task.wait(retryDelay)
        retryDelay = retryDelay * 1.5 -- Exponential backoff
      else
        return false,data
      end
    end
    
    return false,'Max retries exceeded'
  elseif p=='OpenAI' then
    local ok,data=httpRequest({Url='https://api.openai.com/v1/chat/completions',Method='POST',Headers={['Authorization']='Bearer '..key,['Content-Type']='application/json'},Body=HttpService:JSONEncode({model=self.model,messages=messages})})
    if not ok then return false,data end
    local text = (((data.choices or {})[1] or {}).message or {}).content
    return text and true or false, text or 'Empty response'
  elseif p=='Anthropic' then
    local sys='' local msgs={} 
    for _,m in ipairs(messages) do 
      if m.role=='system' then sys=m.content else table.insert(msgs,m) end 
    end
    local ok,data=httpRequest({Url='https://api.anthropic.com/v1/messages',Method='POST',Headers={['x-api-key']=key,['anthropic-version']='2023-06-01',['content-type']='application/json'},Body=HttpService:JSONEncode({model=self.model,max_tokens=2048,system=sys,messages=msgs})})
    if not ok then return false,data end
    local text=((data.content or {})[1] or {}).text
    return text and true or false,text or 'Empty response'
  else
    local ok,data=httpRequest({Url='https://api.deepseek.com/v1/chat/completions',Method='POST',Headers={['Authorization']='Bearer '..key,['Content-Type']='application/json'},Body=HttpService:JSONEncode({model=self.model,messages=messages})})
    if not ok then return false,data end
    local text = (((data.choices or {})[1] or {}).message or {}).content
    return text and true or false, text or 'Empty response'
  end
end

-- ============ CONTEXT ============
local ALL_SERVICES = {
  'Workspace',
  'Players',
  'ReplicatedStorage',
  'ReplicatedFirst',
  'ServerScriptService',
  'ServerStorage',
  'StarterGui',
  'StarterPack',
  'StarterPlayer',
  'Teams',
  'SoundService',
  'Chat',
  'LocalizationService',
  'TestService'
}

local function getAllScripts()
  local scripts = {}
  
  for _, serviceName in ipairs(ALL_SERVICES) do
    local ok, svc = pcall(function() return game:GetService(serviceName) end)
    if ok and svc then
      for _,desc in ipairs(svc:GetDescendants()) do
        if desc:IsA('Script') or desc:IsA('LocalScript') or desc:IsA('ModuleScript') then
          local ok2,src = pcall(function() return desc.Source end)
          if ok2 then
            table.insert(scripts, {
              name = desc.Name,
              class = desc.ClassName,
              path = desc:GetFullName(),
              source = src:sub(1,1000),
              length = #src,
              instance = desc
            })
          end
        end
      end
    end
  end
  
  return scripts
end

local function getContext()
  local sel = Selection:Get()
  local ctx = {'=== ROBLOX PROJECT CONTEXT ===\\n'}
  
  -- All services overview
  table.insert(ctx, 'Available Services:')
  for _, serviceName in ipairs(ALL_SERVICES) do
    local ok, svc = pcall(function() return game:GetService(serviceName) end)
    if ok and svc then
      local count = #svc:GetDescendants()
      table.insert(ctx, string.format('- %s: %d objects', serviceName, count))
    end
  end
  
  -- All scripts in project
  local scripts = getAllScripts()
  table.insert(ctx, string.format('\nTotal Scripts: %d', #scripts))
  if #scripts > 0 then
    table.insert(ctx, '\nExisting Scripts:')
    for i,s in ipairs(scripts) do
      if i <= 10 then -- Show first 10
        table.insert(ctx, string.format('  [%d] %s (%s) at %s - %d chars', i, s.name, s.class, s.path, s.length))
        if s.length > 0 and s.length < 500 then
          table.insert(ctx, '    Preview: '..s.source:sub(1,200):gsub('\n',' '))
        end
      end
    end
    if #scripts > 10 then
      table.insert(ctx, string.format('  ... and %d more scripts', #scripts-10))
    end
  end
  
  -- Selection
  if #sel>0 then
    table.insert(ctx, '\nCurrently Selected:')
    for i,obj in ipairs(sel) do 
      table.insert(ctx, string.format('  [%d] %s "%s"', i, obj.ClassName, obj.Name)) 
    end
  end
  
  return table.concat(ctx, '\n')
end

-- ============ LOGO ============
-- Use simple built-in icon (empty string = default plugin icon)
local LOGO_DATA = ''

-- ============ UI SETUP ============
local toolbar = plugin:CreateToolbar('Neurovia')
local btn = toolbar:CreateButton('Neurovia Coder v2.0.0','Super AI with advanced comprehension',LOGO_DATA)
local info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Right,false,false,420,720,380,600)
local widget = plugin:CreateDockWidgetPluginGui('NeuroviaCoder', info)
widget.Title = 'Neurovia Coder'

local root = Instance.new('Frame')
root.Size=UDim2.new(1,0,1,0)
root.BackgroundColor3=C.bg
root.Parent=widget

-- Tab system
local activeTab = 'chat' -- 'chat' or 'debug'

local tabBar = Instance.new('Frame')
tabBar.BackgroundTransparency=1
tabBar.Size=UDim2.new(1,-20,0,36)
tabBar.Position=UDim2.new(0,10,0,8)
tabBar.Parent=root

-- Chat tab button (Cursor-style like input)
local chatTab = Instance.new('TextButton')
chatTab.BackgroundColor3=Color3.fromRGB(28,28,30)
chatTab.BorderSizePixel=0
chatTab.TextColor3=Color3.fromRGB(220,221,222)
chatTab.Text='💬 Chat'
chatTab.TextSize=11
chatTab.Size=UDim2.new(0.5,-2,1,0)
chatTab.Position=UDim2.new(0,0,0,0)
chatTab.AutoButtonColor=false
chatTab.TextStrokeTransparency=1
chatTab.ClipsDescendants=true
chatTab.SelectionImageObject=nil
chatTab.SelectionBehaviorUp=Enum.SelectionBehavior.Stop
chatTab.SelectionBehaviorDown=Enum.SelectionBehavior.Stop
chatTab.SelectionBehaviorLeft=Enum.SelectionBehavior.Stop
chatTab.SelectionBehaviorRight=Enum.SelectionBehavior.Stop
chatTab.Selectable=false
chatTab.Parent=tabBar
corner(chatTab,8)
font(chatTab,true)

local chatTabStroke=Instance.new('UIStroke')
chatTabStroke.Color=Color3.fromRGB(88,101,242)
chatTabStroke.Thickness=1.5
chatTabStroke.Transparency=0
chatTabStroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
chatTabStroke.Parent=chatTab

-- Debug tab button (Cursor-style like input)
local debugTab = Instance.new('TextButton')
debugTab.BackgroundColor3=Color3.fromRGB(28,28,30)
debugTab.BorderSizePixel=0
debugTab.TextColor3=Color3.fromRGB(160,162,170)
debugTab.Text='🛠️ Debug'
debugTab.TextSize=11
debugTab.Size=UDim2.new(0.5,-2,1,0)
debugTab.Position=UDim2.new(0.5,2,0,0)
debugTab.AutoButtonColor=false
debugTab.TextStrokeTransparency=1
debugTab.ClipsDescendants=true
debugTab.SelectionImageObject=nil
debugTab.SelectionBehaviorUp=Enum.SelectionBehavior.Stop
debugTab.SelectionBehaviorDown=Enum.SelectionBehavior.Stop
debugTab.SelectionBehaviorLeft=Enum.SelectionBehavior.Stop
debugTab.SelectionBehaviorRight=Enum.SelectionBehavior.Stop
debugTab.Selectable=false
debugTab.Parent=tabBar
corner(debugTab,8)
font(debugTab,true)

local debugTabStroke=Instance.new('UIStroke')
debugTabStroke.Color=Color3.fromRGB(45,45,48)
debugTabStroke.Thickness=0.5
debugTabStroke.Transparency=0.7
debugTabStroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
debugTabStroke.Parent=debugTab


-- Menu button (three dots) - Hidden for now since all actions are inline
local menuBtn=Instance.new('TextButton')
menuBtn.BackgroundColor3=Color3.fromRGB(30,30,33)
menuBtn.TextColor3=C.text2
menuBtn.TextSize=18
menuBtn.Text='⋯'
menuBtn.Size=UDim2.new(0,32,0,32)
menuBtn.Position=UDim2.new(1,-38,0,6)
menuBtn.AutoButtonColor=false
menuBtn.Visible=false  -- Hidden since no menu items
menuBtn.Parent=root
corner(menuBtn,8)
font(menuBtn,true)

-- Border
local menuStroke=Instance.new('UIStroke')
menuStroke.Color=Color3.fromRGB(60,60,65)
menuStroke.Thickness=1
menuStroke.Transparency=0.5
menuStroke.Parent=menuBtn

menuBtn.MouseEnter:Connect(function()
  game:GetService('TweenService'):Create(menuBtn, TweenInfo.new(0.15), {BackgroundColor3=Color3.fromRGB(45,45,50)}):Play()
  game:GetService('TweenService'):Create(menuStroke, TweenInfo.new(0.15), {Color=Color3.fromRGB(90,90,95), Transparency=0.3}):Play()
end)
menuBtn.MouseLeave:Connect(function()
  game:GetService('TweenService'):Create(menuBtn, TweenInfo.new(0.15), {BackgroundColor3=Color3.fromRGB(30,30,33)}):Play()
  game:GetService('TweenService'):Create(menuStroke, TweenInfo.new(0.15), {Color=Color3.fromRGB(60,60,65), Transparency=0.5}):Play()
end)

-- Chat area
local chat = Instance.new('ScrollingFrame')
chat.Position=UDim2.new(0,10,0,52)
chat.Size=UDim2.new(1,-20,1,-188)
chat.BackgroundTransparency=1
chat.BorderSizePixel=0
chat.ScrollBarThickness=6
chat.ScrollBarImageColor3=C.border
chat.ScrollingDirection=Enum.ScrollingDirection.Y
chat.ScrollingEnabled=true
chat.ElasticBehavior=Enum.ElasticBehavior.Always
chat.ScrollBarImageTransparency=0.5
chat.TopImage='rbxasset://textures/ui/Scroll/scroll-middle.png'
chat.BottomImage='rbxasset://textures/ui/Scroll/scroll-middle.png'
chat.MidImage='rbxasset://textures/ui/Scroll/scroll-middle.png'
chat.AutomaticCanvasSize=Enum.AutomaticSize.Y
chat.CanvasSize=UDim2.new()
chat.Visible=true
chat.Parent=root

local chatPad=Instance.new('UIPadding')
chatPad.PaddingRight=UDim.new(0,8)
chatPad.PaddingBottom=UDim.new(0,16)
chatPad.Parent=chat

local chatList = Instance.new('UIListLayout')
chatList.Padding=UDim.new(0,12)
chatList.SortOrder=Enum.SortOrder.LayoutOrder
chatList.Parent=chat

-- Debug area (same style as chat)
local debugScroll = Instance.new('ScrollingFrame')
debugScroll.Position=UDim2.new(0,10,0,52)
debugScroll.Size=UDim2.new(1,-20,1,-68)
debugScroll.BackgroundTransparency=1
debugScroll.BorderSizePixel=0
debugScroll.ScrollBarThickness=6
debugScroll.ScrollBarImageColor3=C.border
debugScroll.ScrollingDirection=Enum.ScrollingDirection.Y
debugScroll.ScrollingEnabled=true
debugScroll.ElasticBehavior=Enum.ElasticBehavior.Always
debugScroll.ScrollBarImageTransparency=0.5
debugScroll.TopImage='rbxasset://textures/ui/Scroll/scroll-middle.png'
debugScroll.BottomImage='rbxasset://textures/ui/Scroll/scroll-middle.png'
debugScroll.MidImage='rbxasset://textures/ui/Scroll/scroll-middle.png'
debugScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
debugScroll.CanvasSize=UDim2.new()
debugScroll.Visible=false
debugScroll.Parent=root

local debugPad=Instance.new('UIPadding')
debugPad.PaddingRight=UDim.new(0,8)
debugPad.PaddingBottom=UDim.new(0,16)
debugPad.Parent=debugScroll

local debugList = Instance.new('UIListLayout')
debugList.Padding=UDim.new(0,8)
debugList.SortOrder=Enum.SortOrder.LayoutOrder
debugList.Parent=debugScroll

-- Bottom bar (only in chat tab) - MOVED BEFORE switchTab
local bar=Instance.new('Frame')
bar.BackgroundColor3=C.surfaceDark
bar.BorderSizePixel=0
bar.Size=UDim2.new(1,0,0,68)
bar.Position=UDim2.new(0,0,1,-68)
bar.Parent=root
bar.Name='BottomBar'

local barBorder=Instance.new('Frame')
barBorder.Name='BarBorder'
barBorder.BackgroundColor3=C.border
barBorder.Size=UDim2.new(1,0,0,1)
barBorder.BorderSizePixel=0
barBorder.Parent=bar

-- Tab switching logic
local function switchTab(tab)
  activeTab = tab
  if tab == 'chat' then
    chat.Visible = true
    debugScroll.Visible = false
    bar.Visible = true
    barBorder.Visible = true
    chatTab.TextColor3 = Color3.fromRGB(220,221,222)
    chatTabStroke.Color = Color3.fromRGB(88,101,242)
    chatTabStroke.Thickness = 1.5
    chatTabStroke.Transparency = 0
    debugTab.TextColor3 = Color3.fromRGB(160,162,170)
    debugTabStroke.Color = Color3.fromRGB(45,45,48)
    debugTabStroke.Thickness = 0.5
    debugTabStroke.Transparency = 0.7
  else
    chat.Visible = false
    debugScroll.Visible = true
    bar.Visible = false
    barBorder.Visible = false
    chatTab.TextColor3 = Color3.fromRGB(160,162,170)
    chatTabStroke.Color = Color3.fromRGB(45,45,48)
    chatTabStroke.Thickness = 0.5
    chatTabStroke.Transparency = 0.7
    debugTab.TextColor3 = Color3.fromRGB(220,221,222)
    debugTabStroke.Color = Color3.fromRGB(88,101,242)
    debugTabStroke.Thickness = 1.5
    debugTabStroke.Transparency = 0
  end
end

chatTab.MouseButton1Click:Connect(function()
  switchTab('chat')
  chatTab.SelectionImageObject = nil
  debugTab.SelectionImageObject = nil
end)

debugTab.MouseButton1Click:Connect(function()
  switchTab('debug')
  chatTab.SelectionImageObject = nil
  debugTab.SelectionImageObject = nil
end)

-- Remove selection on hover too
chatTab.MouseEnter:Connect(function()
  chatTab.SelectionImageObject = nil
end)

debugTab.MouseEnter:Connect(function()
  debugTab.SelectionImageObject = nil
end)

-- Old model/API rows removed - now using Cursor-style inline selectors

-- Prompt row (Cursor IDE style - with Agent/Model buttons)
local promptRow=Instance.new('Frame')
promptRow.BackgroundTransparency=1
promptRow.Size=UDim2.new(1,-20,0,48)
promptRow.Position=UDim2.new(0,10,0,8)
promptRow.Parent=bar

-- Current mode state
local currentMode = 'Agent' -- Agent, Ask, Plan
local currentModel = Settings:get('last_model', nil) -- Load last selected model

-- Cursor-style input container (full width)
local promptContainer=Instance.new('Frame')
promptContainer.BackgroundColor3=Color3.fromRGB(28,28,30)
promptContainer.BorderSizePixel=0
promptContainer.Size=UDim2.new(1,0,1,0)
promptContainer.Position=UDim2.new(0,0,0,0)
promptContainer.Parent=promptRow
corner(promptContainer,8)

local promptStroke=Instance.new('UIStroke')
promptStroke.Color=Color3.fromRGB(45,45,48)
promptStroke.Thickness=0.5
promptStroke.Transparency=0.7
promptStroke.Parent=promptContainer

-- Agent button (left, first)
local agentBtn=Instance.new('TextButton')
agentBtn.BackgroundTransparency=1
agentBtn.Text='∞ Agent'
agentBtn.TextColor3=Color3.fromRGB(160,162,170)
agentBtn.TextSize=11
agentBtn.Size=UDim2.new(0,74,1,0)
agentBtn.Position=UDim2.new(0,8,0,0)
agentBtn.TextXAlignment=Enum.TextXAlignment.Left
agentBtn.AutoButtonColor=false
agentBtn.AutomaticSize=Enum.AutomaticSize.None
agentBtn.ZIndex=10
agentBtn.Parent=promptContainer
font(agentBtn)

-- Model button (left, after agent)
local modelDisplayBtn=Instance.new('TextButton')
modelDisplayBtn.BackgroundTransparency=1
modelDisplayBtn.Text='⚡ Select Model'
modelDisplayBtn.TextColor3=Color3.fromRGB(160,162,170)
modelDisplayBtn.TextSize=11
modelDisplayBtn.Size=UDim2.new(0,110,1,0)
modelDisplayBtn.Position=UDim2.new(0,86,0,0)
modelDisplayBtn.TextXAlignment=Enum.TextXAlignment.Left
modelDisplayBtn.AutoButtonColor=false
modelDisplayBtn.AutomaticSize=Enum.AutomaticSize.None
modelDisplayBtn.ZIndex=10
modelDisplayBtn.Parent=promptContainer
font(modelDisplayBtn)

-- Model dropdown arrow removed for cleaner UI

-- Arrow is just visual - clicking model button opens menu

-- Separator line
local separator=Instance.new('Frame')
separator.BackgroundColor3=Color3.fromRGB(45,45,48)
separator.BorderSizePixel=0
separator.Size=UDim2.new(0,1,0,20)
separator.Position=UDim2.new(0,204,0,14)
separator.ZIndex=10
separator.Parent=promptContainer

-- Forward declare prompt (defined below)
local prompt

-- Agent dropdown menu function
local agentMenu = nil
local agentMenuOverlay = nil
local function showAgentMenu()
  -- Close model menu if open
  if modelMenu then modelMenu:Destroy() modelMenu = nil end
  if modelMenuOverlay then modelMenuOverlay:Destroy() modelMenuOverlay = nil end
  if agentMenu then agentMenu:Destroy() end
  if agentMenuOverlay then agentMenuOverlay:Destroy() end
  
  -- Create transparent overlay to catch outside clicks
  agentMenuOverlay = Instance.new('TextButton')
  agentMenuOverlay.BackgroundTransparency = 1
  agentMenuOverlay.Size = UDim2.new(1,0,1,0)
  agentMenuOverlay.ZIndex = 199
  agentMenuOverlay.Text = ''
  agentMenuOverlay.Parent = root
  agentMenuOverlay.MouseButton1Click:Connect(function()
    if agentMenu then agentMenu:Destroy() agentMenu = nil end
    if agentMenuOverlay then agentMenuOverlay:Destroy() agentMenuOverlay = nil end
  end)
  
  agentMenu = Instance.new('Frame')
  agentMenu.Name = 'AgentMenu'
  agentMenu.BackgroundColor3 = Color3.fromRGB(25,26,28)
  agentMenu.BorderSizePixel = 0
  agentMenu.Size = UDim2.new(0,160,0,0)
  agentMenu.Position = UDim2.new(0,18,1,-76)
  agentMenu.AnchorPoint = Vector2.new(0,1)
  agentMenu.AutomaticSize = Enum.AutomaticSize.Y
  agentMenu.ZIndex = 200
  agentMenu.Parent = root
  corner(agentMenu, 8)
  
  local menuStroke = Instance.new('UIStroke')
  menuStroke.Color = Color3.fromRGB(50,52,58)
  menuStroke.Thickness = 1
  menuStroke.Parent = agentMenu
  
  local menuPad = Instance.new('UIPadding')
  menuPad.PaddingLeft = UDim.new(0,6)
  menuPad.PaddingRight = UDim.new(0,6)
  menuPad.PaddingTop = UDim.new(0,6)
  menuPad.PaddingBottom = UDim.new(0,6)
  menuPad.Parent = agentMenu
  
  local menuList = Instance.new('UIListLayout')
  menuList.Padding = UDim.new(0,2)
  menuList.SortOrder = Enum.SortOrder.LayoutOrder
  menuList.Parent = agentMenu
  
  local modes = {
    {name='Agent', icon='∞', desc='Classic execution'},
    {name='Ask', icon='💬', desc='Deep research'}
  }
  
  for idx, mode in ipairs(modes) do
    local btn = Instance.new('TextButton')
    btn.BackgroundColor3 = (currentMode == mode.name) and Color3.fromRGB(45,48,54) or Color3.fromRGB(25,26,28)
    btn.BorderSizePixel = 0
    btn.Size = UDim2.new(1,0,0,32)
    btn.AutoButtonColor = false
    btn.Text = ''
    btn.ZIndex = 201
    btn.LayoutOrder = idx
    btn.Parent = agentMenu
    corner(btn, 6)
    
    local icon = Instance.new('TextLabel')
    icon.BackgroundTransparency = 1
    icon.Text = mode.icon
    icon.TextColor3 = Color3.fromRGB(160,162,170)
    icon.TextSize = 12
    icon.Size = UDim2.new(0,20,1,0)
    icon.Position = UDim2.new(0,8,0,0)
    icon.ZIndex = 202
    icon.Parent = btn
    font(icon)
    
    local label = Instance.new('TextLabel')
    label.BackgroundTransparency = 1
    label.Text = mode.name
    label.TextColor3 = (currentMode == mode.name) and Color3.fromRGB(220,221,222) or Color3.fromRGB(160,162,170)
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Size = UDim2.new(0,60,1,0)
    label.Position = UDim2.new(0,28,0,0)
    label.ZIndex = 202
    label.Parent = btn
    font(label)
    
    if currentMode == mode.name then
      local check = Instance.new('TextLabel')
      check.BackgroundTransparency = 1
      check.Text = '✓'
      check.TextColor3 = Color3.fromRGB(88,101,242)
      check.TextSize = 14
      check.Size = UDim2.new(0,20,1,0)
      check.Position = UDim2.new(1,-22,0,0)
      check.ZIndex = 202
      check.Parent = btn
      font(check, true)
    end
    
    btn.MouseEnter:Connect(function()
      if currentMode ~= mode.name then
        btn.BackgroundColor3 = Color3.fromRGB(35,37,42)
      end
    end)
    btn.MouseLeave:Connect(function()
      if currentMode ~= mode.name then
        btn.BackgroundColor3 = Color3.fromRGB(25,26,28)
      end
    end)
    btn.MouseButton1Click:Connect(function()
      currentMode = mode.name
      agentBtn.Text = mode.icon .. ' ' .. mode.name
      if agentMenu then agentMenu:Destroy() agentMenu = nil end
      if agentMenuOverlay then agentMenuOverlay:Destroy() agentMenuOverlay = nil end
      
      -- Update placeholder
      if prompt then
        if currentMode == 'Agent' then
          prompt.PlaceholderText = 'Execute command...'
        elseif currentMode == 'Ask' then
          prompt.PlaceholderText = 'Ask for detailed explanation...'
        end
      end
    end)
  end
end

agentBtn.MouseButton1Click:Connect(function()
  if agentMenu then
    if agentMenu then agentMenu:Destroy() agentMenu = nil end
    if agentMenuOverlay then agentMenuOverlay:Destroy() agentMenuOverlay = nil end
  else
    showAgentMenu()
  end
end)

-- Model dropdown menu
local modelMenu = nil
local modelMenuOverlay = nil
local function showModelMenu()
  -- Close agent menu if open
  if agentMenu then agentMenu:Destroy() agentMenu = nil end
  if agentMenuOverlay then agentMenuOverlay:Destroy() agentMenuOverlay = nil end
  if modelMenu then modelMenu:Destroy() end
  if modelMenuOverlay then modelMenuOverlay:Destroy() end
  
  -- Create transparent overlay to catch outside clicks
  modelMenuOverlay = Instance.new('TextButton')
  modelMenuOverlay.BackgroundTransparency = 1
  modelMenuOverlay.Size = UDim2.new(1,0,1,0)
  modelMenuOverlay.ZIndex = 199
  modelMenuOverlay.Text = ''
  modelMenuOverlay.Parent = root
  modelMenuOverlay.MouseButton1Click:Connect(function()
    if modelMenu then modelMenu:Destroy() modelMenu = nil end
    if modelMenuOverlay then modelMenuOverlay:Destroy() modelMenuOverlay = nil end
  end)
  
  modelMenu = Instance.new('Frame')
  modelMenu.Name = 'ModelMenu'
  modelMenu.BackgroundColor3 = Color3.fromRGB(25,26,28)
  modelMenu.BorderSizePixel = 0
  modelMenu.Size = UDim2.new(0,200,0,0)
  modelMenu.Position = UDim2.new(0,92,1,-76)
  modelMenu.AnchorPoint = Vector2.new(0,1)
  modelMenu.AutomaticSize = Enum.AutomaticSize.Y
  modelMenu.ZIndex = 200
  modelMenu.Parent = root
  corner(modelMenu, 8)
  
  local menuStroke = Instance.new('UIStroke')
  menuStroke.Color = Color3.fromRGB(50,52,58)
  menuStroke.Thickness = 1
  menuStroke.Parent = modelMenu
  
  local menuPad = Instance.new('UIPadding')
  menuPad.PaddingLeft = UDim.new(0,8)
  menuPad.PaddingRight = UDim.new(0,8)
  menuPad.PaddingTop = UDim.new(0,8)
  menuPad.PaddingBottom = UDim.new(0,8)
  menuPad.Parent = modelMenu
  
  local menuList = Instance.new('UIListLayout')
  menuList.Padding = UDim.new(0,4)
  menuList.SortOrder = Enum.SortOrder.LayoutOrder
  menuList.Parent = modelMenu
  
  -- Search box
  local searchBox = Instance.new('TextBox')
  searchBox.BackgroundColor3 = Color3.fromRGB(35,37,42)
  searchBox.BorderSizePixel = 0
  searchBox.Text = ''
  searchBox.PlaceholderText = 'Search models'
  searchBox.PlaceholderColor3 = Color3.fromRGB(110,110,115)
  searchBox.TextColor3 = Color3.fromRGB(220,221,222)
  searchBox.TextSize = 11
  searchBox.Size = UDim2.new(1,0,0,28)
  searchBox.ClearTextOnFocus = false
  searchBox.LayoutOrder = 0
  searchBox.ZIndex = 201
  searchBox.Parent = modelMenu
  corner(searchBox, 6)
  font(searchBox)
  
  local searchPad = Instance.new('UIPadding')
  searchPad.PaddingLeft = UDim.new(0,8)
  searchPad.Parent = searchBox
  
  -- Model list
  local models = {
    {name='Composer 1', model='composer-1', provider='Anthropic'},
    {name='Sonnet 4.5', model='claude-3.5-sonnet', provider='Anthropic'},
    {name='GPT-5 Codex', model='gpt-5-codex', provider='OpenAI'},
    {name='GPT-5', model='gpt-5', provider='OpenAI'},
    {name='Haiku 4.5', model='haiku-4.5', provider='Anthropic'},
    {name='Grok Code', model='grok-code', provider='xAI'},
    {name='Gemini 2.5 Pro', model='gemini-2.5-pro', provider='Gemini'},
    {name='Gemini 2.5 Flash', model='gemini-2.5-flash', provider='Gemini'}
  }
  
  -- Refresh all key statuses WITH VALIDATION
  local keyCache = {}
  for _, mdl in ipairs(models) do
    local hasValidKey = false
    pcall(function()
      local k = Store:getKey(mdl.provider)
      if k and k ~= '' and #k > 5 then
        -- Validate format (more flexible)
        if mdl.provider == 'OpenAI' then
          hasValidKey = k:match('^sk%-') ~= nil and #k > 20
        elseif mdl.provider == 'Anthropic' then
          hasValidKey = k:match('^sk%-ant%-') ~= nil and #k > 20
        elseif mdl.provider == 'Gemini' then
          hasValidKey = #k >= 20  -- More flexible for Gemini
        elseif mdl.provider == 'xAI' then
          hasValidKey = #k >= 20
        else
          hasValidKey = #k >= 15  -- More flexible for other providers
        end
      end
    end)
    keyCache[mdl.provider] = hasValidKey
  end
  
  for idx, mdl in ipairs(models) do
    local isSelected = (currentModel == mdl.model)
    local hasKey = keyCache[mdl.provider] or false
    
    local btn = Instance.new('TextButton')
    btn.BackgroundColor3 = isSelected and Color3.fromRGB(45,48,54) or Color3.fromRGB(25,26,28)
    btn.BorderSizePixel = 0
    btn.Size = UDim2.new(1,0,0,32)
    btn.AutoButtonColor = false
    btn.Text = ''
    btn.ZIndex = 201
    btn.LayoutOrder = idx
    btn.Parent = modelMenu
    corner(btn, 6)
    
    local label = Instance.new('TextLabel')
    label.BackgroundTransparency = 1
    label.Text = mdl.name
    label.TextColor3 = isSelected and Color3.fromRGB(220,221,222) or Color3.fromRGB(160,162,170)
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Size = UDim2.new(1,-40,1,0)
    label.Position = UDim2.new(0,8,0,0)
    label.ZIndex = 202
    label.Parent = btn
    font(label)
    
    -- API key indicator (always show, regardless of selection)
    local keyIcon = Instance.new('TextLabel')
    keyIcon.BackgroundTransparency = 1
    keyIcon.Text = hasKey and '✓' or '🔒'
    keyIcon.TextColor3 = hasKey and C.success or Color3.fromRGB(120,120,125)
    keyIcon.TextSize = 12
    keyIcon.Size = UDim2.new(0,20,1,0)
    keyIcon.Position = UDim2.new(1,-24,0,0)
    keyIcon.ZIndex = 202
    keyIcon.Parent = btn
    font(keyIcon)
    
    btn.MouseEnter:Connect(function()
      if not isSelected then
        btn.BackgroundColor3 = Color3.fromRGB(35,37,42)
      end
    end)
    btn.MouseLeave:Connect(function()
      if not isSelected then
        btn.BackgroundColor3 = Color3.fromRGB(25,26,28)
      end
    end)
    
    btn.MouseButton1Click:Connect(function()
      if not hasKey then
        -- Show API key dialog
        if modelMenu then modelMenu:Destroy() modelMenu = nil end
        if modelMenuOverlay then modelMenuOverlay:Destroy() modelMenuOverlay = nil end
        
        -- API Key Input Dialog
        local apiDialog = Instance.new('Frame')
        apiDialog.Name = 'APIDialog'
        apiDialog.BackgroundColor3 = Color3.fromRGB(20,20,22)
        apiDialog.BorderSizePixel = 0
        apiDialog.Size = UDim2.new(1,0,1,0)
        apiDialog.ZIndex = 300
        apiDialog.Parent = root
        
        local dialogPanel = Instance.new('Frame')
        dialogPanel.BackgroundColor3 = Color3.fromRGB(30,31,34)
        dialogPanel.BorderSizePixel = 0
        dialogPanel.Size = UDim2.new(0,360,0,180)
        dialogPanel.Position = UDim2.new(0.5,0,0.5,0)
        dialogPanel.AnchorPoint = Vector2.new(0.5,0.5)
        dialogPanel.ZIndex = 301
        dialogPanel.Parent = apiDialog
        corner(dialogPanel, 12)
        
        local dialogStroke = Instance.new('UIStroke')
        dialogStroke.Color = Color3.fromRGB(60,62,68)
        dialogStroke.Thickness = 1
        dialogStroke.Parent = dialogPanel
        
        local dialogTitle = Instance.new('TextLabel')
        dialogTitle.BackgroundTransparency = 1
        dialogTitle.Text = 'Enter ' .. mdl.provider .. ' API Key'
        dialogTitle.TextColor3 = Color3.fromRGB(220,221,222)
        dialogTitle.TextSize = 14
        dialogTitle.Size = UDim2.new(1,-40,0,30)
        dialogTitle.Position = UDim2.new(0,20,0,20)
        dialogTitle.TextXAlignment = Enum.TextXAlignment.Left
        dialogTitle.ZIndex = 302
        dialogTitle.Parent = dialogPanel
        font(dialogTitle, true)
        
        local dialogInput = Instance.new('TextBox')
        dialogInput.BackgroundColor3 = Color3.fromRGB(40,41,44)
        dialogInput.BorderSizePixel = 0
        dialogInput.PlaceholderText = 'sk-...'
        dialogInput.PlaceholderColor3 = Color3.fromRGB(110,110,115)
        dialogInput.TextColor3 = Color3.fromRGB(220,221,222)
        dialogInput.TextSize = 12
        dialogInput.Size = UDim2.new(1,-40,0,40)
        dialogInput.Position = UDim2.new(0,20,0,60)
        dialogInput.ClearTextOnFocus = false
        dialogInput.ZIndex = 302
        dialogInput.Parent = dialogPanel
        corner(dialogInput, 8)
        font(dialogInput)
        
        local inputPad = Instance.new('UIPadding')
        inputPad.PaddingLeft = UDim.new(0,12)
        inputPad.PaddingRight = UDim.new(0,12)
        inputPad.Parent = dialogInput
        
        local saveBtn = Instance.new('TextButton')
        saveBtn.BackgroundColor3 = C.accent
        saveBtn.BorderSizePixel = 0
        saveBtn.Text = 'Save Key'
        saveBtn.TextColor3 = Color3.fromRGB(255,255,255)
        saveBtn.TextSize = 12
        saveBtn.Size = UDim2.new(0,100,0,36)
        saveBtn.Position = UDim2.new(1,-120,1,-50)
        saveBtn.AutoButtonColor = false
        saveBtn.ZIndex = 302
        saveBtn.Parent = dialogPanel
        corner(saveBtn, 8)
        font(saveBtn, true)
        
        local cancelBtn = Instance.new('TextButton')
        cancelBtn.BackgroundColor3 = Color3.fromRGB(50,52,58)
        cancelBtn.BorderSizePixel = 0
        cancelBtn.Text = 'Cancel'
        cancelBtn.TextColor3 = Color3.fromRGB(180,180,185)
        cancelBtn.TextSize = 12
        cancelBtn.Size = UDim2.new(0,100,0,36)
        cancelBtn.Position = UDim2.new(1,-230,1,-50)
        cancelBtn.AutoButtonColor = false
        cancelBtn.ZIndex = 302
        cancelBtn.Parent = dialogPanel
        corner(cancelBtn, 8)
        font(cancelBtn)
        
        saveBtn.MouseButton1Click:Connect(function()
          local key = dialogInput.Text:gsub('^%s+',''):gsub('%s+$','')
          
          -- Validate API key format (more flexible)
          local isValid = false
          if mdl.provider == 'OpenAI' then
            isValid = key:match('^sk%-') ~= nil and #key > 20
          elseif mdl.provider == 'Anthropic' then
            isValid = key:match('^sk%-ant%-') ~= nil and #key > 20
          elseif mdl.provider == 'Gemini' then
            isValid = #key >= 20  -- More flexible for Gemini
          elseif mdl.provider == 'DeepSeek' then
            isValid = key:match('^sk%-') ~= nil and #key > 20
          elseif mdl.provider == 'xAI' then
            isValid = #key >= 20
          else
            isValid = #key >= 15
          end
          
          if isValid then
            Store:setKey(mdl.provider, key)
            currentModel = mdl.model
            Settings:set('last_model', mdl.model)
            Settings:set('last_model_name', mdl.name)
            modelDisplayBtn.Text = '⚡ ' .. mdl.name
            apiDialog:Destroy()
            task.wait(0.1)
            if updateAPILock then updateAPILock() end
          else
            -- Show error
            dialogTitle.Text = '❌ Invalid ' .. mdl.provider .. ' API Key'
            dialogTitle.TextColor3 = Color3.fromRGB(237,66,69)
            task.wait(1.5)
            dialogTitle.Text = 'Enter ' .. mdl.provider .. ' API Key'
            dialogTitle.TextColor3 = Color3.fromRGB(220,221,222)
          end
        end)
        
        cancelBtn.MouseButton1Click:Connect(function()
          apiDialog:Destroy()
        end)
        
        dialogInput:CaptureFocus()
      else
        -- Use cached key status
        if keyCache[mdl.provider] then
          currentModel = mdl.model
          Settings:set('last_model', mdl.model)
          Settings:set('last_model_name', mdl.name)
          modelDisplayBtn.Text = '⚡ ' .. mdl.name
          if modelMenu then modelMenu:Destroy() modelMenu = nil end
          if modelMenuOverlay then modelMenuOverlay:Destroy() modelMenuOverlay = nil end
          task.spawn(function()
            task.wait(0.1)
            if updateAPILock then updateAPILock() end
          end)
        else
          -- Key is invalid - show dialog
          if modelMenu then modelMenu:Destroy() modelMenu = nil end
          if modelMenuOverlay then modelMenuOverlay:Destroy() modelMenuOverlay = nil end
        end
      end
    end)
  end
end

modelDisplayBtn.MouseButton1Click:Connect(function()
  if modelMenu then
    if modelMenu then modelMenu:Destroy() modelMenu = nil end
    if modelMenuOverlay then modelMenuOverlay:Destroy() modelMenuOverlay = nil end
  else
    showModelMenu()
  end
end)


prompt=Instance.new('TextBox')
prompt.BackgroundTransparency=1
prompt.BorderSizePixel=0
prompt.Text=''
prompt.PlaceholderText='Plan, @ for context, / for commands'
prompt.TextColor3=Color3.fromRGB(225,225,230)
prompt.PlaceholderColor3=Color3.fromRGB(110,110,115)
prompt.TextSize=12
prompt.TextXAlignment=Enum.TextXAlignment.Left
prompt.ClearTextOnFocus=false
prompt.Size=UDim2.new(1,-220,1,0)
prompt.Position=UDim2.new(0,214,0,0)
prompt.Parent=promptContainer
font(prompt)

local promptPad=Instance.new('UIPadding')
promptPad.PaddingRight=UDim.new(0,14)
promptPad.Parent=prompt

-- API Lock indicator
local apiLockIcon = Instance.new('TextLabel')
apiLockIcon.Name = 'APILock'
apiLockIcon.BackgroundTransparency = 1
apiLockIcon.Text = '🔒'
apiLockIcon.TextColor3 = Color3.fromRGB(120,120,125)
apiLockIcon.TextSize = 16
apiLockIcon.Size = UDim2.new(0,24,1,0)
apiLockIcon.Position = UDim2.new(1,-40,0,0)
apiLockIcon.ZIndex = 12
apiLockIcon.Visible = false
apiLockIcon.Parent = promptContainer
font(apiLockIcon)

-- Function to update lock visibility (forward declared, will use sendBtn)
local updateAPILock

-- Message history with arrow keys
local messageHistory = {}
local historyIndex = 0

-- Forward declare send function
local send

-- Define updateAPILock with VALIDATION
updateAPILock = function()
  task.spawn(function()
    task.wait(0.05)
    if not currentModel then
      apiLockIcon.Visible = true
      return
    end
    local provider = providerOf(currentModel)
    if not provider then
      apiLockIcon.Visible = true
      return
    end
    
    -- Force refresh from store with VALIDATION
    local hasValidKey = false
    for i = 1, 3 do
      pcall(function()
        local key = Store:getKey(provider)
        if key and key ~= '' and #key > 5 then
          -- Validate format (more flexible)
          if provider == 'OpenAI' then
            hasValidKey = key:match('^sk%-') ~= nil and #key > 20
          elseif provider == 'Anthropic' then
            hasValidKey = key:match('^sk%-ant%-') ~= nil and #key > 20
          elseif provider == 'Gemini' then
            hasValidKey = #key >= 20  -- More flexible
          elseif provider == 'xAI' then
            hasValidKey = #key >= 20
          else
            hasValidKey = #key >= 15
          end
        end
      end)
      if hasValidKey then break end
      task.wait(0.05)
    end
    
    apiLockIcon.Visible = not hasValidKey
  end)
end

-- Restore last selected model on startup
if currentModel then
  local lastModelName = Settings:get('last_model_name', nil)
  if lastModelName then
    modelDisplayBtn.Text = '⚡ ' .. lastModelName
  end
  updateAPILock()
end

local UserInputService = game:GetService('UserInputService')

-- Enter to send with FocusLost
prompt.FocusLost:Connect(function(enterPressed)
  if enterPressed and send then
    send()
    -- Refocus after sending
    task.defer(function()
      prompt:CaptureFocus()
    end)
  end
end)

-- Arrow keys for message history
UserInputService.InputBegan:Connect(function(input, processed)
  if processed then return end
  if not prompt:IsFocused() then return end
  
  if input.KeyCode == Enum.KeyCode.Up then
    -- Previous message
    if #messageHistory > 0 and historyIndex < #messageHistory then
      historyIndex = historyIndex + 1
      prompt.Text = messageHistory[#messageHistory - historyIndex + 1]
      task.defer(function()
        prompt.CursorPosition = #prompt.Text + 1
      end)
    end
  elseif input.KeyCode == Enum.KeyCode.Down then
    -- Next message
    if historyIndex > 0 then
      historyIndex = historyIndex - 1
      if historyIndex == 0 then
        prompt.Text = ''
      else
        prompt.Text = messageHistory[#messageHistory - historyIndex + 1]
        task.defer(function()
          prompt.CursorPosition = #prompt.Text + 1
        end)
      end
    end
  end
end)



-- Layout update (dynamic based on bar height)
local function updateLayout()
  task.wait(0.1)
  local barHeight = bar.AbsoluteSize.Y
  bar.Position = UDim2.new(0,0,1,-barHeight)
  chat.Size = UDim2.new(1,-20,1,-(barHeight + 42))
  debugScroll.Size = UDim2.new(1,-20,1,-68)
end


-- Refresh API visibility (deprecated - no longer needed with new UI)
local function refreshAPI(showWelcome)
  -- Old function removed - users now select model from dropdown directly
  updateLayout()
end

-- Debug log system
local debugLogs = {}
local maxDebugLogs = 100

-- Add debug log entry
local function addDebugLog(logType, message, details, relatedInstance)
  -- Log types: 'info', 'success', 'error', 'action', 'warning'
  local icons = {
    info = '🔵',
    success = '✅',
    error = '❌',
    action = '⚡',
    warning = '⚠️'
  }
  
  local colors = {
    info = Color3.fromRGB(88,101,242),
    success = Color3.fromRGB(67,181,129),
    error = Color3.fromRGB(237,66,69),
    action = Color3.fromRGB(88,101,242),
    warning = Color3.fromRGB(250,166,26)
  }
  
  -- Limit log count
  if #debugLogs >= maxDebugLogs then
    local oldest = debugScroll:GetChildren()[1]
    if oldest and oldest:IsA('Frame') then
      oldest:Destroy()
    end
    table.remove(debugLogs, 1)
  end
  
  -- Create log entry
  local logEntry = Instance.new('Frame')
  logEntry.Size = UDim2.new(1, -8, 0, 60)
  logEntry.AutomaticSize = Enum.AutomaticSize.Y
  logEntry.BackgroundColor3 = Color3.fromRGB(35,35,40)
  logEntry.BorderSizePixel = 0
  logEntry.Parent = debugScroll
  corner(logEntry, 8)
  
  local pd = Instance.new('UIPadding')
  pd.PaddingLeft = UDim.new(0, 12)
  pd.PaddingTop = UDim.new(0, 10)
  pd.PaddingRight = UDim.new(0, 12)
  pd.PaddingBottom = UDim.new(0, 10)
  pd.Parent = logEntry
  
  -- Timestamp
  local timestamp = Instance.new('TextLabel')
  timestamp.BackgroundTransparency = 1
  timestamp.Text = os.date('%H:%M:%S')
  timestamp.TextSize = 9
  timestamp.TextColor3 = C.textMuted
  timestamp.Size = UDim2.new(0, 50, 0, 14)
  timestamp.Position = UDim2.new(1, -54, 0, 0)
  timestamp.TextXAlignment = Enum.TextXAlignment.Right
  timestamp.ZIndex = 2
  timestamp.Parent = logEntry
  font(timestamp)
  
  -- Icon + Type label
  local typeLabel = Instance.new('TextLabel')
  typeLabel.BackgroundTransparency = 1
  typeLabel.Text = icons[logType] .. ' ' .. logType:upper()
  typeLabel.TextColor3 = colors[logType]
  typeLabel.TextSize = 10
  typeLabel.Size = UDim2.new(0, 100, 0, 14)
  typeLabel.Position = UDim2.new(0, 0, 0, 0)
  typeLabel.TextXAlignment = Enum.TextXAlignment.Left
  typeLabel.Parent = logEntry
  font(typeLabel, true)
  
  -- Message
  local msgLabel = Instance.new('TextLabel')
  msgLabel.BackgroundTransparency = 1
  msgLabel.Text = message
  msgLabel.TextColor3 = C.text
  msgLabel.TextSize = 11
  msgLabel.Size = UDim2.new(1, -12, 0, 0)
  msgLabel.Position = UDim2.new(0, 0, 0, 16)
  msgLabel.TextWrapped = true
  msgLabel.TextXAlignment = Enum.TextXAlignment.Left
  msgLabel.TextYAlignment = Enum.TextYAlignment.Top
  msgLabel.AutomaticSize = Enum.AutomaticSize.Y
  msgLabel.Parent = logEntry
  font(msgLabel)
  
  -- Details (if provided)
  if details then
    local detailsLabel = Instance.new('TextLabel')
    detailsLabel.BackgroundTransparency = 1
    detailsLabel.Text = details
    detailsLabel.TextColor3 = C.textMuted
    detailsLabel.TextSize = 9
    detailsLabel.Size = UDim2.new(1, -12, 0, 0)
    detailsLabel.Position = UDim2.new(0, 0, 0, 32)
    detailsLabel.TextWrapped = true
    detailsLabel.TextXAlignment = Enum.TextXAlignment.Left
    detailsLabel.TextYAlignment = Enum.TextYAlignment.Top
    detailsLabel.AutomaticSize = Enum.AutomaticSize.Y
    detailsLabel.Parent = logEntry
    font(detailsLabel)
  end
  
  -- Repost button (copy button removed)
  local repostBtn = Instance.new('TextButton')
  repostBtn.Text = '↩️'
  repostBtn.BackgroundTransparency = 1
  repostBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
  repostBtn.BorderSizePixel = 0
  repostBtn.Size = UDim2.new(0, 24, 0, 24)
  repostBtn.Position = UDim2.new(1, -28, 1, -28)
  repostBtn.ZIndex = 5
  repostBtn.AutoButtonColor = false
  repostBtn.TextSize = 14
  repostBtn.Parent = logEntry
  font(repostBtn)
  
  repostBtn.MouseEnter:Connect(function()
    game:GetService('TweenService'):Create(repostBtn, TweenInfo.new(0.15), {TextColor3=C.accent}):Play()
  end)
  repostBtn.MouseLeave:Connect(function()
    game:GetService('TweenService'):Create(repostBtn, TweenInfo.new(0.15), {TextColor3=Color3.fromRGB(200,200,210)}):Play()
  end)
  
  repostBtn.MouseButton1Click:Connect(function()
    -- WhatsApp-style: Create quote frame above prompt
    switchTab('chat')
    
    -- Build quote text
    local quoteContent = string.format('🔖 [%s] %s', logType:upper(), message)
    if details and #details > 0 then
      quoteContent = quoteContent .. '\n' .. details
    end
    
    print('[DEBUG REPOST] quoteContent:', quoteContent)
    
    -- Create quote frame if not exists
    local quoteFrame = bar:FindFirstChild('QuoteFrame')
    if not quoteFrame then
      quoteFrame = Instance.new('Frame')
      quoteFrame.Name = 'QuoteFrame'
      quoteFrame.BackgroundColor3 = Color3.fromRGB(50,50,55)
      quoteFrame.BorderSizePixel=0
      quoteFrame.Size = UDim2.new(1,-20,0,0)
      quoteFrame.Position = UDim2.new(0,10,0,8)
      quoteFrame.AutomaticSize = Enum.AutomaticSize.Y
      quoteFrame.Visible = false
      quoteFrame.ZIndex = 5
      quoteFrame.Parent = bar
      corner(quoteFrame, 8)
      
      local quoteStroke = Instance.new('UIStroke')
      quoteStroke.Color = Color3.fromRGB(88,101,242)
      quoteStroke.Thickness = 2
      quoteStroke.Transparency = 0.5
      quoteStroke.Parent = quoteFrame
      
      local quotePad = Instance.new('UIPadding')
      quotePad.PaddingLeft = UDim.new(0,10)
      quotePad.PaddingTop = UDim.new(0,8)
      quotePad.PaddingRight = UDim.new(0,10)
      quotePad.PaddingBottom = UDim.new(0,8)
      quotePad.Parent = quoteFrame
      
      local quoteLabel = Instance.new('TextLabel')
      quoteLabel.Name = 'QuoteText'
      quoteLabel.BackgroundTransparency = 1
      quoteLabel.TextColor3 = Color3.fromRGB(220,221,222)
      quoteLabel.TextSize = 11
      quoteLabel.Size = UDim2.new(1,-30,0,0)
      quoteLabel.Position = UDim2.new(0,0,0,0)
      quoteLabel.TextWrapped = true
      quoteLabel.TextXAlignment = Enum.TextXAlignment.Left
      quoteLabel.TextYAlignment = Enum.TextYAlignment.Top
      quoteLabel.AutomaticSize = Enum.AutomaticSize.Y
      quoteLabel.ZIndex = 6
      quoteLabel.Parent = quoteFrame
      font(quoteLabel)
      
      local closeBtn = Instance.new('TextButton')
      closeBtn.Name = 'CloseQuote'
      closeBtn.BackgroundTransparency = 1
      closeBtn.Text = '×'
      closeBtn.TextColor3 = Color3.fromRGB(180,180,185)
      closeBtn.TextSize = 18
      closeBtn.Size = UDim2.new(0,20,0,20)
      closeBtn.Position = UDim2.new(1,-20,0,0)
      closeBtn.AutoButtonColor = false
      closeBtn.ZIndex = 6
      closeBtn.Parent = quoteFrame
      font(closeBtn, true)
      
      closeBtn.MouseEnter:Connect(function()
        closeBtn.TextColor3 = Color3.fromRGB(237,66,69)
      end)
      closeBtn.MouseLeave:Connect(function()
        closeBtn.TextColor3 = Color3.fromRGB(180,180,185)
      end)
      closeBtn.MouseButton1Click:Connect(function()
        quoteFrame.Visible = false
        promptRow.Position = UDim2.new(0,10,0,8)
      end)
    end
    
    -- Update quote content (always update, even if frame already exists)
    local quoteText = quoteFrame:FindFirstChild('QuoteText')
    if quoteText then
      quoteText.Text = quoteContent
      print('[DEBUG REPOST] Updated quoteText.Text to:', quoteText.Text)
      print('[DEBUG REPOST] quoteText.TextColor3:', quoteText.TextColor3)
      print('[DEBUG REPOST] quoteText.TextSize:', quoteText.TextSize)
      print('[DEBUG REPOST] quoteText.Size:', quoteText.Size)
      print('[DEBUG REPOST] quoteText.Visible:', quoteText.Visible)
      print('[DEBUG REPOST] quoteText.ZIndex:', quoteText.ZIndex)
      print('[DEBUG REPOST] quoteFrame.BackgroundColor3:', quoteFrame.BackgroundColor3)
    else
      print('[DEBUG REPOST] ERROR: QuoteText not found!')
    end
    
    -- Show quote frame and adjust layout
    quoteFrame.Visible = true
    print('[DEBUG REPOST] quoteFrame.Visible set to true')
    print('[DEBUG REPOST] quoteFrame.Size:', quoteFrame.Size)
    task.wait(0.1)
    local quoteHeight = quoteFrame.AbsoluteSize.Y
    print('[DEBUG REPOST] quoteHeight:', quoteHeight)
    promptRow.Position = UDim2.new(0,10,0,quoteHeight + 16)
    
    -- Focus prompt for reply
    prompt:CaptureFocus()
  end)
  
  -- OLD MODAL CODE (commented out for reference)
  --[[
  repostBtn.MouseButton1Click:Connect(function()
    local backdrop = Instance.new('Frame')
    backdrop.Name = 'RepostPopup'
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    backdrop.BackgroundTransparency = 0.4
    backdrop.ZIndex = 1000
    backdrop.Parent = root
    
    --[[local panel = Instance.new('Frame')
    panel.Size = UDim2.fromOffset(360, 280)
    panel.Position = UDim2.new(0.5, 0, 0.5, 0)
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    panel.BorderSizePixel = 0
    panel.ZIndex = 1001
    panel.Parent = backdrop
    corner(panel, 12)
    
    local panelStroke = Instance.new('UIStroke')
    panelStroke.Color = Color3.fromRGB(60, 60, 65)
    panelStroke.Thickness = 1
    panelStroke.Transparency = 0.5
    panelStroke.Parent = panel
    
    -- Title
    local title = Instance.new('TextLabel')
    title.BackgroundTransparency = 1
    title.Text = '💬 Repost to Chat'
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 13
    title.Size = UDim2.new(1, -40, 0, 24)
    title.Position = UDim2.new(0, 20, 0, 16)
    title.ZIndex = 1002
    title.Parent = panel
    font(title, true)
    
    -- Close button
    local closeBtn = Instance.new('TextButton')
    closeBtn.Text = '×'
    closeBtn.BackgroundTransparency = 1
    closeBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
    closeBtn.TextSize = 20
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -30, 0, 10)
    closeBtn.ZIndex = 1002
    closeBtn.AutoButtonColor = false
    closeBtn.Parent = panel
    font(closeBtn, true)
    
    closeBtn.MouseEnter:Connect(function()
      closeBtn.TextColor3 = Color3.fromRGB(237, 66, 69)
    end)
    closeBtn.MouseLeave:Connect(function()
      closeBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
    end)
    closeBtn.MouseButton1Click:Connect(function()
      backdrop:Destroy()
    end)
    
    -- Quote box (original log)
    local quoteBox = Instance.new('TextLabel')
    quoteBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    quoteBox.BorderSizePixel = 0
    quoteBox.Text = string.format('[%s] %s\n%s', logType:upper(), message, details or '')
    quoteBox.TextColor3 = C.textMuted
    quoteBox.TextSize = 10
    quoteBox.Size = UDim2.new(1, -40, 0, 80)
    quoteBox.Position = UDim2.new(0, 20, 0, 50)
    quoteBox.TextWrapped = true
    quoteBox.TextXAlignment = Enum.TextXAlignment.Left
    quoteBox.TextYAlignment = Enum.TextYAlignment.Top
    quoteBox.ZIndex = 1002
    quoteBox.Parent = panel
    corner(quoteBox, 6)
    font(quoteBox)
    
    local quotePad = Instance.new('UIPadding')
    quotePad.PaddingLeft = UDim.new(0, 8)
    quotePad.PaddingTop = UDim.new(0, 8)
    quotePad.PaddingRight = UDim.new(0, 8)
    quotePad.PaddingBottom = UDim.new(0, 8)
    quotePad.Parent = quoteBox
    
    local quoteStroke = Instance.new('UIStroke')
    quoteStroke.Color = colors[logType]
    quoteStroke.Thickness = 2
    quoteStroke.Transparency = 0.5
    quoteStroke.Parent = quoteBox
    
    -- Comment box
    local commentBox = Instance.new('TextBox')
    commentBox.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    commentBox.BorderSizePixel = 0
    commentBox.Text = ''
    commentBox.PlaceholderText = '✍️ Add your comment...'
    commentBox.TextColor3 = C.text
    commentBox.PlaceholderColor3 = C.textMuted
    commentBox.TextSize = 11
    commentBox.Size = UDim2.new(1, -40, 0, 80)
    commentBox.Position = UDim2.new(0, 20, 0, 140)
    commentBox.TextWrapped = true
    commentBox.TextXAlignment = Enum.TextXAlignment.Left
    commentBox.TextYAlignment = Enum.TextYAlignment.Top
    commentBox.MultiLine = true
    commentBox.ClearTextOnFocus = false
    commentBox.ZIndex = 1002
    commentBox.Parent = panel
    corner(commentBox, 6)
    font(commentBox)
    
    local commentPad = Instance.new('UIPadding')
    commentPad.PaddingLeft = UDim.new(0, 8)
    commentPad.PaddingTop = UDim.new(0, 8)
    commentPad.PaddingRight = UDim.new(0, 8)
    commentPad.PaddingBottom = UDim.new(0, 8)
    commentPad.Parent = commentBox
    
    local commentStroke = Instance.new('UIStroke')
    commentStroke.Color = Color3.fromRGB(60, 60, 65)
    commentStroke.Thickness = 1
    commentStroke.Transparency = 0.5
    commentStroke.Parent = commentBox
    
    -- Send button
    local sendBtn = Instance.new('TextButton')
    sendBtn.Text = '▶️ Send'
    sendBtn.BackgroundColor3 = C.accent
    sendBtn.BorderSizePixel = 0
    sendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    sendBtn.TextSize = 12
    sendBtn.Size = UDim2.new(1, -40, 0, 36)
    sendBtn.Position = UDim2.new(0, 20, 1, -52)
    sendBtn.ZIndex = 1002
    sendBtn.AutoButtonColor = false
    sendBtn.Parent = panel
    corner(sendBtn, 8)
    font(sendBtn, true)
    
    sendBtn.MouseEnter:Connect(function()
      game:GetService('TweenService'):Create(sendBtn, TweenInfo.new(0.1), {BackgroundColor3=Color3.fromRGB(98,111,252)}):Play()
    end)
    sendBtn.MouseLeave:Connect(function()
      game:GetService('TweenService'):Create(sendBtn, TweenInfo.new(0.1), {BackgroundColor3=C.accent}):Play()
    end)
    
    sendBtn.MouseButton1Click:Connect(function()
      local comment = commentBox.Text:gsub('^%s+', ''):gsub('%s+$', '')
      local repostMsg = string.format('📝 **Debug Log Repost**\n\n**Quote:** [%s] %s\n%s\n\n**Comment:** %s', 
        logType:upper(), message, details or '', comment ~= '' and comment or '(no comment)')
      
      -- Switch to chat tab and add message
      switchTab('chat')
      addMsg('You', repostMsg)
      backdrop:Destroy()
    end)
  end)]]
  -- END OLD MODAL CODE
  
  -- Add to logs array
  table.insert(debugLogs, {type=logType, message=message, details=details, instance=relatedInstance, timestamp=os.time()})
  
  -- Auto-scroll to bottom
  task.defer(function()
    task.wait()
    debugScroll.CanvasPosition = Vector2.new(0, debugScroll.AbsoluteCanvasSize.Y)
  end)
end

-- Chat functions
local mem={}

-- Extract code blocks from AI response
local function extractCode(text)
  local blocks = {}
  -- Try multiple patterns
  for code in text:gmatch('```lua\n(.-)\n```') do
    table.insert(blocks, code)
  end
  if #blocks == 0 then
    -- Fallback: no newlines
    for code in text:gmatch('```lua(.-)```') do
      table.insert(blocks, code:gsub('^%s+', ''):gsub('%s+$', ''))
    end
  end
  return blocks
end

-- Build GUI instances from AI code
local function buildGUIFromCode(code, guiName, intent)
  -- Parse AI code and create actual GUI instances
  -- Returns: screenGui, error
  
  local createdInstances = {}
  local mainScreenGui = nil
  
  -- Keep proxy mappings so we can unwrap on Parent assignments
  local proxyToInst = setmetatable({}, {__mode = 'k'})
  local instToProxy = setmetatable({}, {__mode = 'k'})
  
  -- Create sandbox environment
  local env = {}
  
  -- Provide core Roblox datatypes
  env.UDim2 = UDim2
  env.UDim = UDim
  env.Vector2 = Vector2
  env.Vector3 = Vector3
  env.Vector2int16 = Vector2int16
  env.Vector3int16 = Vector3int16
  env.Color3 = Color3
  env.ColorSequence = ColorSequence
  env.ColorSequenceKeypoint = ColorSequenceKeypoint
  env.NumberRange = NumberRange
  env.NumberSequence = NumberSequence
  env.NumberSequenceKeypoint = NumberSequenceKeypoint
  env.Rect = Rect
  env.Region3 = Region3
  env.Region3int16 = Region3int16
  env.Enum = Enum
  env.Faces = Faces
  env.Axes = Axes
  env.BrickColor = BrickColor
  env.CFrame = CFrame
  env.TweenInfo = TweenInfo
  env.PhysicalProperties = PhysicalProperties
  env.Ray = Ray
  
  -- Basic functions
  env.print = print
  env.warn = warn
  env.error = error
  env.typeof = typeof
  env.type = type
  env.wait = task.wait
  env.task = task
  env.pairs = pairs
  env.ipairs = ipairs
  env.next = next
  env.select = select
  env.tostring = tostring
  env.tonumber = tonumber
  
  local function isMock(v)
    return type(v) == 'table' and rawget(v, '__isNeuroviaMock') == true
  end
  
  local function unwrap(v)
    if type(v) == 'userdata' and proxyToInst[v] then return proxyToInst[v] end
    return v
  end
  
  -- Intercept Instance.new to track instances and wrap them
  env.Instance = {
    new = function(className)
      local inst = Instance.new(className)
      table.insert(createdInstances, inst)
      print('[GUI Builder] Created:', className, 'Total instances:', #createdInstances)
      
      -- Track the main ScreenGui
      if className == 'ScreenGui' and not mainScreenGui then
        mainScreenGui = inst
        print('[GUI Builder] Main ScreenGui set')
      end
      
      -- Create a wrapper proxy to intercept property assignments
      local proxy = newproxy(true)
      local mt = getmetatable(proxy)
      proxyToInst[proxy] = inst
      instToProxy[inst] = proxy
      
      mt.__index = function(_, key)
        local v = inst[key]
        -- We generally return raw Roblox values; if it's an Instance we can return its proxy
        if typeof(v) == 'Instance' and instToProxy[v] then
          return instToProxy[v]
        end
        return v
      end
      
      mt.__newindex = function(_, key, value)
        -- Unwrap proxy values
        local val = unwrap(value)
        if key == 'Parent' then
          if isMock(val) then
            print('[GUI Builder] Intercepted parent assignment to mock for:', className)
            return -- skip; we'll reparent later
          end
          local ok, err = pcall(function()
            inst.Parent = val
          end)
          if not ok then
            print('[GUI Builder] Parent assignment failed:', err)
          end
          return
        end
        -- Special handling for LocalScript/Script .Source
        if key == 'Source' and (className == 'LocalScript' or className == 'Script' or className == 'ModuleScript') then
          local ok2, err2 = pcall(function()
            inst.Source = val
          end)
          if not ok2 then
            print('[GUI Builder] Script source set failed:', err2)
          end
          return
        end
        local ok2, err2 = pcall(function()
          inst[key] = val
        end)
        if not ok2 then
          print('[GUI Builder] Property set failed on', className, key, ':', err2)
        end
      end
      
      return proxy
    end
  }
  
  -- Create smart mock that accepts parent assignments
  local mockPlayerGui = { __isNeuroviaMock = true }
  setmetatable(mockPlayerGui, {
    __index = function() return mockPlayerGui end,
    __newindex = function() end -- Silently ignore all assignments
  })
  
  -- Mock game services - allow access to all real services
  env.game = {
    GetService = function(_, serviceName)
      if serviceName == 'StarterGui' then
        return mockPlayerGui
      elseif serviceName == 'Players' then
        -- Mock Players service
        return {
          LocalPlayer = {
            WaitForChild = function(_, childName)
              return mockPlayerGui
            end,
            PlayerGui = mockPlayerGui
          }
        }
      end
      -- Allow access to real services (ReplicatedFirst, TweenService, etc.)
      local ok, service = pcall(function() return game:GetService(serviceName) end)
      if ok then return service else return mockPlayerGui end
    end,
    StarterGui = mockPlayerGui,
    Players = {
      LocalPlayer = {
        WaitForChild = function(_, childName)
          return mockPlayerGui
        end,
        PlayerGui = mockPlayerGui
      }
    },
    Workspace = workspace
  }
  
  -- Provide workspace directly
  env.workspace = workspace
  
  -- Compile and execute code
  local func, compileErr = loadstring(code)
  if not func then
    print('[GUI Builder] Compile error:', compileErr)
    addDebugLog('error', 'GUI Compilation Error', tostring(compileErr))
    return nil, 'Compile error: '..tostring(compileErr)
  end
  
  setfenv(func, env)
  local ok, execErr = pcall(func)
  if not ok then
    print('[GUI Builder] Execution error:', execErr)
    print('[GUI Builder] Code snippet:', code:sub(1, 300))
  end
  
  local function countEffectiveChildren(sg)
    local n = 0
    for _,d in ipairs(sg:GetDescendants()) do
      local cls = d.ClassName
      if cls ~= 'UICorner' and cls ~= 'UIStroke' and not cls:find('Constraint') and not cls:find('Layout') and not d:IsA('UIPadding') then
        n = n + 1
      end
    end
    return n
  end
  
  local function ensureMinimalStructure(sg, k)
    k = (k or (guiName or '')):lower()
    if k:find('loading') then
      local overlay = Instance.new('Frame')
      overlay.Name = 'Overlay'
      overlay.BackgroundColor3 = Color3.fromRGB(0,0,0)
      overlay.BackgroundTransparency = 0.4
      overlay.BorderSizePixel = 0
      overlay.Size = UDim2.new(1,0,1,0)
      overlay.Parent = sg
      local panel = Instance.new('Frame')
      panel.Name = 'Panel'
      panel.Size = UDim2.new(0.4,0,0.28,0)
      panel.AnchorPoint = Vector2.new(0.5,0.5)
      panel.Position = UDim2.new(0.5,0,0.5,0)
      panel.BackgroundColor3 = Color3.fromRGB(40,40,40)
      panel.BorderSizePixel = 0
      panel.Parent = sg
      local cr = Instance.new('UICorner') cr.CornerRadius = UDim.new(0,12) cr.Parent = panel
      local title = Instance.new('TextLabel')
      title.BackgroundTransparency = 1
      title.Size = UDim2.new(1,-20,0,36)
      title.Position = UDim2.new(0,10,0,12)
      title.Text = 'Loading...'
      title.Font = Enum.Font.GothamBold
      title.TextScaled = true
      title.TextColor3 = Color3.fromRGB(255,255,255)
      title.Parent = panel
      local barBg = Instance.new('Frame')
      barBg.Size = UDim2.new(0.8,0,0,8)
      barBg.Position = UDim2.new(0.1,0,0,64)
      barBg.BackgroundColor3 = Color3.fromRGB(60,60,60)
      barBg.BorderSizePixel = 0
      barBg.Parent = panel
      local barCR = Instance.new('UICorner') barCR.CornerRadius = UDim.new(0,4) barCR.Parent = barBg
      local bar = Instance.new('Frame')
      bar.Name = 'Progress'
      bar.Size = UDim2.new(0.2,0,1,0)
      bar.BackgroundColor3 = Color3.fromRGB(88,101,242)
      bar.BorderSizePixel = 0
      bar.Parent = barBg
      local bar2CR = Instance.new('UICorner') bar2CR.CornerRadius = UDim.new(0,4) bar2CR.Parent = bar
    elseif k:find('settings') then
      local panel = Instance.new('Frame')
      panel.Name = 'SettingsPanel'
      panel.Size = UDim2.new(0.45,0,0.6,0)
      panel.AnchorPoint = Vector2.new(0.5,0.5)
      panel.Position = UDim2.new(0.5,0,0.5,0)
      panel.BackgroundColor3 = Color3.fromRGB(40,40,40)
      panel.BorderSizePixel = 0
      panel.Parent = sg
      local cr = Instance.new('UICorner') cr.CornerRadius = UDim.new(0,12) cr.Parent = panel
      local list = Instance.new('UIListLayout') list.Padding=UDim.new(0,8) list.FillDirection=Enum.FillDirection.Vertical list.HorizontalAlignment=Enum.HorizontalAlignment.Center list.Parent=panel
      local pad = Instance.new('UIPadding') pad.PaddingLeft=UDim.new(0,12) pad.PaddingRight=UDim.new(0,12) pad.PaddingTop=UDim.new(0,12) pad.PaddingBottom=UDim.new(0,12) pad.Parent=panel
      for i=1,5 do
        local row = Instance.new('Frame') row.Size=UDim2.new(1,0,0,36) row.BackgroundColor3=Color3.fromRGB(55,55,55) row.BorderSizePixel=0 row.Parent=panel local rcr=Instance.new('UICorner') rcr.CornerRadius=UDim.new(0,8) rcr.Parent=row
        local lbl = Instance.new('TextLabel') lbl.BackgroundTransparency=1 lbl.Text='Setting '..i lbl.TextScaled=true lbl.TextColor3=Color3.fromRGB(230,230,230) lbl.Size=UDim2.new(0.7,0,1,0) lbl.Position=UDim2.new(0,10,0,0) lbl.Font=Enum.Font.Gotham lbl.Parent=row
        local btn = Instance.new('TextButton') btn.Text='Toggle' btn.Size=UDim2.new(0.25,0,0.8,0) btn.Position=UDim2.new(0.73,0,0.1,0) btn.BackgroundColor3=Color3.fromRGB(88,101,242) btn.TextColor3=Color3.new(1,1,1) btn.AutoButtonColor=false btn.BorderSizePixel=0 btn.Parent=row local bcr=Instance.new('UICorner') bcr.CornerRadius=UDim.new(0,6) bcr.Parent=btn
      end
    elseif k:find('inventory') then
      local panel = Instance.new('Frame') panel.Name='InventoryPanel' panel.Size=UDim2.new(0.6,0,0.65,0) panel.AnchorPoint=Vector2.new(0.5,0.5) panel.Position=UDim2.new(0.5,0,0.5,0) panel.BackgroundColor3=Color3.fromRGB(40,40,40) panel.BorderSizePixel=0 panel.Parent=sg local cr=Instance.new('UICorner') cr.CornerRadius=UDim.new(0,12) cr.Parent=panel
      local gridHolder = Instance.new('ScrollingFrame') gridHolder.Size=UDim2.new(1,-24,1,-24) gridHolder.Position=UDim2.new(0,12,0,12) gridHolder.BackgroundTransparency=1 gridHolder.BorderSizePixel=0 gridHolder.CanvasSize=UDim2.new() gridHolder.AutomaticCanvasSize=Enum.AutomaticSize.Y gridHolder.ScrollBarThickness=6 gridHolder.Parent=panel
      local pad = Instance.new('UIPadding') pad.PaddingLeft=UDim.new(0,6) pad.PaddingRight=UDim.new(0,6) pad.PaddingTop=UDim.new(0,6) pad.PaddingBottom=UDim.new(0,6) pad.Parent=gridHolder
      local grid = Instance.new('UIGridLayout') grid.CellSize=UDim2.new(0,120,0,140) grid.CellPadding=UDim2.new(0,8,0,8) grid.FillDirectionMaxCells=4 grid.SortOrder=Enum.SortOrder.LayoutOrder grid.Parent=gridHolder
      for i=1,12 do
        local card = Instance.new('Frame') card.Size=UDim2.new(0,120,0,140) card.BackgroundColor3=Color3.fromRGB(55,55,55) card.BorderSizePixel=0 card.Parent=gridHolder local ccr=Instance.new('UICorner') ccr.CornerRadius=UDim.new(0,8) ccr.Parent=card
        local img = Instance.new('ImageLabel') img.BackgroundColor3=Color3.fromRGB(35,35,35) img.Size=UDim2.new(1,-12,0,90) img.Position=UDim2.new(0,6,0,6) img.BorderSizePixel=0 img.Parent=card local icr=Instance.new('UICorner') icr.CornerRadius=UDim.new(0,6) icr.Parent=img
        local name = Instance.new('TextLabel') name.BackgroundTransparency=1 name.Text='Item '..i name.TextScaled=true name.TextColor3=Color3.fromRGB(235,235,235) name.Font=Enum.Font.Gotham name.Size=UDim2.new(1,-12,0,36) name.Position=UDim2.new(0,6,0,96) name.Parent=card
      end
    end
  end
  
  -- Use the ScreenGui that was created
  if mainScreenGui then
    mainScreenGui.Name = guiName or mainScreenGui.Name
    
    print('[GUI Builder] Post-processing', #createdInstances, 'instances')
    
    -- Parent all orphan instances to the ScreenGui
    local orphanCount = 0
    for _, inst in ipairs(createdInstances) do
      if inst ~= mainScreenGui and inst.Parent == nil then
        orphanCount = orphanCount + 1
        print('[GUI Builder] Orphan found:', inst.ClassName)
        local ok = pcall(function()
          inst.Parent = mainScreenGui
        end)
        if ok then
          print('[GUI Builder] ✓ Parented orphan')
        else
          print('[GUI Builder] ✗ Failed to parent orphan')
        end
      end
    end
    print('[GUI Builder] Orphans processed:', orphanCount)
    
    -- Also find instances parented to mock tables and reparent them
    local mockCount = 0
    for _, inst in ipairs(createdInstances) do
      if inst ~= mainScreenGui then
        local parent = inst.Parent
        if parent and type(parent) == 'table' and not parent.ClassName then
          mockCount = mockCount + 1
          print('[GUI Builder] Mock-parented found:', inst.ClassName)
          pcall(function()
            inst.Parent = mainScreenGui
          end)
        end
      end
    end
    print('[GUI Builder] Mock-parented processed:', mockCount)
    
    -- Fallback: synthesize minimal structure if too few effective children
    if countEffectiveChildren(mainScreenGui) < 3 then
      ensureMinimalStructure(mainScreenGui, intent or guiName)
    end
    
    return mainScreenGui, nil
  else
    -- No ScreenGui created, make one and parent everything to it
    local sg = Instance.new('ScreenGui')
    sg.Name = guiName or 'NeuroviaGUI'
    sg.ResetOnSpawn = false
    
    for _, inst in ipairs(createdInstances) do
      if inst.Parent == nil then
        pcall(function()
          inst.Parent = sg
        end)
      end
    end
    
    -- Also ensure there is at least a basic structure
    if countEffectiveChildren(sg) < 3 then
      ensureMinimalStructure(sg, intent or guiName)
    end
    
    return sg, nil
  end
end


-- Auto-apply code to project with SMART HIERARCHY DETECTION
local function autoApply(code, scriptName)
  scriptName = scriptName or 'NeuroviaScript'
  
  print('[AUTO APPLY] Analyzing code for:', scriptName)
  print('[AUTO APPLY] Code preview:', code:sub(1, 200))
  
  -- INTELLIGENT CODE ANALYSIS
  local codeLower = code:lower()
  local isGUICode = codeLower:find('screengui') or codeLower:find('frame') or codeLower:find('textlabel') or codeLower:find('textbutton') or codeLower:find('imagelabel')
  local hasLocalScript = codeLower:find('localscript')
  local hasServerLogic = codeLower:find('playeradded') or codeLower:find('remoteevent') or (codeLower:find('script') and not hasLocalScript)
  local isToolCode = codeLower:find('tool') and codeLower:find('handle')
  local isWorkspaceCode = codeLower:find('workspace') or codeLower:find('part') or codeLower:find('model')
  
  print('[AUTO APPLY] Analysis - GUI:', isGUICode, 'LocalScript:', hasLocalScript, 'Server:', hasServerLogic, 'Tool:', isToolCode, 'Workspace:', isWorkspaceCode)
  
  -- Try to execute the code directly (it might create its own hierarchy)
  local success = pcall(function()
    local func, err = loadstring(code)
    if func then
      local env = getfenv(func)
      env.game = game
      env.workspace = workspace
      env.script = {Parent = game:GetService('ServerScriptService')}
      setfenv(func, env)
      func()
      print('[AUTO APPLY] Code executed successfully')
    else
      print('[AUTO APPLY] Code compilation error:', err)
    end
  end)
  
  if success then
    return true, 'Code executed and hierarchy created'
  end
  
  -- Fallback: Create as script in appropriate location
  local allScripts = getAllScripts()
  local target = nil
  
  for _,s in ipairs(allScripts) do
    if s.name:lower():find(scriptName:lower()) then
      target = s.instance
      break
    end
  end
  
  if target then
    -- Update existing
    Store:pushUndo({script=target, old=target.Source})
    local ok,err = pcall(function()
      target.Source = code
    end)
    if ok then
      return true, 'Updated '..target.Name..' in '..target.Parent.Name
    else
      return false, 'Failed to update: '..tostring(err)
    end
  else
    -- Determine correct location based on code analysis
    local parent, scriptType
    
    if isGUICode and hasLocalScript then
      -- GUI code with LocalScript → StarterGui
      parent = game:GetService('StarterGui')
      scriptType = 'LocalScript'
      print('[AUTO APPLY] Detected GUI code → StarterGui + LocalScript')
    elseif isToolCode then
      -- Tool code → StarterPack
      parent = game:GetService('StarterPack')
      scriptType = 'Script'
      print('[AUTO APPLY] Detected Tool code → StarterPack')
    elseif isWorkspaceCode then
      -- Workspace objects → Workspace
      parent = workspace
      scriptType = 'Script'
      print('[AUTO APPLY] Detected Workspace code → Workspace')
    elseif hasServerLogic then
      -- Server logic → ServerScriptService
      parent = game:GetService('ServerScriptService')
      scriptType = 'Script'
      print('[AUTO APPLY] Detected Server logic → ServerScriptService')
    else
      -- Default: ServerScriptService
      parent = game:GetService('ServerScriptService')
      scriptType = 'Script'
      print('[AUTO APPLY] Default location → ServerScriptService')
    end
    
    -- Create script
    local newScript
    if scriptType == 'LocalScript' then
      newScript = Instance.new('LocalScript')
    else
      newScript = Instance.new('Script')
    end
    
    newScript.Name = scriptName
    newScript.Source = code
    newScript.Parent = parent
    
    print('[AUTO APPLY] Created', scriptType, 'in', parent.Name)
    return true, 'Created '..scriptType..' "'..scriptName..'" in '..parent.Name
  end
end

local function addMsg(who,txt,err,locations)
  local fr=Instance.new('Frame')
  fr.Size=UDim2.new(1,-8,0,0)
  fr.AutomaticSize=Enum.AutomaticSize.Y
  fr.BackgroundColor3=err and C.danger or (who=='You' and C.bubbleUser or C.bubbleAI)
  fr.BorderSizePixel=0
  fr.Parent=chat
  corner(fr,10)
  
  -- Add icon
  local icon=Instance.new('ImageLabel')
  icon.Size=UDim2.new(0,28,0,28)
  icon.Position=UDim2.new(0,8,0,8)
  icon.BackgroundTransparency=1
  icon.Parent=fr
  corner(icon,14)
  
  if who=='You' then
    -- User's Roblox avatar
    local ok,userId=pcall(function()
      return game:GetService('StudioService'):GetUserId()
    end)
    if ok and userId and userId>0 then
      icon.Image='rbxthumb://type=AvatarHeadShot&id='..userId..'&w=150&h=150'
    else
      -- Fallback to default user icon
      icon:Destroy()
      local userIcon=Instance.new('TextLabel')
      userIcon.Size=UDim2.new(0,28,0,28)
      userIcon.Position=UDim2.new(0,8,0,8)
      userIcon.BackgroundTransparency=1
      userIcon.Text='👤'
      userIcon.TextSize=20
      userIcon.Parent=fr
    end
    
    -- Add undo button to user messages (for next AI response)
    fr.Name='UserMessage_'..os.time()
    
  elseif who=='Neurovia' then
    -- AI icon (Roblox asset)
    icon:Destroy()
    local aiIcon=Instance.new('ImageLabel')
    aiIcon.Size=UDim2.new(0,28,0,28)
    aiIcon.Position=UDim2.new(0,8,0,8)
    aiIcon.BackgroundTransparency=1
    aiIcon.Image='rbxassetid://73590799266237'
    aiIcon.ScaleType=Enum.ScaleType.Fit
    aiIcon.ZIndex=10
    aiIcon.Parent=fr
  else
    icon:Destroy()
  end
  
  -- Add undo and location buttons if locations provided
  if locations and #locations > 0 then
    -- Find the previous user message and add undo button to it
    local userMsg = nil
    for i = #chat:GetChildren(), 1, -1 do
      local child = chat:GetChildren()[i]
      if child:IsA('Frame') and child.Name:find('UserMessage_') then
        userMsg = child
        break
      end
    end
    
    if userMsg then
      -- Adjust user message padding to make room for buttons ONLY if locations exist
      local userPadding = userMsg:FindFirstChild('UIPadding')
      if userPadding then
        userPadding.PaddingBottom = UDim.new(0, 40)
      end
      
      -- Add undo button to user's message (below timestamp, right aligned)
      local undoBtn = Instance.new('TextButton')
      undoBtn.Text='Geri Al'
      undoBtn.BackgroundTransparency=1
      undoBtn.TextColor3=Color3.fromRGB(200,200,210)
      undoBtn.BorderSizePixel=0
      undoBtn.Size=UDim2.new(0,50,0,16)
      undoBtn.Position=UDim2.new(1,-54,0,20)
      undoBtn.ZIndex=5
      undoBtn.AutoButtonColor=false
      undoBtn.Parent=userMsg
      undoBtn.TextSize=9
      font(undoBtn,true)
      
      undoBtn.MouseEnter:Connect(function()
        game:GetService('TweenService'):Create(undoBtn, TweenInfo.new(0.15), {TextColor3=Color3.fromRGB(237,66,69)}):Play()
      end)
      undoBtn.MouseLeave:Connect(function()
        game:GetService('TweenService'):Create(undoBtn, TweenInfo.new(0.15), {TextColor3=Color3.fromRGB(200,200,210)}):Play()
      end)
      
      undoBtn.MouseButton1Click:Connect(function()
        -- Undo this specific action by deleting created instances
        local deleted = 0
        for _,loc in ipairs(locations) do
          if loc.instance and loc.instance.Parent then
            pcall(function()
              loc.instance:Destroy()
              deleted = deleted + 1
            end)
          end
        end
        
        if deleted > 0 then
          undoBtn.Text='✓'
          undoBtn.TextColor3=C.success
          task.wait(0.5)
          undoBtn:Destroy()
          
          -- Show notification in AI message
          local msgTxt=fr:FindFirstChild('MessageText')
          if msgTxt then
            msgTxt.Text=txt..'\n\n❌ Undone - '..deleted..' item'..(deleted>1 and 's' or '')..' removed'
            msgTxt.TextColor3=C.textMuted
          end
        end
      end)
    end
    
    -- Adjust AI message padding to make room for buttons ONLY if locations exist
    local aiPadding = fr:FindFirstChild('UIPadding')
    if aiPadding then
      aiPadding.PaddingBottom = UDim.new(0, 40)
    end
    
    -- Location button (below timestamp, left aligned to match undo button)
    local locBtn = Instance.new('TextButton')
    locBtn.Text='Göster'
    locBtn.BackgroundTransparency=1
    locBtn.TextColor3=C.accent
    locBtn.BorderSizePixel=0
    locBtn.TextSize=9
    locBtn.Size=UDim2.new(0,50,0,16)
    locBtn.Position=UDim2.new(1,-54,0,20)
    locBtn.ZIndex=5
    locBtn.AutoButtonColor=false
    locBtn.Parent=fr
    font(locBtn,true)
    
    locBtn.MouseEnter:Connect(function()
      game:GetService('TweenService'):Create(locBtn, TweenInfo.new(0.15), {TextColor3=Color3.fromRGB(120,140,255)}):Play()
    end)
    locBtn.MouseLeave:Connect(function()
      game:GetService('TweenService'):Create(locBtn, TweenInfo.new(0.15), {TextColor3=C.accent}):Play()
    end)
    
    locBtn.MouseButton1Click:Connect(function()
      -- Select the created objects in explorer
      local toSelect = {}
      for _,loc in ipairs(locations) do
        if loc.instance and loc.instance.Parent then
          table.insert(toSelect, loc.instance)
        end
      end
      if #toSelect > 0 then
        Selection:Set(toSelect)
        locBtn.Text='✓'
        locBtn.TextColor3=C.success
        task.wait(1)
        locBtn.Text='Göster'
        locBtn.TextColor3=C.accent
      end
    end)
  end
  
  local pd=Instance.new('UIPadding')
  pd.PaddingLeft=UDim.new(0,14)
  pd.PaddingTop=UDim.new(0,10)
  pd.PaddingRight=UDim.new(0,14)
  pd.PaddingBottom=UDim.new(0,10)
  pd.Parent=fr
  
  -- Check if user is a developer
  local isDeveloper = false
  if who == 'You' then
    local ok, userId = pcall(function()
      return game:GetService('StudioService'):GetUserId()
    end)
    if ok and userId then
      for _, devId in ipairs(DEVELOPERS) do
        if userId == devId then
          isDeveloper = true
          break
        end
      end
    end
  end
  
  local lbl=Instance.new('TextLabel')
  lbl.BackgroundTransparency=1
  lbl.Text=who
  lbl.TextColor3=C.textMuted
  lbl.TextSize=9
  lbl.Size=UDim2.new(1,-46,0,12)
  lbl.Position=UDim2.new(0,44,0,0)
  lbl.TextXAlignment=Enum.TextXAlignment.Left
  lbl.Parent=fr
  
  -- Developer badge (separate from username)
  if isDeveloper then
    local devBadge = Instance.new('TextLabel')
    devBadge.BackgroundTransparency=1
    devBadge.Text='[DEVELOPER]'
    devBadge.TextColor3=Color3.fromRGB(255,120,120)
    devBadge.TextSize=9
    devBadge.Size=UDim2.new(0,90,0,12)
    devBadge.Position=UDim2.new(0,44+lbl.TextBounds.X+5,0,0)
    devBadge.TextXAlignment=Enum.TextXAlignment.Left
    devBadge.Parent=fr
    font(devBadge,true)
  end
  -- Timestamp
  local timestamp = Instance.new('TextLabel')
  timestamp.BackgroundTransparency = 1
  timestamp.Text = os.date('%H:%M:%S')
  timestamp.TextSize = 9
  timestamp.TextColor3 = C.textMuted
  timestamp.Size = UDim2.new(0, 50, 0, 14)
  timestamp.Position = UDim2.new(1, -54, 0, 2)
  timestamp.TextXAlignment = Enum.TextXAlignment.Right
  timestamp.ZIndex=2
  timestamp.Parent = fr
  font(timestamp)
  font(lbl,true)
  
  local body=Instance.new('TextLabel')
  body.Name='MessageText'
  body.BackgroundTransparency=1
  body.Text=txt
  body.TextColor3=C.text
  body.TextSize=12
  body.Size=UDim2.new(1,-56,0,0)
  body.Position=UDim2.new(0,44,0,14)
  body.TextWrapped=true
  body.TextXAlignment=Enum.TextXAlignment.Left
  body.TextYAlignment=Enum.TextYAlignment.Top
  body.AutomaticSize=Enum.AutomaticSize.Y
  body.Parent=fr
  font(body)
  
  -- Auto-detect and apply code blocks
  if who == 'Neurovia' and not err then
    local codes = extractCode(txt)
    if #codes > 0 then
      local applyBtn = Instance.new('TextButton')
      applyBtn.Text='⚡ Apply to Project'
      applyBtn.BackgroundColor3=C.success
      applyBtn.TextColor3=Color3.fromRGB(255,255,255)
      applyBtn.BorderSizePixel=0
      applyBtn.Size=UDim2.new(0,130,0,28)
      applyBtn.Position=UDim2.new(1,-140,1,-34)
      applyBtn.Parent=fr
      corner(applyBtn,6)
      font(applyBtn,true)
      
      applyBtn.MouseButton1Click:Connect(function()
        applyBtn.Text='⏳ Applying...'
        applyBtn.BackgroundColor3=C.textMuted
        applyBtn.Active=false
        
        task.spawn(function()
          local results = {}
          for i,code in ipairs(codes) do
            -- Smart naming
            local scriptName = 'GeneratedScript'
            if code:find('ScreenGui') or code:find('TextLabel') or code:find('Frame') then
              scriptName = 'UIScript'
            elseif code:find('PlayerAdded') or code:find('Players') then
              scriptName = 'PlayerScript'
            elseif code:find('Part') or code:find('workspace') then
              scriptName = 'WorldScript'
            end
            if #codes > 1 then scriptName = scriptName..i end
            
            local ok,msg = autoApply(code, scriptName)
            table.insert(results, (ok and '✅ ' or '❌ ')..msg)
            task.wait(0.1)
          end
          
          applyBtn.Text='✅ Applied!'
          applyBtn.BackgroundColor3=C.success
          addMsg('System', '\n'..table.concat(results,'\n'), false)
          
          task.wait(2)
          applyBtn:Destroy()
        end)
      end)
    end
  end
  
  task.defer(function()
    task.wait()
    chat.CanvasPosition=Vector2.new(0, chat.AbsoluteCanvasSize.Y)
  end)
end

-- Progress bar for AI processing
local progressBar = nil
local function showProgress(modeText)
  if progressBar then progressBar:Destroy() end
  
  progressBar = Instance.new('Frame')
  progressBar.Name = 'ProgressBar'
  progressBar.Size = UDim2.new(1, -20, 0, 48)
  progressBar.Position = UDim2.new(0, 10, 1, -128)
  progressBar.BackgroundColor3 = Color3.fromRGB(35,35,40)
  progressBar.BorderSizePixel = 0
  progressBar.Parent = root
  progressBar.ZIndex = 150
  corner(progressBar, 8)
  
  local pd = Instance.new('UIPadding')
  pd.PaddingLeft = UDim.new(0, 14)
  pd.PaddingTop = UDim.new(0, 10)
  pd.PaddingRight = UDim.new(0, 14)
  pd.PaddingBottom = UDim.new(0, 10)
  pd.Parent = progressBar
  
  local statusLabel = Instance.new('TextLabel')
  statusLabel.BackgroundTransparency = 1
  statusLabel.Text = modeText
  statusLabel.TextColor3 = Color3.fromRGB(200,200,205)
  statusLabel.TextSize = 11
  statusLabel.Size = UDim2.new(1, -24, 0, 14)
  statusLabel.Position = UDim2.new(0, 0, 0, 0)
  statusLabel.TextXAlignment = Enum.TextXAlignment.Left
  statusLabel.Parent = progressBar
  font(statusLabel, true)
  
  local barBg = Instance.new('Frame')
  barBg.Size = UDim2.new(1, 0, 0, 4)
  barBg.Position = UDim2.new(0, 0, 1, -4)
  barBg.BackgroundColor3 = Color3.fromRGB(50,50,55)
  barBg.BorderSizePixel = 0
  barBg.Parent = progressBar
  corner(barBg, 2)
  
  local barFill = Instance.new('Frame')
  barFill.Size = UDim2.new(0, 0, 1, 0)
  barFill.BackgroundColor3 = Color3.fromRGB(88,101,242)
  barFill.BorderSizePixel = 0
  barFill.Parent = barBg
  corner(barFill, 2)
  
  -- Animate
  task.spawn(function()
    local tween = game:GetService('TweenService'):Create(
      barFill,
      TweenInfo.new(1.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
      {Size = UDim2.new(1, 0, 1, 0)}
    )
    tween:Play()
  end)
  
  return progressBar
end

local function hideProgress()
  if progressBar then
    progressBar:Destroy()
    progressBar = nil
  end
end

-- Ask Mode: Deep research with context
local function executeAskMode(userMsg)
  prompt.Text=''
  table.insert(messageHistory, userMsg)
  if #messageHistory > 50 then table.remove(messageHistory, 1) end
  historyIndex = 0
  addDebugLog('action', 'Ask Mode', 'Deep research query')
  
  -- Add user message bubble
  addMsg('You', userMsg)
  
  if not currentModel then
    addMsg('System','⚠️ Please select a model first',true)
    return
  end
  
  local prov=providerOf(currentModel)
  if not prov then
    addMsg('System','⚠️ Invalid model configuration',true)
    return
  end
  local key=Store:getKey(prov)
  if not key then
    addMsg('System','⚠️ API key required',true)
    return
  end
  
  -- Show progress
  showProgress('💡 Researching and analyzing...')
  
  -- Enhanced prompt for research
  local researchPrompt = string.format([[
You are a knowledgeable assistant for Roblox development. Provide a detailed, well-researched answer.

User Question: %s

Guidelines:
- Be thorough and comprehensive
- Explain concepts clearly
- Provide examples where relevant
- Cite best practices
- Consider different perspectives
]], userMsg)
  
  mem=mem or {}
  table.insert(mem, {role='user', content=researchPrompt})
  
  local ai=AI.new(currentModel)
  local ok,res=ai:chat(mem,key)
  hideProgress()
  
  if ok then
    table.insert(mem, {role='assistant', content=res})
    addMsg('Neurovia', '💡 ' .. res)
    addDebugLog('success', 'Research Complete', 'Answer provided')
  else
    addMsg('Neurovia', '❌ ' .. tostring(res), true)
    addDebugLog('error', 'Research Failed', tostring(res))
  end
  
  task.defer(function()
    task.wait()
    chat.CanvasPosition = Vector2.new(0, chat.AbsoluteCanvasSize.Y)
  end)
end

-- Send message
local sending=false

send = function()
  if sending then return end
  local msg = prompt.Text:gsub('^%s+',''):gsub('%s+$','')
  if #msg==0 then return end
  
  -- Check if there's an active quote
  local quoteFrame = bar:FindFirstChild('QuoteFrame')
  local fullMsg = msg
  
  if quoteFrame and quoteFrame.Visible then
    -- Include quote in message
    local quoteText = quoteFrame:FindFirstChild('QuoteText')
    if quoteText then
      fullMsg = '**[QUOTE]**\n' .. quoteText.Text .. '\n\n**[REPLY]**\n' .. msg
    end
    -- Hide quote frame
    quoteFrame.Visible = false
    promptRow.Position = UDim2.new(0,10,0,8)
  end
  
  -- MODE-AWARE EXECUTION
  if currentMode == 'Ask' then
    -- Ask mode: Deep research with context
    executeAskMode(fullMsg)
    return
  end
  
  -- Agent mode: Continue with normal execution below
  
  prompt.Text=''
  
  -- Add to message history
  table.insert(messageHistory, msg)
  if #messageHistory > 50 then table.remove(messageHistory, 1) end
  historyIndex = 0  -- Reset history position
  
  if not currentModel then
    addMsg('System','⚠️ Please select a model first',true)
    return
  end
  
  mem=mem or {}
  table.insert(mem, {role='user', content=fullMsg})
  if #mem>100 then table.remove(mem,1) end
  
  addMsg('You', fullMsg)
  
  local prov=providerOf(currentModel)
  if not prov then
    addMsg('System','⚠️ Invalid model configuration',true)
    return
  end
  local key=Store:getKey(prov)
  
  if not key or #key<10 then
    addMsg('System','⚠️ No API key for '..prov..'. Click model selector to add key.',true)
    return
  end
  
  -- Step 3: Generate plan with ENHANCED CONTEXT
  local planPrompt = string.format('You are an EXPERT Roblox Studio architect. Analyze this task and create a detailed execution plan.\n\nTask: %s\n\n🎯 CRITICAL RULES:\n1. UNDERSTAND THE TASK TYPE:\n   - If task is about GUI/UI then Steps MUST create ScreenGui in StarterGui + LocalScript\n   - If task is about gameplay/server logic then Steps MUST create Script in ServerScriptService\n   - If task is about tools/weapons then Steps MUST create Tool in StarterPack\n   - If task is about world objects then Steps MUST create Model/Parts in Workspace\n\n2. CORRECT HIERARCHY:\n   GUI Example: StarterGui -> ScreenGui -> Frame/TextLabel/TextButton + LocalScript\n   NEVER put GUI scripts in ServerScriptService!\n   Server Example: ServerScriptService -> Script (for game logic)\n   Workspace -> Model/Parts (for physical objects)\n\n3. OUTPUT FORMAT (ONLY step titles):\nStep 1: [Short title]\nStep 2: [Short title]\nStep 3: [Short title]\n\nExample for Create health bar GUI:\nStep 1: Create ScreenGui in StarterGui\nStep 2: Add Frame and TextLabel UI elements\nStep 3: Create LocalScript for health tracking\n\nExample for Create shop system:\nStep 1: Create RemoteEvent in ReplicatedStorage\nStep 2: Create server Script in ServerScriptService\nStep 3: Create UI in StarterGui with LocalScript\n\nNow break down the task into 3-5 clear steps:', userMsg)
  
  mem=mem or {}
  table.insert(mem, {role='user', content=planPrompt})
  
  local ai=AI.new(currentModel)
  local ok,res=ai:chat(mem,key)
  
  -- Remove loading
  if loadingFrame then loadingFrame:Destroy() end
  
  if not ok then
    addMsg('Neurovia', '❌ Plan generation failed: ' .. tostring(res), true)
    addDebugLog('error', 'Plan Failed', tostring(res))
    return
  end
  
  print('[PLAN MODE] Response:', res)
  table.insert(mem, {role='assistant', content=res})
  
  -- Step 4: Parse steps (clean markdown)
  local steps = {}
  local cleanText = res:gsub('%*%*', ''):gsub('##%s*', ''):gsub('%*', '')
  
  for stepLine in cleanText:gmatch('[^\n]+') do
    local num, title = stepLine:match('^Step%s*(%d+):%s*(.+)')
    if num and title then
      title = title:gsub('^%s+', ''):gsub('%s+$', ''):gsub('[%.!?]+$', '')
      table.insert(steps, {num=tonumber(num), title=title})
      print('[PLAN MODE] Step', num, ':', title)
    end
  end
  
  if #steps == 0 then
    addMsg('Neurovia', '❌ Could not parse plan steps', true)
    addDebugLog('error', 'Parse Failed', 'No steps found in response')
    return
  end
  
  -- Step 5: Display plan (Modern style with circular checkboxes)
  local planFrame = Instance.new('Frame')
  planFrame.Name = 'PlanDisplay'
  planFrame.Size = UDim2.new(1, -8, 0, 0)
  planFrame.AutomaticSize = Enum.AutomaticSize.Y
  planFrame.BackgroundColor3 = Color3.fromRGB(35,35,40)
  planFrame.BorderSizePixel = 0
  planFrame.Parent = chat
  corner(planFrame, 8)
  activePlanFrame = planFrame -- Track for New button
  
  local planPad = Instance.new('UIPadding')
  planPad.PaddingLeft = UDim.new(0, 14)
  planPad.PaddingTop = UDim.new(0, 12)
  planPad.PaddingRight = UDim.new(0, 14)
  planPad.PaddingBottom = UDim.new(0, 54)
  planPad.Parent = planFrame
  
  local planList = Instance.new('UIListLayout')
  planList.Padding = UDim.new(0, 6)
  planList.SortOrder = Enum.SortOrder.LayoutOrder
  planList.Parent = planFrame
  
  -- Header
  local header = Instance.new('TextLabel')
  header.BackgroundTransparency = 1
  header.Text = '📋 Plan'
  header.TextColor3 = Color3.fromRGB(220,221,222)
  header.TextSize = 13
  header.Size = UDim2.new(1, 0, 0, 20)
  header.TextXAlignment = Enum.TextXAlignment.Left
  header.LayoutOrder = 0
  header.Parent = planFrame
  font(header, true)
  
  -- Steps with circular checkboxes
  local stepFrames = {}
  local stepLabels = {}
  local stepCheckboxes = {}
  
  for i, step in ipairs(steps) do
    local stepContainer = Instance.new('Frame')
    stepContainer.BackgroundTransparency = 1
    stepContainer.BorderSizePixel = 0
    stepContainer.Size = UDim2.new(1, 0, 0, 28)
    stepContainer.LayoutOrder = i
    stepContainer.Parent = planFrame
    
    -- Circular checkbox (empty circle initially)
    local checkbox = Instance.new('Frame')
    checkbox.Name = 'Checkbox'
    checkbox.BackgroundColor3 = Color3.fromRGB(45,45,50)
    checkbox.BorderSizePixel = 0
    checkbox.Size = UDim2.new(0, 18, 0, 18)
    checkbox.Position = UDim2.new(0, 2, 0, 5)
    checkbox.Parent = stepContainer
    
    local cbCorner = Instance.new('UICorner')
    cbCorner.CornerRadius = UDim.new(1, 0)
    cbCorner.Parent = checkbox
    
    local cbStroke = Instance.new('UIStroke')
    cbStroke.Color = Color3.fromRGB(88,101,242)
    cbStroke.Thickness = 1.5
    cbStroke.Transparency = 0.5
    cbStroke.Parent = checkbox
    
    -- Checkmark (hidden initially)
    local checkmark = Instance.new('TextLabel')
    checkmark.Name = 'Checkmark'
    checkmark.BackgroundTransparency = 1
    checkmark.Text = '✓'
    checkmark.TextColor3 = Color3.fromRGB(255,255,255)
    checkmark.TextSize = 14
    checkmark.Size = UDim2.new(1, 0, 1, 0)
    checkmark.Visible = false
    checkmark.Parent = checkbox
    font(checkmark, true)
    
    -- Step text
    local stepLabel = Instance.new('TextLabel')
    stepLabel.Name = 'StepLabel'
    stepLabel.BackgroundTransparency = 1
    stepLabel.Text = step.title
    stepLabel.TextColor3 = Color3.fromRGB(200,200,205)
    stepLabel.TextSize = 11
    stepLabel.Size = UDim2.new(1, -28, 1, 0)
    stepLabel.Position = UDim2.new(0, 26, 0, 0)
    stepLabel.TextXAlignment = Enum.TextXAlignment.Left
    stepLabel.TextYAlignment = Enum.TextYAlignment.Center
    stepLabel.TextWrapped = false
    stepLabel.TextTruncate = Enum.TextTruncate.AtEnd
    stepLabel.Parent = stepContainer
    font(stepLabel)
    
    table.insert(stepFrames, stepContainer)
    table.insert(stepLabels, stepLabel)
    table.insert(stepCheckboxes, {checkbox=checkbox, checkmark=checkmark, stroke=cbStroke})
  end
  
  -- Buttons row
  local btnRow = Instance.new('Frame')
  btnRow.BackgroundTransparency = 1
  btnRow.Size = UDim2.new(1, 0, 0, 32)
  btnRow.Position = UDim2.new(0, 0, 1, -42)
  btnRow.Parent = planFrame
  
  -- New button (left side) - to add more steps
  local newBtn = Instance.new('TextButton')
  newBtn.BackgroundColor3 = Color3.fromRGB(50,52,58)
  newBtn.BorderSizePixel = 0
  newBtn.Text = '+ New'
  newBtn.TextColor3 = Color3.fromRGB(200,200,205)
  newBtn.TextSize = 11
  newBtn.Size = UDim2.new(0, 80, 0, 32)
  newBtn.Position = UDim2.new(0, 0, 0, 0)
  newBtn.AutoButtonColor = false
  newBtn.Parent = btnRow
  corner(newBtn, 6)
  font(newBtn, true)
  
  newBtn.MouseButton1Click:Connect(function()
    -- Prompt user to add a new step
    prompt:CaptureFocus()
    prompt.PlaceholderText = 'Add new step to plan...'
    print('[PLAN MODE] New button clicked - ready for new step')
  end)
  
  -- Apply button (right side)
  local applyBtn = Instance.new('TextButton')
  applyBtn.BackgroundColor3 = Color3.fromRGB(88,101,242)
  applyBtn.BorderSizePixel = 0
  applyBtn.Text = '▶ Apply'
  applyBtn.TextColor3 = Color3.fromRGB(255,255,255)
  applyBtn.TextSize = 11
  applyBtn.Size = UDim2.new(0, 100, 0, 32)
  applyBtn.Position = UDim2.new(1, -100, 0, 0)
  applyBtn.AutoButtonColor = false
  applyBtn.Parent = btnRow
  corner(applyBtn, 6)
  font(applyBtn, true)
  
  print('[PLAN MODE] Apply and New buttons created')
  
  -- Apply button interaction
  applyBtn.MouseButton1Click:Connect(function()
    print('[PLAN MODE] Apply button clicked!')
    
    if applyBtn.Text ~= '▶ Apply' then 
      print('[PLAN MODE] Button already processing')
      return 
    end
    
    applyBtn.Text = '⏳ Applying...'
    applyBtn.BackgroundColor3 = Color3.fromRGB(60,60,65)
    applyBtn.Active = false
    newBtn.Visible = false
    
    print('[PLAN MODE] Starting execution')
    addDebugLog('action', 'Applying Plan', string.format('Executing %d steps', #steps))
    
    task.spawn(function()
      local ctx = getContext()
      
      -- Execute each step
      for i, step in ipairs(steps) do
        print('[PLAN MODE] Executing step', i, ':', step.title)
        
        -- Animate checkbox (blue pulse)
        if stepCheckboxes[i] then
          local cb = stepCheckboxes[i]
          cb.checkbox.BackgroundColor3 = Color3.fromRGB(88,101,242)
          cb.stroke.Transparency = 0
        end
        
        -- ENHANCED AI PROMPT with strict hierarchy rules
        local stepPrompt = string.format('%s\n\n🎯 EXECUTE THIS STEP:\nStep %d: %s\n\n🚨 CRITICAL HIERARCHY RULES:\n\n1. GUI/UI Tasks (health bar, menu, HUD, button):\n   ✅ CORRECT: Create ScreenGui in StarterGui + LocalScript inside ScreenGui\n   ❌ WRONG: Creating Script in ServerScriptService for GUI\n\n2. Server Logic Tasks (shop, admin, data):\n   ✅ CORRECT: Create Script in ServerScriptService\n   ❌ WRONG: Using LocalScript for server logic\n\n3. World Objects (parts, models, NPCs):\n   ✅ CORRECT: Create Model/Parts in Workspace + Script for behavior\n\n📝 OUTPUT FORMAT:\nProvide ONLY complete, working Roblox Lua code in ```lua``` blocks.\nCode must create proper hierarchy automatically (StarterGui for GUI, ServerScriptService for server logic).\nNo explanations outside code blocks.\n\nNow execute: %s', ctx, i, step.title, step.title)
          
        local stepMem = {{
          role='system', 
          content='You are an EXPERT Roblox developer. You MUST follow Roblox Studio hierarchy rules perfectly. GUI code goes in StarterGui with LocalScript, server logic goes in ServerScriptService with Script.'
        }}
        table.insert(stepMem, {role='user', content=stepPrompt})
        
        local stepAI = AI.new(currentModel)
        local stepOk, stepRes = stepAI:chat(stepMem, key)
        
        if stepOk then
          print('[PLAN MODE] Step', i, 'response received')
          local codes = extractCode(stepRes)
          print('[PLAN MODE] Found', #codes, 'code blocks')
          
          if #codes > 0 then
            local stepSuccess = false
            for _, code in ipairs(codes) do
              local scriptName = string.format('PlanStep%d_%s', i, step.title:gsub('%s+', ''))
              local applyOk, msg = autoApply(code, scriptName)
              if applyOk then
                print('[PLAN MODE] Step', i, 'applied:', msg)
                addDebugLog('success', string.format('Step %d Applied', i), msg)
                stepSuccess = true
              else
                print('[PLAN MODE] Step', i, 'failed:', msg)
                addDebugLog('error', string.format('Step %d Failed', i), msg)
              end
            end
            
            -- Animate completion
            if stepSuccess and stepCheckboxes[i] and stepLabels[i] then
              local cb = stepCheckboxes[i]
              local label = stepLabels[i]
              
              -- Fill checkbox with green checkmark
              cb.checkbox.BackgroundColor3 = Color3.fromRGB(67,181,129)
              cb.stroke.Color = Color3.fromRGB(67,181,129)
              cb.stroke.Transparency = 0
              cb.checkmark.Visible = true
              
              -- Strikethrough effect
              label.TextColor3 = Color3.fromRGB(120,120,125)
              label.TextStrokeTransparency = 0
              label.TextStrokeColor3 = Color3.fromRGB(120,120,125)
              
              -- Add strikethrough line
              local strike = Instance.new('Frame')
              strike.BackgroundColor3 = Color3.fromRGB(120,120,125)
              strike.BorderSizePixel = 0
              strike.Size = UDim2.new(0, 0, 0, 1)
              strike.Position = UDim2.new(0, 26, 0.5, 0)
              strike.Parent = stepFrames[i]
              
              -- Animate strikethrough
              game:GetService('TweenService'):Create(
                strike,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad),
                {Size = UDim2.new(1, -30, 0, 1)}
              ):Play()
            else
              -- Mark as failed
              if stepCheckboxes[i] then
                local cb = stepCheckboxes[i]
                cb.checkbox.BackgroundColor3 = Color3.fromRGB(237,66,69)
                cb.stroke.Color = Color3.fromRGB(237,66,69)
              end
            end
          else
            print('[PLAN MODE] Step', i, 'no code found')
            addDebugLog('warning', string.format('Step %d', i), 'No code found in response')
            if stepCheckboxes[i] then
              local cb = stepCheckboxes[i]
              cb.checkbox.BackgroundColor3 = Color3.fromRGB(250,166,26)
              cb.stroke.Color = Color3.fromRGB(250,166,26)
            end
          end
        else
          print('[PLAN MODE] Step', i, 'request failed:', stepRes)
          addDebugLog('error', 'Step Failed', tostring(stepRes))
          if stepCheckboxes[i] then
            local cb = stepCheckboxes[i]
            cb.checkbox.BackgroundColor3 = Color3.fromRGB(237,66,69)
            cb.stroke.Color = Color3.fromRGB(237,66,69)
          end
          break
        end
        
        task.wait(0.5)
      end
      
      print('[PLAN MODE] Execution complete')
      applyBtn.Text = '✅ Done'
      applyBtn.BackgroundColor3 = Color3.fromRGB(67,181,129)
      addDebugLog('success', 'Plan Complete', 'All steps executed')
    end)
  end)
  
  addDebugLog('success', 'Plan Created', #steps .. ' steps identified')
  
  task.defer(function()
    task.wait()
    chat.CanvasPosition = Vector2.new(0, chat.AbsoluteCanvasSize.Y)
  end)
end

-- Ask Mode: Deep research with context
local function executeAskMode(userMsg)
  prompt.Text=''
  table.insert(messageHistory, userMsg)
  if #messageHistory > 50 then table.remove(messageHistory, 1) end
  historyIndex = 0
  addDebugLog('action', 'Ask Mode', 'Deep research query')
  
  -- Add user message bubble
  addMsg('You', userMsg)
  
  if not currentModel then
    addMsg('System','⚠️ Please select a model first',true)
    return
  end
  
  local prov=providerOf(currentModel)
  if not prov then
    addMsg('System','⚠️ Invalid model configuration',true)
    return
  end
  local key=Store:getKey(prov)
  if not key then
    addMsg('System','⚠️ API key required',true)
    return
  end
  
  -- Show progress
  showProgress('💡 Researching and analyzing...')
  
  -- Enhanced prompt for research
  local researchPrompt = string.format([[
You are a knowledgeable assistant for Roblox development. Provide a detailed, well-researched answer.

User Question: %s

Guidelines:
- Be thorough and comprehensive
- Explain concepts clearly
- Provide examples where relevant
- Cite best practices
- Consider different perspectives
]], userMsg)
  
  mem=mem or {}
  table.insert(mem, {role='user', content=researchPrompt})
  
  local ai=AI.new(currentModel)
  local ok,res=ai:chat(mem,key)
  hideProgress()
  
  if ok then
    table.insert(mem, {role='assistant', content=res})
    addMsg('Neurovia', '💡 ' .. res)
    addDebugLog('success', 'Research Complete', 'Answer provided')
  else
    addMsg('Neurovia', '❌ ' .. tostring(res), true)
    addDebugLog('error', 'Research Failed', tostring(res))
  end
  
  task.defer(function()
    task.wait()
    chat.CanvasPosition = Vector2.new(0, chat.AbsoluteCanvasSize.Y)
  end)
end

-- Send message
local sending=false

send = function()
  if sending then return end
  local msg = prompt.Text:gsub('^%s+',''):gsub('%s+$','')
  if #msg==0 then return end
  
  -- Check if there's an active quote
  local quoteFrame = bar:FindFirstChild('QuoteFrame')
  local fullMsg = msg
  
  if quoteFrame and quoteFrame.Visible then
    -- Include quote in message
    local quoteText = quoteFrame:FindFirstChild('QuoteText')
    if quoteText then
      fullMsg = '**[QUOTE]**\n' .. quoteText.Text .. '\n\n**[REPLY]**\n' .. msg
    end
    -- Hide quote frame
    quoteFrame.Visible = false
    promptRow.Position = UDim2.new(0,10,0,8)
  end
  
  -- MODE-AWARE EXECUTION
  if currentMode == 'Ask' then
    -- Ask mode: Deep research with context
    executeAskMode(fullMsg)
    return
  end
  
  -- Agent mode: Continue with normal execution below
  
  prompt.Text=''
  
  -- Add to message history
  table.insert(messageHistory, msg)
  if #messageHistory > 50 then table.remove(messageHistory, 1) end
  historyIndex = 0  -- Reset history position
  
  if not currentModel then
    addMsg('System','⚠️ Please select a model first',true)
    return
  end
  
  mem=mem or {}
  table.insert(mem, {role='user', content=fullMsg})
  if #mem>100 then table.remove(mem,1) end
  
  addMsg('You', fullMsg)
  
  local prov=providerOf(currentModel)
  if not prov then
    addMsg('System','⚠️ Invalid model configuration',true)
    return
  end
  local key=Store:getKey(prov)
  
  if not key or #key<10 then
    addMsg('System','⚠️ No API key for '..prov..'. Click model selector to add key.',true)
    return
  end
  
  -- ============ UNIVERSAL FIX SYSTEM ============
  -- Detect user intent from message + conversation
  local intent = 'create' -- default
  local targetName = nil
  local targetInstance = nil
  local targetType = nil -- 'gui', 'script', 'part', 'model', etc.
  
  -- Scan all services for potential fix targets
  local existingObjects = {} -- {name -> {instance, type, path}}
  
  -- Scan StarterGui for GUIs
  local starterGui = game:GetService('StarterGui')
  for _, child in ipairs(starterGui:GetChildren()) do
    if child:IsA('ScreenGui') then
      existingObjects[child.Name] = {instance=child, type='gui', path=child:GetFullName()}
    end
  end
  
  -- Scan all services for Scripts/Models/Parts
  for _, serviceName in ipairs(ALL_SERVICES) do
    local ok, svc = pcall(function() return game:GetService(serviceName) end)
    if ok and svc then
      for _, desc in ipairs(svc:GetDescendants()) do
        if desc:IsA('Script') or desc:IsA('LocalScript') or desc:IsA('ModuleScript') then
          existingObjects[desc.Name] = {instance=desc, type='script', path=desc:GetFullName()}
        elseif desc:IsA('Model') and desc.Parent ~= workspace then
          existingObjects[desc.Name] = {instance=desc, type='model', path=desc:GetFullName()}
        elseif desc:IsA('Part') or desc:IsA('MeshPart') then
          existingObjects[desc.Name] = {instance=desc, type='part', path=desc:GetFullName()}
        elseif desc:IsA('Folder') then
          existingObjects[desc.Name] = {instance=desc, type='folder', path=desc:GetFullName()}
        end
      end
    end
  end
  
  -- Scan recent conversation for object names
  local recentNames = {}
  for i = math.max(1, #mem-10), #mem do
    -- Extract quoted names, CamelCase, or specific patterns
    for match in mem[i].content:gmatch('([%w]+GUI)') do recentNames[match] = true end
    for match in mem[i].content:gmatch('([%w]+Script)') do recentNames[match] = true end
    for match in mem[i].content:gmatch('([%w]+Model)') do recentNames[match] = true end
    for match in mem[i].content:gmatch('"([%w_]+)"') do recentNames[match] = true end
  end
  
  -- ============ SUPER INTENT DETECTION ============
  local msgLower = msg:lower()
  
  -- ============ SMART INTENT CLASSIFICATION ============
  
  -- NO MORE SHORTCUTS - All messages go through AI for context-aware responses
  
  -- Priority 1: CONVERSATION/QUESTION intent (user just asking, learning, chatting)
  local isConversation = 
    (msgLower:find('nedir') or msgLower:find('what is') or msgLower:find('ne demek') or 
     msgLower:find('anlat') or msgLower:find('explain') or msgLower:find('nasıl çalışır') or 
     msgLower:find('how does') or msgLower:find('neden') or msgLower:find('why') or
     msgLower:find('fark') or msgLower:find('difference') or msgLower:find('öğren') or msgLower:find('learn') or
     msgLower:find('nasıl yapılır') or msgLower:find('how to') or msgLower:find('ne zaman') or msgLower:find('when')) and
    not (msgLower:find('yap') or msgLower:find('oluştur') or msgLower:find('create') or msgLower:find('make'))
  
  if isConversation then
    intent = 'conversation'
    print('[Intent] CONVERSATION detected - user asking a question')
  end
  
  -- Priority 2: FIX intent (expanded detection)
  local isFixIntent = not isConversation and (
    msgLower:find('düzelt') or msgLower:find('fix') or msgLower:find('çalışmıyor') or 
    msgLower:find('not working') or msgLower:find('broken') or
    msgLower:find('değiştir') or msgLower:find('change') or msgLower:find('güncelle') or msgLower:find('update') or
    msgLower:find('hata') or msgLower:find('error') or msgLower:find('bug') or msgLower:find('bozuk') or
    msgLower:find('yanlış') or msgLower:find('wrong') or msgLower:find('eksik') or msgLower:find('missing') or
    msgLower:find('donuyor') or msgLower:find('freezing') or msgLower:find('lag') or msgLower:find('crash') or
    msgLower:find('optimize') or msgLower:find('improve') or msgLower:find('geliştir') or msgLower:find('iyileştir') or
    msgLower:find('sorun') or msgLower:find('problem') or msgLower:find('issue') or
    msgLower:find('incele') or msgLower:find('analyze') or msgLower:find('kontrol') or msgLower:find('check'))
  
  if isFixIntent then
    intent = 'fix'
    -- Priority 1: Check existing objects by exact name match in message
    for objName, objData in pairs(existingObjects) do
      if msgLower:find(objName:lower()) then
        targetName = objName
        targetInstance = objData.instance
        targetType = objData.type
        print('[Intent] FIX detected (exact):', targetName, '(', targetType, ')')
        break
      end
    end
    
    -- Priority 2: Check by keyword match (partial name)
    if not targetName then
      for objName, objData in pairs(existingObjects) do
        local keyword = objName:lower():gsub('gui', ''):gsub('script', ''):gsub('model', '')
        if #keyword > 2 and msgLower:find(keyword) then
          targetName = objName
          targetInstance = objData.instance
          targetType = objData.type
          print('[Intent] FIX detected (keyword):', targetName, '(', targetType, ')')
          break
        end
      end
    end
    
    -- Priority 3: Check conversation history for recently mentioned objects
    if not targetName then
      for name, _ in pairs(recentNames) do
        if existingObjects[name] then
          targetName = name
          targetInstance = existingObjects[name].instance
          targetType = existingObjects[name].type
          print('[Intent] FIX from history:', targetName)
          break
        end
      end
    end
    
    -- Priority 4: If still no target but fix keywords detected, try to infer from most recent creation
    if not targetName then
      -- Get most recently created/mentioned object
      for i = #mem, math.max(1, #mem-3), -1 do
        if mem[i].role == 'assistant' then
          for objName, objData in pairs(existingObjects) do
            if mem[i].content:find(objName) then
              targetName = objName
              targetInstance = objData.instance
              targetType = objData.type
              print('[Intent] FIX inferred from recent:', targetName)
              break
            end
          end
          if targetName then break end
        end
      end
    end
  end
  
  -- Detect delete intent
  if msgLower:find('sil') or msgLower:find('kaldır') or msgLower:find('delete') or msgLower:find('remove') then
    intent = 'delete'
    for objName, objData in pairs(existingObjects) do
      if msgLower:find(objName:lower()) then
        targetName = objName
        targetInstance = objData.instance
        targetType = objData.type
        break
      end
    end
  end
  
  -- ============ SUPER AI PROMPT ============
  local sysPrompt = [[
!!NEUROVIA CODER - ULTRA ADVANCED ASSISTANT!!
You are Neurovia AI: The ULTIMATE Roblox development assistant. You are an expert in:
- Roblox Studio architecture & hierarchy
- Lua programming & best practices
- GUI design & user experience
- Debugging & error resolution
- Game systems & mechanics

!! LANGUAGE DETECTION !!
IMPORTANT: Detect user's language from their message.
- If user writes in TURKISH (contains: ç,ğ,ı,ö,ş,ü or Turkish words), respond in TURKISH.
- If user writes in ENGLISH, respond in ENGLISH.
- Match the user's language for ALL responses, explanations, and comments in code.

Turkish words to detect: oluştur, yap, düzelt, hata, güncelle, ekle, sil, nasıl, nedir
English words to detect: create, make, fix, error, update, add, delete, how, what

═══════════════════════════════════════════════════════
🏛️ ROBLOX STUDIO HIERARCHY MASTERY
═══════════════════════════════════════════════════════

KEY SERVICES & THEIR PURPOSE:

🌍 **Workspace**
- Physical 3D world container
- Use for: Parts, Models, Maps, Terrain, NPCs, physical objects
- Scripts: Use regular Script (server-side)
- Example: Building a house, spawning enemies, map objects

💾 **ReplicatedStorage**
- Shared storage accessible by both client & server
- Use for: ModuleScripts, shared assets, RemoteEvents/RemoteFunctions
- Perfect for: Reusable code, shared data, client-server communication

🎮 **StarterGui**
- Container for UI elements shown to players
- Use for: ScreenGuis, Menus, HUDs, Notifications
- Scripts: Use LocalScript (client-side only)
- Example: Health bar, inventory UI, settings menu

⚙️ **ServerScriptService**
- Server-side script container (not replicated to clients)
- Use for: Game logic, data management, security-critical code
- Scripts: Use Script (server-side)
- Example: Player data, shop system, admin commands

👥 **StarterPlayer**
- Contains StarterCharacterScripts & StarterPlayerScripts
- Use for: Character customization, player-specific scripts
- Scripts: LocalScripts in StarterPlayerScripts

🎽 **StarterPack**
- Tools given to players on spawn
- Use for: Weapons, tools, equipment

📦 **ServerStorage**
- Server-only storage (never replicated to clients)
- Use for: Temporary objects, cloneable templates, secure assets

SCRIPT TYPES:
• **Script** → Runs on SERVER. Use in Workspace, ServerScriptService
• **LocalScript** → Runs on CLIENT. Use in StarterGui, StarterPlayerScripts, ReplicatedFirst
• **ModuleScript** → Reusable code library. Use in ReplicatedStorage, ServerStorage

COMMON MISTAKES TO AVOID:
❌ LocalScript in ServerScriptService (won't run)
❌ Script in StarterGui (won't run)
❌ Accessing LocalPlayer from server Script
✅ Always use correct script type for location

═══════════════════════════════════════════════════════
🔍 ADVANCED ERROR DETECTION & DEBUGGING
═══════════════════════════════════════════════════════

When user reports an error, you are a MASTER DEBUGGER. Follow this process:

1. **ANALYZE THE ERROR PATTERN**
   - "Script not running" → Check script type & location mismatch
   - "Nil value" → Check WaitForChild, verify object exists
   - "Attempt to index nil" → Object doesn't exist or wrong path
   - "Expected 'end'" → Missing end keyword (count functions)
   - "Infinite yield" → WaitForChild for non-existent object

2. **COMMON BUG PATTERNS**
   ❌ `script.Parent.Button` → Use `script.Parent:WaitForChild('Button')`
   ❌ `Part.Position = 5` → Use `Part.Position = Vector3.new(5,5,5)`
   ❌ Missing `local` keyword → Creates global variable (bad practice)
   ❌ `if x = 5 then` → Use `==` for comparison
   ❌ Tweening Transparency on Frame with visible=false → Won't show

3. **SCRIPT LOCATION ERRORS**
   - LocalScript in ServerScriptService? → Move to StarterPlayerScripts
   - Script trying to access PlayerGui? → Use LocalScript
   - RemoteEvent not firing? → Check if it exists in ReplicatedStorage

4. **FIX APPROACH**
   - Read the FULL existing code
   - Identify root cause (don't just patch symptoms)
   - Output COMPLETE fixed version
   - Explain what was wrong in simple terms

═══════════════════════════════════════════════════════
🧠 INTERNAL THINKING PROCESS (NEVER SHOW TO USER)
═══════════════════════════════════════════════════════

❌ CRITICAL: DO NOT include phase headers, brackets, or analysis text in your response!
✅ Think through these phases silently, then output ONLY the final answer.

Before responding, SILENTLY analyze:

【PHASE 1: INTENT CLASSIFICATION】
Question to answer: "What is the user REALLY asking for?"
- CONVERSATION: User asking question, seeking explanation, learning concept (keywords: "nedir", "nasıl", "why", "what is", "explain")
  → Response: Educational explanation, no code unless explicitly requested
  
- ACTION_CREATE: User wants NEW content created (keywords: "oluştur", "yap", "create", "make", "build")
  → Response: Generate complete, working code with LocalScript
  
- ACTION_FIX: User reports bug in EXISTING object (keywords: "düzelt", "fix", "çalışmıyor", "broken", "bug")
  → Response: Analyze existing code, output ONLY the fixed version
  
- ACTION_DELETE: User wants to remove object (keywords: "sil", "kaldır", "delete", "remove")
  → Response: Confirmation message only

DECISION: [State detected intent before proceeding]

【PHASE 2: CONTEXT ANALYSIS】
Question to answer: "What information do I need to fulfill this request?"
- What objects/scripts exist in the conversation history?
- What style preferences has user mentioned? (neon, minimalist, dark, glass)
- Are there constraints or requirements mentioned?
- Is this a follow-up to a previous request?

CONTEXT SUMMARY: [Summarize relevant context]

【PHASE 3: SOLUTION DESIGN】
Question to answer: "What is the BEST approach for this specific case?"
- If CONVERSATION: What's the clearest explanation? Do I need code examples?
- If ACTION_CREATE: What components are needed? What's the hierarchy? What animations/interactions?
- If ACTION_FIX: What is the root cause? What minimal changes fix it?
- If ACTION_DELETE: Simple confirmation or ask for clarification?

APPROACH: [Describe solution strategy]

【PHASE 4: QUALITY VALIDATION】
Question to answer: "Does my planned response meet quality standards?"
Checklist:
☐ Does this directly address user's intent?
☐ Is code syntactically correct (if applicable)?
☐ Are all parent-child relationships valid?
☐ Does it follow modern Roblox best practices?
☐ Is response concise and clear?

VALIDATION: [Confirm readiness]

【PHASE 5: RESPONSE GENERATION】
Now execute the planned solution.

═══════════════════════════════════════════════════════
📋 COMPREHENSION RULES
═══════════════════════════════════════════════════════
- NEVER assume action intent from vague questions
- ALWAYS ask clarifying questions if intent is ambiguous
- PREFER conversation mode unless explicit action keywords present
- READ conversation history to detect referenced objects

CREATION RULES:
1. Create ScreenGui first with a clear name (e.g., LoadingGUI, SettingsGUI, InventoryGUI)
2. Create ALL GUI elements (Frame, TextLabel, TextButton, ImageLabel, UICorner, UIStroke, UIListLayout/UIPadding when needed)
3. Create a LocalScript inside the ScreenGui for functionality (animations, button clicks, progress updates)
4. Set ALL properties for a modern, smooth look (fonts, TextScaled, colors, sizes)
5. Parent UI children to their containers (label.Parent = frame, corner.Parent = frame). DO NOT parent to StarterGui/PlayerGui. I will attach the ScreenGui to the game.

FUNCTIONALITY RULES (MANDATORY - NO EXCEPTIONS):
- ALWAYS create a LocalScript named "Controller" inside the ScreenGui
- LocalScript.Source must contain WORKING, TESTED code
- Use script.Parent to reference the ScreenGui, then WaitForChild for elements
- ALWAYS include TweenService for animations
- Loading GUIs: progress bar MUST animate from Size=UDim2.new(0,0,1,0) to UDim2.new(1,0,1,0) over 2-4 seconds
- Settings GUIs: buttons MUST have MouseButton1Click handlers that toggle states
- Inventory GUIs: items MUST have hover effects (MouseEnter/MouseLeave)
- Test your code mentally before outputting - ensure no nil references, proper parent hierarchy

CODE QUALITY CHECKLIST:
☐ All WaitForChild calls include correct element names matching the GUI structure
☐ Progress bar starts at width 0 and tweens to width 1 (not hardcoded at 0.2)
☐ TweenInfo duration is realistic (2-5 seconds for loading, 0.2-0.5s for buttons)
☐ All button handlers are connected before script ends
☐ No syntax errors, no missing 'end' keywords, no typos in property names

QUALITY STANDARDS (PREMIUM EDITION):
- Use UICorner for rounded edges (CornerRadius = UDim.new(0, 8-12)); add UIStroke for subtle borders (Color = 50,50,50, Transparency 0.5)
- Prefer AnchorPoint = Vector2.new(0.5, 0.5) and Position = UDim2.fromScale(0.5, 0.5) for centered panels
- Prefer Scale with small offsets (<= 24px). Avoid large absolute offsets.
- Add UIPadding and UIListLayout for consistent spacing; use ScrollingFrame + UIGridLayout for grids
- Text: TextScaled = true, TextWrapped = true, Font = Gotham/GothamBold, proper TextX/YAlignment
- Colors: dark surfaces (30-50), content (40-60), accent (88,101,242), white text
- ZIndex: layer popups above backgrounds (e.g., DisplayOrder >= 90)

PREMIUM FEATURES:
- Add ImageLabels with placeholder icons: rbxassetid://0 (user will replace)
- Use AutomaticSize = Enum.AutomaticSize.XY when appropriate (titles, dynamic lists)
- Add subtle animations: hover scale (1.0 → 1.05), color transitions
- Responsive layout: aspect ratio constraints for mobile/tablet
- Accessibility: named elements clearly, logical tab order

STYLE DETECTION (detect from user's message):
- If user says "neon"/"parlak"/"bright" → Black background (10,10,10), neon accent (0,255,200), glowing effects
- If user says "minimalist"/"sade"/"simple" → Light background (245,245,245), dark text, NO rounded corners, clean
- If user says "glass"/"frosted"/"şeffaf" → Semi-transparent (0.3), light blue tint (200,200,255), frosted look
- If user says "dark"/"modern"/"karanlık" → Dark surfaces (40,40,40), purple accent (88,101,242), rounded (12px)
- If NO style mentioned → Use modern dark by default


EXAMPLE (Loading GUI with functionality — note: child parenting + LocalScript):
```lua
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LoadingGUI"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 100

local background = Instance.new("Frame")
background.Name = "Background"
background.Size = UDim2.new(1, 0, 1, 0)
background.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
background.BackgroundTransparency = 0.25
background.BorderSizePixel = 0
background.Parent = screenGui

local centerFrame = Instance.new("Frame")
centerFrame.Name = "Panel"
centerFrame.Size = UDim2.new(0.4, 0, 0.28, 0)
centerFrame.AnchorPoint = Vector2.new(0.5, 0.5)
centerFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
centerFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
centerFrame.BorderSizePixel = 0
centerFrame.Parent = screenGui
local corner = Instance.new("UICorner") corner.CornerRadius = UDim.new(0, 12) corner.Parent = centerFrame

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -20, 0, 36)
title.Position = UDim2.new(0, 10, 0, 12)
title.Text = "Loading..."
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.BackgroundTransparency = 1
title.Parent = centerFrame

local progressBg = Instance.new("Frame")
progressBg.Name = "ProgressBG"
progressBg.Size = UDim2.new(0.8, 0, 0, 8)
progressBg.Position = UDim2.new(0.1, 0, 0, 64)
progressBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
progressBg.BorderSizePixel = 0
progressBg.Parent = centerFrame
local pbCorner = Instance.new("UICorner") pbCorner.CornerRadius = UDim.new(0, 4) pbCorner.Parent = progressBg

local progressBar = Instance.new("Frame")
progressBar.Name = "ProgressBar"
progressBar.Size = UDim2.new(0, 0, 1, 0)
progressBar.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
progressBar.BorderSizePixel = 0
progressBar.Parent = progressBg
local barCorner = Instance.new("UICorner") barCorner.CornerRadius = UDim.new(0, 4) barCorner.Parent = progressBar

-- FUNCTIONALITY: LocalScript for animation
local controller = Instance.new("LocalScript")
controller.Name = "Controller"
controller.Source = [=[
local TweenService = game:GetService("TweenService")
local gui = script.Parent
local panel = gui:WaitForChild("Panel")
local progressBar = panel:WaitForChild("ProgressBG"):WaitForChild("ProgressBar")
local title = panel:WaitForChild("Title")

-- Fade in animation
panel.BackgroundTransparency = 1
for _,child in ipairs(panel:GetDescendants()) do
  if child:IsA("GuiObject") then child.BackgroundTransparency = 1 end
  if child:IsA("TextLabel") or child:IsA("TextButton") then child.TextTransparency = 1 end
end

local fadeIn = TweenService:Create(panel, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {BackgroundTransparency = 0})
fadeIn:Play()
task.wait(0.2)
for _,child in ipairs(panel:GetDescendants()) do
  if child:IsA("TextLabel") then TweenService:Create(child, TweenInfo.new(0.3), {TextTransparency = 0}):Play() end
end

-- Progress bar animation (0 to 100%)
task.wait(0.5)
local progressTween = TweenService:Create(progressBar, TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 1, 0)})
progressTween:Play()

progressTween.Completed:Connect(function()
  task.wait(0.5)
  title.Text = "Complete!"
  task.wait(1)
  gui:Destroy()
end)
]=]
controller.Parent = screenGui
```

REMEMBER: Parent inside the GUI hierarchy, include LocalScript for interactivity, but NOT parent to StarterGui/PlayerGui.
]]

  -- Detect style keywords from user message
  local msgLower = msg:lower()
  local styleHint = ''
  
  if msgLower:find('neon') or msgLower:find('parlak') or msgLower:find('bright') then
    styleHint = '\n\n!! STYLE REQUEST: NEON !!\nUSE: Black background (10,10,10), bright neon accent (0,255,200), glowing colors, high contrast\n'
  elseif msgLower:find('minimalist') or msgLower:find('sade') or msgLower:find('simple') then
    styleHint = '\n\n!! STYLE REQUEST: MINIMALIST !!\nUSE: Light background (245,245,245), dark text (30,30,30), NO rounded corners, clean lines, subtle borders\n'
  elseif msgLower:find('glass') or msgLower:find('frosted') or msgLower:find('şeffaf') or msgLower:find('transparent') then
    styleHint = '\n\n!! STYLE REQUEST: GLASSMORPHISM !!\nUSE: Semi-transparent (BackgroundTransparency=0.3), light blue tint (200,200,255), frosted glass effect\n'
  elseif msgLower:find('dark') or msgLower:find('modern') or msgLower:find('karanlık') then
    styleHint = '\n\n!! STYLE REQUEST: MODERN DARK !!\nUSE: Dark surfaces (40,40,40), purple accent (88,101,242), rounded corners (12px)\n'
  else
    -- No specific style mentioned, use default modern dark
    styleHint = '\n\nSTYLE: Modern professional (dark theme, rounded corners, smooth)\n'
  end
  
  -- Contextual prompt injection based on intent
  local intentPrefix = ''
  if intent == 'conversation' then
    intentPrefix = [[

!! MODE: CONVERSATION/EXPLANATION !!
User is asking a question or seeking explanation. DO NOT generate code unless explicitly requested.
Provide clear, educational response. Use examples only if helpful for understanding.]]
  elseif intent == 'fix' and targetName then
    local objSource = ''
    if targetInstance then
      -- Extract current object structure
      local function describeObject(obj, indent)
        local desc = indent .. obj.ClassName .. ' "' .. obj.Name .. '"'
        if obj:IsA('LuaSourceContainer') then
          local ok, src = pcall(function() return obj.Source end)
          if ok and src and #src > 0 then
            desc = desc .. ' [Source: ' .. src:sub(1, 300) .. '...]'
          end
        elseif obj:IsA('GuiObject') then
          desc = desc .. string.format(' (Size: %s, Pos: %s)', tostring(obj.Size), tostring(obj.Position))
        end
        desc = desc .. '\n'
        for _, child in ipairs(obj:GetChildren()) do
          desc = desc .. describeObject(child, indent .. '  ')
        end
        return desc
      end
      objSource = describeObject(targetInstance, '')
    end
    intentPrefix = string.format([[

!! CRITICAL: ERROR FIX MODE !!

User reports issue with existing %s "%s".

Current structure:
%s

User's complaint: "%s"

!! YOUR TASK !!
1. ANALYZE the existing code/structure carefully
2. IDENTIFY the root cause of the issue
3. OUTPUT ONLY THE COMPLETE FIXED VERSION
4. DO NOT create a new object - FIX the existing one
5. Explain what was wrong in simple terms

If object doesn't exist or context unclear, ask user to clarify which object has the issue.]]
, targetType or 'object', targetName, objSource, msg)
  elseif intent == 'delete' and targetName then
    intentPrefix = '\n\n[CONTEXT: User wants to DELETE ' .. (targetType or 'object') .. ' "' .. targetName .. '". Respond with confirmation message, no code needed.]\n'
  else
    intentPrefix = '\n\n[CONTEXT: User is creating NEW content. Generate PERFECT, WORKING code with ZERO bugs. Use premium quality standards.]\n'
  end
  
  local ctx = getContext()..sysPrompt..styleHint..intentPrefix
  -- Add system message
  local msgs={{role='system',content=ctx}}
  
  -- Add conversation history (only last 5 messages to keep it short)
  for i=math.max(1,#mem-5),#mem do 
    table.insert(msgs, mem[i]) 
  end
  
  -- Check if this is an action request BEFORE sending
  local userMsg = msg:lower()
  local isActionRequest = 
    userMsg:find('oluştur') or 
    userMsg:find('yap') or 
    userMsg:find('ekle') or 
    userMsg:find('create') or 
    userMsg:find('make') or 
    userMsg:find('add') or
    userMsg:find('build') or
    userMsg:find('koy') or
    userMsg:find('getir') or
    userMsg:find('gui') or
    userMsg:find('sistem') or
    userMsg:find('bi.*şey') or
    userMsg:find('bir şey') or
    userMsg:find('bişey') or
    userMsg:find('tasarla') or
    userMsg:find('design') or
    userMsg:find('düzenle') or
    userMsg:find('edit')
  
  -- DIRECT NPC CREATION (bypass AI for NPCs)
  local isNPCRequest = (userMsg:find('npc') or userMsg:find('dummy') or userMsg:find('karakter') or userMsg:find('asker')) and
                       (userMsg:find('oluştur') or userMsg:find('yap') or userMsg:find('ekle') or userMsg:find('create') or userMsg:find('make'))
  
  if isNPCRequest then
    -- Handle NPC creation directly using InsertService
    local count = tonumber(userMsg:match('%d+')) or 1
    
    -- Create or find Npcs folder in workspace
    local npcsFolder = workspace:FindFirstChild('Npcs')
    if not npcsFolder then
      npcsFolder = Instance.new('Folder')
      npcsFolder.Name = 'Npcs'
      npcsFolder.Parent = workspace
    end
    
    local locations = {}
    local InsertService = game:GetService('InsertService')
    
    -- Load NPC model from asset ID 8114157416
    for i = 1, count do
      local success, model = pcall(function()
        return InsertService:LoadAsset(8114157416)
      end)
      
      if success and model then
        -- Get the actual model from the loaded asset
        local npcModel = model:GetChildren()[1]
        if npcModel then
          npcModel.Name = 'Dummy'
          
          -- Position NPCs with spacing
          local spacing = (i - 1) * 5
          if npcModel.PrimaryPart then
            npcModel:SetPrimaryPartCFrame(CFrame.new(spacing, 3, 0))
          elseif npcModel:FindFirstChild('HumanoidRootPart') then
            npcModel:MoveTo(Vector3.new(spacing, 3, 0))
          end
          
          -- Tag for undo
          local tag = Instance.new('BoolValue')
          tag.Name = 'IsNeuroviaBuild'
          tag.Parent = npcModel
          
          -- Parent to Npcs folder
          npcModel.Parent = npcsFolder
          table.insert(locations, {name=npcModel.Name, path='Workspace.Npcs.'..npcModel.Name, instance=npcModel})
        end
        model:Destroy()
      end
    end
    
    -- Show success message
    if #locations > 0 then
      addDebugLog('success', 'NPC Creation', string.format('%d NPCs created in Workspace/Npcs folder', #locations))
      addMsg('Neurovia', string.format('✅ %d NPC başarıyla oluşturuldu! (Workspace/Npcs klasöründe)', #locations), false, locations)
    else
      addDebugLog('error', 'NPC Creation Failed', 'Failed to load NPCs from asset ID 8114157416')
      addMsg('System', '❌ NPC oluşturulamadı. Lütfen internet bağlantınızı kontrol edin.', true)
    end
    return
  end
  
  -- Only show progress bar for action requests (not conversation)
  local showProgress = intent ~= 'conversation'
  
  sending=true
  
  local loadingMsg
  if showProgress then
    -- Show thinking progress bar
    loadingMsg = Instance.new('Frame')
  loadingMsg.Size=UDim2.new(1,-8,0,80)
  loadingMsg.BackgroundColor3=C.bubbleAI
  loadingMsg.BorderSizePixel=0
  loadingMsg.Parent=chat
  corner(loadingMsg,10)
  
  local loadIcon=Instance.new('ImageLabel')
  loadIcon.Size=UDim2.new(0,28,0,28)
  loadIcon.Position=UDim2.new(0,8,0,8)
  loadIcon.BackgroundTransparency=1
  loadIcon.Image='rbxassetid://73590799266237'
  loadIcon.ScaleType=Enum.ScaleType.Fit
  loadIcon.Parent=loadingMsg
  
  local loadText=Instance.new('TextLabel')
  loadText.Text='Neurovia'
  loadText.Size=UDim2.new(1,-46,0,12)
  loadText.Position=UDim2.new(0,44,0,0)
  loadText.BackgroundTransparency=1
  loadText.TextColor3=C.textMuted
  loadText.TextSize=9
  loadText.TextXAlignment=Enum.TextXAlignment.Left
  loadText.Parent=loadingMsg
  font(loadText,true)
  
  local loadBody=Instance.new('TextLabel')
  loadBody.Text='🧠 Analyzing request...'
  loadBody.Size=UDim2.new(1,-46,0,16)
  loadBody.Position=UDim2.new(0,44,0,14)
  loadBody.BackgroundTransparency=1
  loadBody.TextColor3=C.text
  loadBody.TextSize=11
  loadBody.TextXAlignment=Enum.TextXAlignment.Left
  loadBody.Parent=loadingMsg
  font(loadBody)
  
  -- Progress bar background
  local progressBg = Instance.new('Frame')
  progressBg.Size=UDim2.new(1,-56,0,4)
  progressBg.Position=UDim2.new(0,44,0,38)
  progressBg.BackgroundColor3=Color3.fromRGB(50,50,50)
  progressBg.BorderSizePixel=0
  progressBg.Parent=loadingMsg
  corner(progressBg,2)
  
  -- Progress bar fill (animated)
  local progressBar = Instance.new('Frame')
  progressBar.Size=UDim2.new(0,0,1,0)
  progressBar.BackgroundColor3=C.accent
  progressBar.BorderSizePixel=0
  progressBar.Parent=progressBg
  corner(progressBar,2)
  
  -- Gradient for progress bar
  local gradient=Instance.new('UIGradient')
  gradient.Color=ColorSequence.new(Color3.fromRGB(88,101,242), Color3.fromRGB(120,140,255))
  gradient.Parent=progressBar
  
  -- Animate thinking phases (different for fix vs create vs conversation)
  task.spawn(function()
    local phases
    if intent == 'fix' then
      -- Error analysis phases (RED)
      phases = {
        {text='🔍 Investigating issue...', progress=0.2},
        {text='📝 Reading existing code...', progress=0.4},
        {text='🔧 Identifying root cause...', progress=0.65},
        {text='✅ Preparing fix...', progress=0.9}
      }
      progressBar.BackgroundColor3=Color3.fromRGB(237,66,69)
      gradient.Color=ColorSequence.new(Color3.fromRGB(237,66,69), Color3.fromRGB(255,120,120))
    elseif intent == 'conversation' then
      -- Conversation mode (GREEN)
      phases = {
        {text='💬 Processing question...', progress=0.25},
        {text='📚 Gathering knowledge...', progress=0.5},
        {text='✍️ Formulating response...', progress=0.75},
        {text='✨ Finalizing...', progress=0.95}
      }
      progressBar.BackgroundColor3=Color3.fromRGB(67,181,129)
      gradient.Color=ColorSequence.new(Color3.fromRGB(67,181,129), Color3.fromRGB(100,220,160))
    else
      -- Creation phases (PURPLE)
      phases = {
        {text='🧠 Analyzing request...', progress=0.15},
        {text='📊 Planning approach...', progress=0.35},
        {text='⚙️ Generating solution...', progress=0.65},
        {text='✨ Finalizing...', progress=0.9}
      }
    end
    
    local phaseIndex = 1
    local startTime = tick()
    
    while loadingMsg and loadingMsg.Parent do
      local elapsed = tick() - startTime
      
      -- Change phase every 1.5 seconds
      if elapsed > phaseIndex * 1.5 and phaseIndex < #phases then
        phaseIndex = phaseIndex + 1
      end
      
      local currentPhase = phases[math.min(phaseIndex, #phases)]
      if loadBody and loadBody.Parent then
        loadBody.Text = currentPhase.text
      end
      
      -- Smooth progress animation
      local targetProgress = currentPhase.progress
      local currentProgress = progressBar.Size.X.Scale
      local newProgress = currentProgress + (targetProgress - currentProgress) * 0.1
      
      game:GetService('TweenService'):Create(progressBar, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        Size=UDim2.new(newProgress,0,1,0)
      }):Play()
      
      task.wait(0.1)
    end
  end)
  
  local pd=Instance.new('UIPadding')
  pd.PaddingLeft=UDim.new(0,14)
  pd.PaddingTop=UDim.new(0,10)
  pd.PaddingRight=UDim.new(0,14)
  pd.PaddingBottom=UDim.new(0,10)
  pd.Parent=loadingMsg
  
    -- Scroll to bottom
    task.defer(function()
      task.wait()
      chat.CanvasPosition=Vector2.new(0, chat.AbsoluteCanvasSize.Y)
    end)
  end
  
  task.spawn(function()
    local modelName = model or currentModel or 'Unknown'
    addDebugLog('info', 'AI Request', string.format('Sending request to %s', tostring(modelName)))
    local ok,res = AI.new(model):chat(msgs, key)
    
    -- Remove loading message
    if loadingMsg and loadingMsg.Parent then
      loadingMsg:Destroy()
    end
    
    sending=false
    
    if ok then
      addDebugLog('success', 'AI Response', string.format('Received %d characters from AI', #(res or '')))
      -- Check if response is empty or too short
      if not res or #res < 3 then
        addDebugLog('warning', 'Empty AI Response', 'AI returned empty or too short response')
        addMsg('System', '❌ AI boş yanıt verdi. Lütfen tekrar deneyin veya farklı model seçin.', true)
        return
      end
      
      -- Trim whitespace
      res = res:gsub('^%s+', ''):gsub('%s+$', '')
      
      table.insert(mem, {role='assistant', content=res})
      if #mem>100 then table.remove(mem,1) end
      
      -- Check for code blocks
      local codes = extractCode(res)
      if #codes > 0 then
        addDebugLog('info', 'Code Extracted', string.format('Found %d code block(s) in AI response', #codes))
      end
      
      -- Get ACTUAL user message (not AI response)
      local userMsg = ''
      for i = #mem, 1, -1 do
        if mem[i].role == 'user' then
          userMsg = mem[i].content:lower()
          break
        end
      end
      
      -- First check if it's conversational (greetings, questions)
      local isConversational = 
        userMsg:find('^selam') or
        userMsg:find('^naber') or
        userMsg:find('^hello') or
        userMsg:find('^hi$') or
        userMsg:find('^merhaba') or
        userMsg:find('nasılsın') or
        userMsg:find('^hey') or
        (userMsg:find('ne haber') and not userMsg:find('yap') and not userMsg:find('oluştur'))
      
      -- Then check if it's an action request
      local isActionRequest = not isConversational and (
        userMsg:find('oluştur') or 
        userMsg:find('yap') or 
        userMsg:find('ekle') or 
        userMsg:find('create') or 
        userMsg:find('make') or 
        userMsg:find('add') or
        userMsg:find('build') or
        userMsg:find('koy') or
        userMsg:find('getir') or
        userMsg:find('gui') or
        userMsg:find('menu') or
        userMsg:find('loading') or
        userMsg:find('bi.*şey') or
        userMsg:find('bir şey') or
        userMsg:find('bişey') or
        userMsg:find('tasarla') or
        userMsg:find('design') or
        userMsg:find('düzenle') or
        userMsg:find('edit')
      )
      
      -- Only auto-apply code if explicit action intent (not conversation)
      if #codes > 0 and intent ~= 'conversation' then
        -- AUTONOMOUS MODE: Auto-apply code immediately
        
        task.spawn(function()
          local results = {}
          local locations = {}
          
          for i,code in ipairs(codes) do
            -- Enhanced detection for workspace models/NPCs
            local isModel = userMsg:find('model') or userMsg:find('npc') or userMsg:find('workspace') or
                           code:find('workspace') or code:find('Model%.new') or code:find('Instance%.new%("Model"')
            local isGUI = not isModel and (userMsg:find('gui') or userMsg:find('menu') or userMsg:find('interface') or
                          code:find('ScreenGui') or code:find('Frame') or code:find('TextButton'))
            local isScript = not isGUI and not isModel and (code:find('function') or code:find('PlayerAdded'))
            
            if isModel then
              -- CREATE MODEL/NPC IN WORKSPACE (Note: NPCs are now handled by bypass before AI call)
              -- Execute generic model code from AI
              local success, err = pcall(function()
                local func, loadErr = loadstring(code)
                if func then
                  func()  -- Execute model creation code
                else
                  error(loadErr or 'Failed to compile code')
                end
              end)
              
              if success then
                -- Count models created
                local modelCount = 0
                for _, child in ipairs(workspace:GetChildren()) do
                  if child:IsA('Model') and not child:FindFirstChild('IsNeuroviaBuild') then
                    local tag = Instance.new('BoolValue')
                    tag.Name = 'IsNeuroviaBuild'
                    tag.Parent = child
                    modelCount = modelCount + 1
                    table.insert(locations, {name=child.Name, path='Workspace.'..child.Name, instance=child})
                  end
                end
                table.insert(results, string.format('✅ %d model oluşturuldu', modelCount))
              else
                table.insert(results, '❌ Model oluşturulamadı: '..tostring(err))
              end
              
            elseif isGUI then
              -- BUILD ACTUAL GUI INSTANCES
              local guiName = userMsg:match('(%w+)%s+gui') or 'NeuroviaGUI'
              guiName = guiName:sub(1,1):upper()..guiName:sub(2)..'GUI'
              
              -- If fix intent, delete old object first
              if intent == 'fix' and targetName and targetInstance then
                pcall(function() targetInstance:Destroy() end)
              end
              
              local screenGui, err = buildGUIFromCode(code, guiName, userMsg)
              
              if screenGui then
                -- Add to StarterGui
                local ok, applyErr = pcall(function()
                  screenGui.Parent = game:GetService('StarterGui')
                end)
                
                if ok then
                  local childCount = #screenGui:GetChildren()
                  addDebugLog('action', 'GUI Applied', string.format('%s added to StarterGui with %d elements', guiName, childCount))
                  table.insert(results, string.format('✅ %s (%d eleman)', guiName, childCount))
                  table.insert(locations, {name=guiName, path='StarterGui.'..guiName, instance=screenGui})
                else
                  addDebugLog('error', 'GUI Application Failed', tostring(applyErr))
                  table.insert(results, '❌ Başarısız: '..tostring(applyErr))
                end
              else
                addDebugLog('error', 'GUI Build Failed', tostring(err))
                table.insert(results, '❌ GUI Build Failed: '..tostring(err))
              end
            elseif isScript then
              -- CREATE SCRIPT
              local scriptName = 'GeneratedScript'
              local scriptType = 'Script'
              local targetParent = game:GetService('ServerScriptService')
              
              -- Detect script type
              if code:find('LocalPlayer') or code:find('PlayerGui') then
                scriptType = 'LocalScript'
                targetParent = game:GetService('StarterGui')
                scriptName = 'ClientScript'
              elseif code:find('PlayerAdded') or code:find('CharacterAdded') then
                scriptName = 'ServerScript'
                scriptType = 'Script'
                targetParent = game:GetService('ServerScriptService')
              elseif code:find('Tool') or code:find('Equipped') then
                scriptName = 'ToolScript'
                scriptType = 'Script'
                targetParent = game:GetService('StarterPack')
              elseif code:find('workspace') and code:find('Part') then
                scriptName = 'Script'
                scriptType = 'Script'
                targetParent = game:GetService('ServerScriptService')
              end
              
              if #codes > 1 then scriptName = scriptName..i end
              
              -- Create the script
              local newScript = Instance.new(scriptType)
              newScript.Name = scriptName
              newScript.Source = code
              
              -- Save for undo
              Store:pushUndo({script=newScript, old='', created=true})
              
              -- Apply to project
              local ok,err = pcall(function()
                newScript.Parent = targetParent
              end)
              
              if ok then
                local fullPath = targetParent:GetFullName()..'.'..scriptName
                addDebugLog('action', 'Script Created', string.format('%s (%s) created in %s', scriptName, scriptType, targetParent.Name))
                table.insert(results, string.format('✅ %s', scriptName))
                table.insert(locations, {name=scriptName, path=fullPath, instance=newScript})
              else
                addDebugLog('error', 'Script Creation Failed', string.format('Failed to create %s: %s', scriptName, tostring(err)))
                table.insert(results, '❌ Başarısız: '..tostring(err))
              end
            end
            
            task.wait(0.1)
          end
          
          -- Create modern notification with Turkish support
          local successCount = 0
          for _,r in ipairs(results) do
            if r:find('✅') then successCount = successCount + 1 end
          end
          
          -- Detect if user message is in Turkish
          local isTurkish = msg:find('[çğıöşüÇĞİÖŞÜ]') or 
                            msg:lower():find('oluştur') or msg:lower():find('yap') or 
                            msg:lower():find('düzelt') or msg:lower():find('hata')
          
          local notification
          if intent == 'fix' then
            -- Fix mode
            if isTurkish then
              notification = string.format('✅ %d öğe başarıyla düzeltildi:\n%s', 
                successCount, table.concat(results, '\n'))
            else
              notification = string.format('✅ Successfully fixed %d item%s:\n%s', 
                successCount, successCount > 1 and 's' or '', table.concat(results, '\n'))
            end
          else
            -- Create mode
            if isTurkish then
              notification = string.format('🎉 %d öğe başarıyla oluşturuldu:\n%s', 
                successCount, table.concat(results, '\n'))
            else
              notification = string.format('🎉 Successfully created %d item%s:\n%s', 
                successCount, successCount > 1 and 's' or '', table.concat(results, '\n'))
            end
          end
          
          addMsg('Neurovia', notification, false, locations)
        end)
      -- Removed: show-only branch (auto-apply enabled)
      elseif intent == 'conversation' then
        -- CONVERSATION mode: just show response, no auto-apply
        addMsg('Neurovia', res)
      else
        -- No code blocks, show response
        addMsg('Neurovia', res:sub(1,800)..(#res>800 and '...' or ''))
      end
    else
      -- Error occurred
      addDebugLog('error', 'AI Error', tostring(res))
      if loadingMsg and loadingMsg.Parent then
        loadingMsg:Destroy()
      end
      addMsg('System', '❌ '..tostring(res), true)
    end
  end)
end

-- Old model menu removed - now using Cursor-style inline dropdown

-- Main menu
menuBtn.MouseButton1Click:Connect(function()
  closeMenus()
  local over=Instance.new('Frame')
  over.Name='Menu'
  over.BackgroundTransparency=1
  over.Size=UDim2.new(1,0,1,0)
  over.ZIndex=100
  over.Parent=root
  
  local menu=Instance.new('Frame')
  menu.BackgroundColor3=Color3.fromRGB(30,30,33)
  menu.BackgroundTransparency=0
  menu.BorderSizePixel=0
  menu.Size=UDim2.new(0,220,0,0)
  menu.AnchorPoint=Vector2.new(1,0)
  menu.Position=UDim2.new(1,-10,0,40)
  menu.ZIndex=101
  menu.AutomaticSize=Enum.AutomaticSize.Y
  menu.ClipsDescendants=false
  menu.Parent=over
  corner(menu,8)
  
  -- Border
  local menuStroke=Instance.new('UIStroke')
  menuStroke.Color=Color3.fromRGB(60,60,65)
  menuStroke.Thickness=1
  menuStroke.Transparency=0.5
  menuStroke.Parent=menu
  
  -- Padding
  local menuPad=Instance.new('UIPadding')
  menuPad.PaddingTop=UDim.new(0,6)
  menuPad.PaddingBottom=UDim.new(0,6)
  menuPad.PaddingLeft=UDim.new(0,6)
  menuPad.PaddingRight=UDim.new(0,6)
  menuPad.Parent=menu
  
  local menuList=Instance.new('UIListLayout')
  menuList.Padding=UDim.new(0,2)
  menuList.SortOrder=Enum.SortOrder.LayoutOrder
  menuList.FillDirection=Enum.FillDirection.Vertical
  menuList.Parent=menu
  
  local menuItems = {
    -- Menu is now minimal - most actions moved to inline buttons
  }
  
  for idx,item in ipairs(menuItems) do
    local b=Instance.new('TextButton')
    b.BackgroundColor3=Color3.fromRGB(30,30,33)
    b.BackgroundTransparency=0
    b.TextColor3=Color3.fromRGB(180,180,185)
    b.TextSize=11
    b.Text=item.text
    b.Size=UDim2.new(1,0,0,36)
    b.ZIndex=102
    b.LayoutOrder=idx
    b.TextXAlignment=Enum.TextXAlignment.Left
    b.Parent=menu
    corner(b,6)
    font(b)
    
    local pad=Instance.new('UIPadding')
    pad.PaddingLeft=UDim.new(0,10)
    pad.Parent=b
    
    -- Hover effect
    b.MouseEnter:Connect(function()
      game:GetService('TweenService'):Create(b, TweenInfo.new(0.1), {
        BackgroundColor3=Color3.fromRGB(45,45,50),
        TextColor3=Color3.fromRGB(255,255,255)
      }):Play()
    end)
    b.MouseLeave:Connect(function()
      game:GetService('TweenService'):Create(b, TweenInfo.new(0.1), {
        BackgroundColor3=Color3.fromRGB(30,30,33),
        TextColor3=Color3.fromRGB(180,180,185)
      }):Play()
    end)
    
    b.MouseButton1Click:Connect(function()
      over:Destroy()
      item.fn()
    end)
  end
  
  over.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then
      over:Destroy()
    end
  end)
end)

-- Toggle widget

-- Hot Reload Function
local function hotReload()
  addMsg('System', '?? Reloading plugin...', false)
  task.wait(0.5)
  
  -- Get plugin manager
  local PluginManager = settings():GetService('PluginManagement')
  
  -- Find this plugin
  for _, p in ipairs(PluginManager:GetPlugins()) do
    if p.Name:find('NeuroviaCoder') or p.Name:find('Neurovia') then
      -- Disable and re-enable
      pcall(function()
        PluginManager:SetPlugin(p, false)
        task.wait(0.1)
        PluginManager:SetPlugin(p, true)
      end)
      break
    end
  end
  
  addMsg('System', '? Plugin reloaded!', false)
end


-- ============ AUTO-RELOAD SYSTEM ============
local lastModified = 0
local function checkForUpdates()
  -- Check if plugin file was modified
  local ok, fileInfo = pcall(function()
    return plugin:GetSetting('_last_modified') or 0
  end)
  
  local currentTime = os.time()
  if ok and currentTime - lastModified > 2 then
    lastModified = currentTime
    -- File might have changed, offer to reload
    -- (We can't detect file changes directly, so check periodically)
  end
end

-- Check every 5 seconds
task.spawn(function()
  while true do
    task.wait(5)
    checkForUpdates()
  end
end)
btn.Click:Connect(function() 
  widget.Enabled = not widget.Enabled
  if widget.Enabled then
    refreshAPI(true) -- Show welcome if no API
  end
end)

-- Check on initial load
task.defer(function()
  task.wait(0.5)
  if widget.Enabled then
    refreshAPI(true)
  end
end)

-- Initialize
refreshAPI()

print('✅ Neurovia Coder v2.0.0 - Super AI Comprehension')
