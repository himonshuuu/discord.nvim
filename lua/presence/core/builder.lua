local M = {}

local assets = require("presence.assets")
local state = require("presence.state")

function M.build_activity(mode)
  local buf = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(buf)
  local ft = vim.bo[buf].filetype or "plaintext"
  local icon = assets.icon_for_filename(name)
  local details
  local cursor = vim.api.nvim_win_get_cursor(0)
  local filename = (name ~= "" and vim.fn.fnamemodify(name, ":t") or "untitled")
  local pos = string.format("%s:%d:%d", filename, cursor[1], cursor[2] + 1)
  local root = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")

  local problems = M.get_diagnostic_count(buf)

  if mode == "editing" then
    details = string.format("📁 %s - %d problems found", root, problems)
  elseif mode == "viewing" then
    details = string.format("📁 %s - %d problems found", root, problems)
  else
    details = string.format("📁 %s - %d problems found", root, problems)
  end
  
  local state_text = "📄 " .. pos
  
  return {
    details = details,
    state = state_text,
    large_image = icon,
    large_text = ft,
    small_image = mode == "idle" and "idle" or "neovim",
    small_text = "Neovim",
    start_at = state.get_start_at(),
    session_id = state.get_session_id(),
  }
end

function M.get_diagnostic_count(buf)
  local problems = 0
  if vim.diagnostic and vim.diagnostic.get then
    local diags = vim.diagnostic.get(buf) or {}
    problems = #diags
  end
  return problems
end

function M.format_activity_for_daemon(activity, config)
  local formatted = vim.tbl_deep_extend("force", activity, {})
  
  if not config.show_timer then 
    formatted.start_at = 0 
  end
  
  return formatted
end

return M
