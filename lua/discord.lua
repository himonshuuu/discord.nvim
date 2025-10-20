-- discord.nvim main entry point
local M = {}

local state = {
  config = {},
  mode = "viewing",
  start_at = os.time(),
}

local default_config = {
  client_id = "1173975703046340789",
  idle_timeout_ms = 5000,
  show_timer = true,
  debounce_timeout_ms = 500,
  log_level = "info", -- "debug", "info", "warn", "error"
  
  -- Customizable symbols for different states
  symbols = {
    editing = "📝",
    viewing = "📄", 
    idle = "💤",
    folder = "📁",
    tree = "📂",
  },
  
  -- Customizable state text
  states = {
    browsing = "🔎 Browsing files",
    idle = "💤 Taking a break",
    editing = "Editing",
    viewing = "Viewing",
  },
}

function M.setup(user_config)
  state.config = vim.tbl_deep_extend("force", default_config, user_config or {})  
  
  local logger = require("lib.logger")
  logger.setup(state.config)
  
  local daemon = require("discord.daemon")
  daemon.start(state.config)
  
  local events = require("discord.events")
  events.setup(state)
  
  local commands = require("lib.commands")
  commands.setup()
end

function M.shutdown()
  require("discord.activity").cleanup()
  require("discord.daemon").shutdown()
end

function M.get_state()
  return state
end

function M.start()
  require("discord.daemon").start(state.config)
  require("discord.activity").update()
end

function M.get_status()
  return require("discord.daemon").get_status()
end

return M

