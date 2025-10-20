-- Stdio MessagePack connection handling
local M = {}

local uv = vim.loop
local stdin_pipe = nil

function M.attach_stdin(write_pipe)
  stdin_pipe = write_pipe
end

function M.send_raw(bytes)
  if stdin_pipe then
    stdin_pipe:write(bytes)
  end
end

function M.close()
  if stdin_pipe then
    stdin_pipe:close()
    stdin_pipe = nil
  end
end

function M.is_connected()
  return stdin_pipe ~= nil
end

return M

