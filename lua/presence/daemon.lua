local M = {}

local daemon = require("presence.core.manager")
local activity = require("presence.core.builder")
local connection = require("presence.core.connection")
local state = require("presence.state")

function M.ensure_started(config)
  daemon.ensure_started(config, function(success, err)
    if not success and err then
      vim.schedule(function()
        vim.notify("presence.nvim: " .. err, vim.log.levels.ERROR)
      end)
    end
  end)
end

function M.push_activity(mode)
  if not connection.is_connected() then return end
  
  local cfg = state.get_config()
  local activity_data = activity.build_activity(mode)
  local formatted_activity = activity.format_activity_for_daemon(activity_data, cfg)
  
  connection.write_json({ action = "set_activity", payload = formatted_activity })
end

function M.shutdown()
  daemon.shutdown()
end

return M