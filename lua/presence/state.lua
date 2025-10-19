local M = {}

local cfg = {}
local current = {
  mode = "viewing",
  start_at = os.time(),
  session_id = tostring(math.floor(vim.loop.hrtime() / 1000))
}

function M.set_config(c)
  cfg = c or {}
end

function M.get_config()
  return cfg
end

function M.set_mode(mode)
  if current.mode ~= mode then
    current.mode = mode
    current.start_at = os.time()
  end
end

function M.get_mode()
  return current.mode
end

function M.get_start_at()
  return current.start_at
end

function M.get_session_id()
  return current.session_id
end

return M


