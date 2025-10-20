-- Daemon process management
local M = {}

local uv = vim.loop
local conn = require("discord.conn")
local proc = nil

local function get_binary()
  local os_name = uv.os_uname().sysname:lower()
  local arch = uv.os_uname().machine:lower()
  local is_arm = arch:match("aarch64") or arch:match("arm64")
  
  local name
  if os_name == "linux" then
    name = is_arm and "discord-nvim-daemon-linux-arm64" or "discord-nvim-daemon-linux-amd64"
  elseif os_name == "darwin" then
    name = is_arm and "discord-nvim-daemon-darwin-arm64" or "discord-nvim-daemon-darwin-amd64"
  elseif os_name:match("windows") then
    name = "discord-nvim-daemon-windows-amd64.exe"
  else
    name = "discord-nvim-daemon-linux-amd64"
  end
  
  local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ":p:h:h:h")
  return root .. "/bin/" .. name
end

local function download_binary()
  local bin = get_binary()
  local url = "https://github.com/himonshuuu/discord.nvim/releases/latest/download/" .. vim.fn.fnamemodify(bin, ":t")

  local logger = require("lib.logger")
   
  logger.debug(url)
  vim.fn.mkdir(vim.fn.fnamemodify(bin, ":h"), "p")

  logger.debug("Downloading binary...")
  uv.spawn("curl", { args = {"-fsSL", url, "-o", bin } }, function(code)
    if code == 0 then
      uv.fs_chmod(bin, tonumber("755", 8), function() end)
      vim.schedule(function()
        logger.debug("Downloaded successfully!")
      end)
    end
  end)
end


local function spawn_daemon()
  local bin = get_binary()
  if not uv.fs_stat(bin) then
    download_binary()
    return false
  end
  
  local stdin_pipe = uv.new_pipe(false)
  local stdout_read = uv.new_pipe(false)
  local stderr_read = uv.new_pipe(false)

  proc = uv.spawn(bin, {
    stdio = { stdin_pipe, stdout_read, stderr_read },
  }, function()
    -- Only close handles if they're still active
    if stdin_pipe and not stdin_pipe:is_closing() then
      stdin_pipe:close()
    end
    if stdout_read and not stdout_read:is_closing() then
      stdout_read:close()
    end
    if stderr_read and not stderr_read:is_closing() then
      stderr_read:close()
    end
    proc = nil
  end)
  if not proc then
    -- Only close handles if they're still active
    if stdin_pipe and not stdin_pipe:is_closing() then
      stdin_pipe:close()
    end
    if stdout_read and not stdout_read:is_closing() then
      stdout_read:close()
    end
    if stderr_read and not stderr_read:is_closing() then
      stderr_read:close()
    end
    return false
  end

  conn.attach_stdin(stdin_pipe)

  -- Drain stdout/stderr to avoid backpressure
  stdout_read:read_start(function() end)
  stderr_read:read_start(function() end)
  return proc ~= nil
end

function M.start(config)
  local logger = require("lib.logger")
  logger.debug("Starting daemon with stdio transport")
  
  if not spawn_daemon() then
    logger.error("Failed to spawn daemon")
    return
  end
  
  local m = { type = "INIT", client_id = config.client_id }
  local bytes = vim.mpack.encode(m)
  conn.send_raw(bytes)
  logger.debug("Sent INIT via stdio")
  
  vim.schedule(function()
    require("discord.activity").update()
  end)
end

function M.shutdown()
  local m = { type = "SHUTDOWN" }
  conn.send_raw(vim.mpack.encode(m))
  conn.close()
  if proc then
    proc:kill("TERM")
    proc = nil
  end
end

function M.get_status()
  return proc ~= nil and "running" or "not running"
end

return M
