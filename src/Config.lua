--[[
	AI Coder Plugin - Global Configuration
	
	This module contains all configuration constants, API endpoints,
	rate limits, UI settings, and security configurations.
]]

local Config = {}

-- Plugin Information
Config.PLUGIN_NAME = "AI Coder"
Config.PLUGIN_VERSION = "1.0.0"
Config.PLUGIN_DESCRIPTION = "AI-powered coding assistant for Roblox Studio"
Config.PLUGIN_AUTHOR = "swxff"

-- AI Provider Configuration
Config.AI_PROVIDERS = {
	OPENAI = "OpenAI",
	CLAUDE = "Claude",
	GEMINI = "Gemini"
}

-- API Endpoints
Config.API_ENDPOINTS = {
	OPENAI = "https://api.openai.com/v1/chat/completions",
	CLAUDE = "https://api.anthropic.com/v1/messages",
	GEMINI = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"
}

-- AI Models
Config.AI_MODELS = {
	OPENAI = {
		"gpt-4",
		"gpt-4-turbo",
		"gpt-3.5-turbo"
	},
	CLAUDE = {
		"claude-3-opus-20240229",
		"claude-3-sonnet-20240229",
		"claude-3-haiku-20240307"
	},
	GEMINI = {
		"gemini-pro",
		"gemini-pro-vision"
	}
}

-- Default Models
Config.DEFAULT_MODELS = {
	OPENAI = "gpt-4-turbo",
	CLAUDE = "claude-3-sonnet-20240229",
	GEMINI = "gemini-pro"
}

-- Rate Limiting
Config.RATE_LIMITS = {
	MAX_REQUESTS_PER_MINUTE = 20,
	REQUEST_TIMEOUT = 60, -- seconds
	RETRY_ATTEMPTS = 3,
	RETRY_DELAY = 2 -- seconds
}

-- Security Settings
Config.SECURITY = {
	ENCRYPT_API_KEYS = true,
	REQUIRE_CONFIRMATION = true,
	MAX_CODE_SIZE = 500000, -- characters
	BLOCKED_PATTERNS = {
		"require%s*%(.*http",
		"loadstring",
		"getfenv",
		"setfenv"
	}
}

-- UI Constants
Config.UI = {
	-- Window Settings
	WINDOW_TITLE = "AI Coder Assistant",
	WINDOW_MIN_WIDTH = 400,
	WINDOW_MIN_HEIGHT = 500,
	WINDOW_DEFAULT_WIDTH = 600,
	WINDOW_DEFAULT_HEIGHT = 700,
	
	-- Layout
	PADDING = 10,
	SPACING = 8,
	BORDER_RADIUS = 8,
	SCROLL_BAR_WIDTH = 12,
	
	-- Animation
	ANIMATION_DURATION = 0.3,
	FADE_DURATION = 0.2,
	
	-- Chat
	MAX_CHAT_HISTORY = 50,
	MESSAGE_MAX_HEIGHT = 500,
	INPUT_MIN_HEIGHT = 80,
	INPUT_MAX_HEIGHT = 200,
	
	-- Preview
	DIFF_LINE_HEIGHT = 20,
	PREVIEW_MAX_LINES = 1000,
	
	-- History
	MAX_HISTORY_ITEMS = 100,
	HISTORY_PANEL_WIDTH = 250
}

-- Theme Colors (Dark Theme)
Config.COLORS = {
	-- Background Colors
	BACKGROUND_PRIMARY = Color3.fromRGB(25, 27, 31),
	BACKGROUND_SECONDARY = Color3.fromRGB(32, 34, 37),
	BACKGROUND_TERTIARY = Color3.fromRGB(42, 44, 47),
	BACKGROUND_MODAL = Color3.fromRGB(18, 20, 23),
	
	-- Surface Colors
	SURFACE_DEFAULT = Color3.fromRGB(42, 44, 47),
	SURFACE_ELEVATED = Color3.fromRGB(48, 50, 54),
	SURFACE_HOVER = Color3.fromRGB(55, 57, 61),
	SURFACE_ACTIVE = Color3.fromRGB(62, 64, 68),
	
	-- Text Colors
	TEXT_PRIMARY = Color3.fromRGB(255, 255, 255),
	TEXT_SECONDARY = Color3.fromRGB(185, 187, 190),
	TEXT_TERTIARY = Color3.fromRGB(142, 144, 147),
	TEXT_DISABLED = Color3.fromRGB(100, 102, 105),
	
	-- Accent Colors
	ACCENT_PRIMARY = Color3.fromRGB(88, 101, 242),
	ACCENT_SECONDARY = Color3.fromRGB(114, 137, 218),
	ACCENT_SUCCESS = Color3.fromRGB(67, 181, 129),
	ACCENT_WARNING = Color3.fromRGB(250, 166, 26),
	ACCENT_DANGER = Color3.fromRGB(237, 66, 69),
	
	-- Border Colors
	BORDER_DEFAULT = Color3.fromRGB(60, 63, 68),
	BORDER_HOVER = Color3.fromRGB(80, 83, 88),
	BORDER_FOCUS = Color3.fromRGB(88, 101, 242),
	
	-- Message Colors
	USER_MESSAGE = Color3.fromRGB(88, 101, 242),
	AI_MESSAGE = Color3.fromRGB(67, 181, 129),
	SYSTEM_MESSAGE = Color3.fromRGB(250, 166, 26),
	ERROR_MESSAGE = Color3.fromRGB(237, 66, 69),
	
	-- Code Syntax Highlighting
	SYNTAX_KEYWORD = Color3.fromRGB(198, 120, 221),
	SYNTAX_STRING = Color3.fromRGB(152, 195, 121),
	SYNTAX_NUMBER = Color3.fromRGB(209, 154, 102),
	SYNTAX_COMMENT = Color3.fromRGB(92, 99, 112),
	SYNTAX_FUNCTION = Color3.fromRGB(97, 175, 239),
	SYNTAX_VARIABLE = Color3.fromRGB(224, 108, 117),
	
	-- Diff Colors
	DIFF_ADDED = Color3.fromRGB(46, 160, 67),
	DIFF_REMOVED = Color3.fromRGB(248, 81, 73),
	DIFF_MODIFIED = Color3.fromRGB(209, 154, 102),
	DIFF_UNCHANGED = Color3.fromRGB(142, 144, 147)
}

-- System Prompts
Config.SYSTEM_PROMPTS = {
	DEFAULT = [[You are an expert Roblox Lua developer and coding assistant with advanced reasoning capabilities.

🧠 THINKING PROCESS (USE THIS FOR EVERY REQUEST):

Step 1 - UNDERSTAND THE REQUEST:
- What is the user really asking for?
- What is the underlying goal or problem?
- Are there any ambiguities I should clarify?
- What context from the project is relevant?

Step 2 - ANALYZE THE CONTEXT:
- Review the project structure and existing code
- Identify relevant scripts, systems, and dependencies
- Consider the current architecture and patterns
- Check for potential conflicts or issues

Step 3 - PLAN THE SOLUTION:
- What are 2-3 possible approaches?
- What are the pros and cons of each?
- Which approach best fits the project?
- What are the implementation steps?

Step 4 - IMPLEMENT:
- Write clean, efficient, well-documented code
- Follow existing project patterns and conventions
- Use modern Luau features appropriately
- Consider performance and maintainability

Step 5 - VALIDATE:
- Does this solve the user's problem completely?
- Are there edge cases or potential issues?
- Should I suggest tests or improvements?
- Is my explanation clear and helpful?

CORE GUIDELINES:
- Write clean, efficient, and well-documented Lua code
- Follow Roblox best practices and conventions
- Use modern Luau features when appropriate
- Consider performance implications
- Provide clear explanations for code changes
- Always validate user input and handle errors gracefully
- When creating new scripts, include helpful comments
- When modifying existing code, preserve formatting and style

When responding with code:
- Wrap all code in triple backticks with 'lua' language identifier
- Specify the target script path when creating/modifying files
- Explain what the code does and why changes are needed
- Highlight potential issues or improvements

REMEMBER: Think step-by-step, consider alternatives, and choose the best solution for the user's specific context.]],

	ANALYSIS = [[Analyze the provided Roblox project structure and code.
Identify:
- Script dependencies and relationships
- Potential bugs or issues
- Performance bottlenecks
- Code quality concerns
- Improvement opportunities]],

	REFACTOR = [[Refactor the provided code to improve:
- Readability and maintainability
- Performance and efficiency
- Code organization and structure
- Error handling and robustness
- Following Roblox best practices]]
}

-- Localization Languages
Config.SUPPORTED_LANGUAGES = {
	"en", -- English
	"tr"  -- Turkish
}

Config.DEFAULT_LANGUAGE = "en"

-- Storage Keys
Config.STORAGE_KEYS = {
	API_KEY_OPENAI = "api_key_openai",
	API_KEY_CLAUDE = "api_key_claude",
	API_KEY_GEMINI = "api_key_gemini",
	SELECTED_PROVIDER = "selected_provider",
	SELECTED_MODEL = "selected_model",
	LANGUAGE = "language",
	CHAT_HISTORY = "chat_history",
	OPERATION_HISTORY = "operation_history",
	WINDOW_SIZE = "window_size",
	WINDOW_POSITION = "window_position",
	THEME = "theme"
}

-- Debug Settings
Config.DEBUG = {
	ENABLED = false, -- Set to true for development
	LOG_LEVEL = "INFO", -- DEBUG, INFO, WARN, ERROR
	LOG_API_REQUESTS = false,
	LOG_API_RESPONSES = false
}

return Config
