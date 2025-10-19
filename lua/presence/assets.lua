local M = {}

local known_extensions = {}
local known_languages = {}

-- Make these accessible for debugging
M.known_extensions = known_extensions
M.known_languages = known_languages

function M.load()
  local icons = require("presence.icons")
  known_extensions = {}
  known_languages = {}
  
  if icons.KNOWN_LANGUAGES then
    for _, lang_data in ipairs(icons.KNOWN_LANGUAGES) do
      known_languages[lang_data.language] = true
    end
  end
  
  if icons.KNOWN_EXTENSIONS then
    known_extensions = icons.KNOWN_EXTENSIONS
  end
end

function M.icon_for_filename(filename)
  if not filename or filename == "" then
    return "text"
  end
  
  local basename = vim.fn.fnamemodify(filename, ":t")
  local basename_lower = basename:lower()
  
  -- First pass: exact matches (most common case, fastest)
  local match = known_extensions[basename]
  if match then
    return match.image
  end
  
  -- Second pass: case-insensitive exact matches
  match = known_extensions[basename_lower]
  if match then
    return match.image
  end
  
  -- Third pass: extension-based matches
  local ext = basename:match("(%.[^%.]+)$")
  if ext then
    match = known_extensions[ext]
    if match then
      return match.image
    end
    
    -- Try lowercase extension
    match = known_extensions[ext:lower()]
    if match then
      return match.image
    end
  end
  
  -- Fourth pass: complex patterns (stored as table keys with pattern field)
  -- This handles the regex-like patterns from the original JSON
  local patterns_to_check = {}
  
  for key, value in pairs(known_extensions) do
    if type(key) == "table" and key.pattern then
      table.insert(patterns_to_check, {
        pattern = key.pattern,
        caseless = key.caseless,
        image = value.image
      })
    end
  end
  
  -- Sort by pattern length for better specificity matching
  table.sort(patterns_to_check, function(a, b)
    return #a.pattern > #b.pattern
  end)
  
  for _, entry in ipairs(patterns_to_check) do
    local test_string = entry.caseless and basename_lower or basename
    local pattern = entry.caseless and entry.pattern:lower() or entry.pattern
    
    -- Convert regex pattern to Lua pattern
    -- Handle common cases from the original regex patterns
    local lua_pattern = pattern
      :gsub("%(?:", "(")  -- Convert non-capturing groups to capturing groups
      :gsub("%-", "%%-")  -- Escape hyphens
      -- Note: %. in regex already means literal dot, same as Lua, so no conversion needed
    
    if test_string:match(lua_pattern) then
      return entry.image
    end
  end
  
  -- Fallback to text
  return "text"
end

-- Backwards compatibility: keep the old signature and delegate
function M.icon_for_any(filetype, filename)
  -- Check if we have a language mapping for the filetype
  if filetype and known_languages[filetype] then
    -- Find the image for this language
    local icons = require("presence.icons")
    if icons.KNOWN_LANGUAGES then
      for _, lang_data in ipairs(icons.KNOWN_LANGUAGES) do
        if lang_data.language == filetype then
          return lang_data.image
        end
      end
    end
  end
  
  -- Fall back to filename-based detection
  return M.icon_for_filename(filename)
end

return M