---@diagnostic disable: undefined-global

---
--- WorkspaceUtils: Utility functions for workspace operations.
---
--- @class WorkspaceUtils
--- @field get_current_buffer function
--- @field get_project_name function
--- @field get_dir_path function
--- @field get_filename function
--- @field get_file_extension function
local WorkspaceUtils = {}

function WorkspaceUtils.get_current_buffer()
    local current_buffer = vim.api.nvim_get_current_buf()
    return vim.api.nvim_buf_get_name(current_buffer)
end

function WorkspaceUtils.get_project_name(file_path, os_name, path_separator, log)
    if not file_path then
        return nil
    end
    file_path = file_path:gsub('"', '\"')
    local project_path_cmd = "git rev-parse --show-toplevel"
    project_path_cmd = file_path and string.format([[cd "%s" && %s]], file_path, project_path_cmd) or project_path_cmd
    local project_path = vim.fn.system(project_path_cmd)
    project_path = vim.trim(project_path)
    if project_path:find("fatal.*") then
        if log then log:info("Not a git repository, skipping...") end
        return nil
    end
    if vim.v.shell_error ~= 0 or #project_path == 0 then
        if log then
            local message_fmt = "Failed to get project name (error code %d): %s"
            log:error(string.format(message_fmt, vim.v.shell_error, project_path))
        end
        return nil
    end
    if os_name == "windows" then
        project_path = project_path:gsub("/", [[\]])
    end
    return WorkspaceUtils.get_filename(project_path, path_separator), project_path
end

function WorkspaceUtils.get_dir_path(path, path_separator)
    return path:match(string.format("^(.+%s.+)%s.*$", path_separator, path_separator))
end

function WorkspaceUtils.get_filename(path, path_separator)
    return path:match(string.format("^.+%s(.+)$", path_separator))
end

function WorkspaceUtils.get_file_extension(path)
    return path:match("^.+%.(.+)$")
end

return WorkspaceUtils
