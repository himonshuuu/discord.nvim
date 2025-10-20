local M = {}
local config = {}
local log_levels = {
  debug = 1,
  info = 2,
  warn = 3,
  error = 4,
}

function M.setup(user_config)
  config = user_config or {}
  config.log_level = config.log_level or "info"
end

local function should_log(level)
  local current_level = log_levels[config.log_level] or log_levels.info
  local message_level = log_levels[level] or log_levels.info
  return message_level >= current_level
end

local function notify_colored(msg, level, color)
  if not should_log(level) then
    return
  end
  
  local hl_group
  if color == "yellow" then
    hl_group = "WarningMsg"
  elseif color == "white" then
    hl_group = "Normal"
  elseif color == "red" then
    hl_group = "ErrorMsg"
  elseif color == "orange" then
    hl_group = "Todo"
  else
    hl_group = nil
  end

  -- Map string levels to vim.log.levels
  local vim_level
  if level == "debug" then
    vim_level = vim.log.levels.DEBUG
  elseif level == "info" then
    vim_level = vim.log.levels.INFO
  elseif level == "warn" then
    vim_level = vim.log.levels.WARN
  elseif level == "error" then
    vim_level = vim.log.levels.ERROR
  else
    vim_level = vim.log.levels.INFO
  end

  if vim and vim.notify and vim.log and vim.log.levels then
    vim.notify(
      "[discord.nvim]: " .. tostring(msg),
      vim_level,
      { title = "discord.nvim", hl_group = hl_group }
    )
  else
    print("[discord.nvim]: " .. tostring(msg))
  end
end

function M.info(message)
  notify_colored(message, "info", "white")
end

function M.debug(message)
  notify_colored(message, "debug", "yellow")
end

function M.warn(message)
  notify_colored(message, "warn", "orange")
end

function M.error(message)
  notify_colored(message, "error", "red")
end

return M