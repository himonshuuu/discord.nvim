---@diagnostic disable: undefined-global
---
--- Helpers: General helper functions for Presence
---
--- @class Helpers
--- @field get_os_name function
--- @field coalesce_option function

local Utils = {}

function Utils.get_os_name(uname)
    if uname.sysname:find("Windows") then
        return "windows"
    elseif uname.sysname:find("Darwin") then
        return "macos"
    elseif uname.sysname:find("Linux") then
        return "linux"
    end
    return "unknown"
end

function Utils.coalesce_option(value)
    if type(value) == "boolean" then
        return value and 1 or 0
    end
    return value
end

return Utils
