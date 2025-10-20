-- Icon lookup helper
local M = {}

local data = require("deps.icons")
local exts = data.KNOWN_EXTENSIONS or {}
local langs = {}

for _, v in ipairs(data.KNOWN_LANGUAGES or {}) do
  langs[v.language] = v.image
end

function M.icon_for_filename(filename)
  if not filename or filename == "" then return "text" end
  
  local basename = vim.fn.fnamemodify(filename, ":t")
  local match = exts[basename] or exts[basename:lower()]
  if match then return match.image end
  
  local ext = basename:match("(%.[^%.]+)$")
  if ext then
    match = exts[ext] or exts[ext:lower()]
    if match then return match.image end
  end
  
  return "text"
end

function M.icon_for_any(filetype, filename)
  if filetype and langs[filetype] then
    return langs[filetype]
  end
  return M.icon_for_filename(filename)
end

return M
