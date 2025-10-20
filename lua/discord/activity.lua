local M = {}

local uv = vim.loop
local debounce_timer = nil

local function get_icon(filename)
  local icons = require("lib.icons")
  return icons.icon_for_filename(filename)
end

local function get_diagnostics(buf)
  if vim.diagnostic and vim.diagnostic.get then
    return #(vim.diagnostic.get(buf) or {})
  end
  return 0
end

local function get_symbols()
  local state = require("discord").get_state()
  return state.config.symbols or {
    editing = "📝",
    viewing = "📄",
    idle = "💤",
    folder = "📁",
    tree = "📂",
  }
end

local function get_states()
  local state = require("discord").get_state()
  return state.config.states or {
    browsing = "🔎 Browsing files",
    idle = "💤 Taking a break",
    editing = "Editing",
    viewing = "Viewing",
  }
end

local function is_dir_listing(ft, name)
  ft = ft or ""
  if ft == "netrw" or ft == "NvimTree" or ft == "dirvish" or ft == "oil" then
    return true
  end
  if name:find("^oil://") then return true end
  return false
end

local function get_stats(buf)
  local mode = vim.api.nvim_get_mode().mode
  local symbols = get_symbols()

  local action = (mode:match("^[iR]")) and "editing" or "viewing"
  local symbol = (action == "editing") and symbols.editing or symbols.viewing

  return symbol
end

function M.build()
  local state = require("discord").get_state()
  local symbols = get_symbols()
  local states = get_states()
  local buf = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(buf)
  local ft = vim.bo[buf].filetype or "text"
  local cursor = vim.api.nvim_win_get_cursor(0)
  local filename = (name ~= "" and vim.fn.fnamemodify(name, ":t")) or "untitled"
  local pos = string.format("%s:%d:%d", filename, cursor[1], cursor[2] + 1)
  local root = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
  local problems = get_diagnostics(buf)

  if is_dir_listing(ft, name) then
    return {
      details = string.format("%s %s", symbols.folder, root),
      state = states.browsing,
      large_image = "tree",
      large_text = states.browsing,
      small_image = (state.mode == "idle" and "idle") or "neovim",
      small_text = "Neovim",
      start_at = state.config.show_timer and state.start_at or 0,
    }
  end

  if state.mode == "idle" then
    return {
      details = "",
      state = states.idle,
      large_image = "idle",
      large_text = symbols.idle .. " Idle",
      small_image = "neovim",
      small_text = "Neovim",
      start_at = state.config.show_timer and state.start_at or 0,
    }
  end

  local symbol = get_stats(buf)
  return {
    details = string.format("%s %s - %d problems", symbols.folder, root, problems),
    state = string.format("%s %s", symbol, pos),
    large_image = get_icon(name),
    large_text = ft,
    small_image = "neovim",
    small_text = "Neovim",
    start_at = state.config.show_timer and state.start_at or 0,
  }
end

local function send_activity_update()
  local conn = require("discord.conn")
  local logger = require("lib.logger")
  
  if not conn.is_connected() then 
    logger.warn("Not connected, skipping activity update")
    return 
  end
  
  local act = M.build()
  local msg = {
    type = "ACT",
    details = act.details or "",
    state = act.state or "",
    large_image = act.large_image or "",
    large_text = act.large_text or "",
    small_image = act.small_image or "",
    small_text = act.small_text or "",
    start_at = act.start_at or 0,
  }
  local bytes = vim.mpack.encode(msg)
  conn.send_raw(bytes)
  logger.debug("Sent ACT via stdio")
end

function M.update()
  local state = require("discord").get_state()
  local debounce_timeout = state.config.debounce_timeout_ms or 1000
  
  if debounce_timer then
    debounce_timer:stop()
  end
    
  debounce_timer = uv.new_timer()
  debounce_timer:start(debounce_timeout, 0, function()
    vim.schedule(function()
      send_activity_update()
      debounce_timer:close()
      debounce_timer = nil
    end)
  end)
end

function M.cleanup()
  if debounce_timer then
    debounce_timer:stop()
    debounce_timer:close()
    debounce_timer = nil
  end
end

return M
