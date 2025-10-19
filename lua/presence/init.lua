local M = {}

local state = require("presence.state")
local daemon = require("presence.daemon")
local events = require("presence.events")
local assets = require("presence.assets")

local default_config = {
  client_id = "1173975703046340789",
  idle_timeout_ms = 60000,
  show_timer = true,
}

function M.setup(user_config)
  local config = vim.tbl_deep_extend("force", default_config, user_config or {})
  state.set_config(config)
  assets.load()
  daemon.ensure_started(config)
  events.register_autocmds()
  events.update_presence("viewing")
end

function M.shutdown()
  daemon.shutdown()
end

return M


