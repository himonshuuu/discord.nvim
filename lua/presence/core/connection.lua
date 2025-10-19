local M = {}

local uv = vim.loop
local state = require("presence.state")

local sock = nil

function M.connect(addr, on_connected)
  sock = uv.new_pipe(true)
  local function connect()
    local ok = sock:connect(addr, function(cerr)
      if cerr then
        on_connected(false, cerr)
      else
        sock:read_start(M.on_read)
        on_connected(true)
      end
    end)
    if not ok then
      on_connected(false, "Failed to initiate socket connection")
    end
  end
  connect()
end

function M.write_json(payload)
  if not sock then return false end
  local line = vim.json.encode(payload) .. "\n"
  sock:write(line)
  return true
end

function M.on_read(err, data)
  if err then return end
  if not data then return end
  -- could parse responses for logging/checks in future
end

function M.is_connected()
  return sock ~= nil
end

function M.close()
  if sock then
    sock:close()
    sock = nil
  end
end

return M
