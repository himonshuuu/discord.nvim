---@diagnostic disable: undefined-global
---
--- PresenceManager: Main orchestrator for Discord Rich Presence in Neovim.
---
--- @class PresenceManager
--- @field is_authorized boolean
--- @field is_authorizing boolean
--- @field is_connected boolean
--- @field is_connecting boolean
--- @field last_activity table
--- @field peers table
--- @field socket string
--- @field workspace string|nil
--- @field workspaces table
--- @field options table
--- @field log Logger


local log = require("lib.log")
local default_file_assets = require("presence.assets")
local Helpers = require("presence.internal.helpers")

local PresenceManager = {}
PresenceManager.is_authorized = false
PresenceManager.is_authorizing = false
PresenceManager.is_connected = false
PresenceManager.is_connecting = false
PresenceManager.last_activity = {}
PresenceManager.peers = {}
PresenceManager.socket = vim.v.servername
PresenceManager.workspace = nil
PresenceManager.workspaces = {}

--- Set an option, with validation and fallback to global or default.
--- @param option string
--- @param default any
--- @param validate boolean|nil
function PresenceManager:set_option(option, default, validate)
    default = Helpers.coalesce_option(default)
    validate = validate == nil and true or validate
    local g_variable = string.format("presence_%s", option)
    self.options[option] = Helpers.coalesce_option(self.options[option])
    if validate then
        self:check_dup_options(option)
    end
    self.options[option] = self.options[option] or vim.g[g_variable] or default
end

--- Warn if both global and setup options are set for the same key.
--- @param option string
function PresenceManager:check_dup_options(option)
    local g_variable = string.format("presence_%s", option)
    if self.options[option] ~= nil and vim.g[g_variable] ~= nil then
        local warning_fmt = "Duplicate options: `g:%s` and setup option `%s`"
        local warning_msg = string.format(warning_fmt, g_variable, option)
        self.log:warn(warning_msg)
    end
end

--- Find the Discord socket from temp runtime directories
--- @return string|nil
function PresenceManager:get_discord_socket_path()
    local sock_name = "discord-ipc-0"
    local sock_path = nil

    if self.os.is_wsl then
        -- Use socket created by relay for WSL
        sock_path = "/var/run/" .. sock_name
    elseif self.os.name == "windows" then
        -- Use named pipe in NPFS for Windows
        sock_path = [[\\.\pipe\]] .. sock_name
    elseif self.os.name == "macos" then
        -- Use $TMPDIR for macOS
        local path = os.getenv("TMPDIR")
        if path then
            sock_path = path:match("/$") and path .. sock_name or path .. "/" .. sock_name
        end
    elseif self.os.name == "linux" then
        -- Check various temp directory environment variables
        local env_vars = { "XDG_RUNTIME_DIR", "TEMP", "TMP", "TMPDIR" }
        for i = 1, #env_vars do
            local var = env_vars[i]
            local path = os.getenv(var)
            if path then
                self.log:debug(string.format("Using runtime path: %s", path))
                sock_path = path:match("/$") and path .. sock_name or path .. "/" .. sock_name
                break
            end
        end
    end

    return sock_path
end

--- Check the Discord socket at the given path
--- @param path string
function PresenceManager:check_discord_socket(path)
    self.log:debug(string.format("Checking Discord IPC socket at %s...", path))

    -- Asynchronously check socket path via stat
    vim.loop.fs_stat(path, function(err, stats)
        if err then
            local err_msg = "Failed to get socket information"
            self.log:error(string.format("%s: %s", err_msg, err))
            return
        end

        if stats.type ~= "socket" then
            local warning_msg = "Found unexpected Discord IPC socket type"
            self.log:warn(string.format("%s: %s", warning_msg, err))
            return
        end

        self.log:debug("Checked Discord IPC socket, looks good!")
    end)
end

--- Setup the PresenceManager with user configuration.
--- @param options table|nil
function PresenceManager:setup(options)
    options = options or {}
    self.options = options
    self:set_option("log_level", nil, false)
    self.log = log:init({ level = "debug" })
    local uname = vim.loop.os_uname()
    local separator = package.config:sub(1, 1)
    local wsl_distro_name = os.getenv("WSL_DISTRO_NAME")
    local os_name = Helpers.get_os_name(uname)
    self.os = {
        name = os_name,
        is_wsl = uname.release:lower():find("microsoft") ~= nil,
        path_separator = separator,
    }
    local setup_message_fmt = "Setting up plugin for %s"
    if self.os.name then
        local setup_message = self.os.is_wsl
            and string.format(setup_message_fmt .. " in WSL (%s)", self.os.name, vim.inspect(wsl_distro_name))
            or string.format(setup_message_fmt, self.os.name)
        self.log:debug(setup_message)
    else
        self.log:error(string.format("Unable to detect operating system: %s", vim.inspect(vim.loop.os_uname())))
    end
    if options.client_id then
        self.log:info("Using user-defined Discord client id")
    end
    self:set_option("auto_update", 1)
    self:set_option("client_id", "1173975703046340789")
    self:set_option("debounce_timeout", 10)
    self:set_option("idle_timeout", 300)
    self:set_option("idle_treatment", "update")
    self:set_option("main_image", "neovim")
    self:set_option("neovim_image_text", "Neovim")
    self:set_option("enable_line_number", true)
    self:set_option("editing_text", "Editing %s")
    self:set_option("file_explorer_text", "Browsing %s")
    self:set_option("git_commit_text", "Committing changes")
    self:set_option("plugin_manager_text", "Managing plugins")
    self:set_option("reading_text", "Reading %s")
    self:set_option("workspace_text", "Working on %s")
    self:set_option("line_number_text", "Line %s out of %s")
    self:set_option("idling_text", "Idling...")
    self:set_option("blacklist", {})
    self:set_option("buttons", true)
    self:set_option("file_assets", {})
    self:set_option("log_level", "debug", false)
    for name, asset in pairs(default_file_assets) do
        if not self.options.file_assets[name] then
            self.options.file_assets[name] = asset
        end
    end

    -- Initialize Discord client
    local discord_socket_path = self:get_discord_socket_path()
    if discord_socket_path then
        self.log:debug(string.format("Using Discord IPC socket path: %s", discord_socket_path))
        self:check_discord_socket(discord_socket_path)
    else
        self.log:error("Failed to determine Discord IPC socket path")
    end

    -- Initialize Discord client
    local DiscordClient = require("presence.internal.discord_client")
    self.discord = DiscordClient:init({
        logger = self.log,
        client_id = self.options.client_id,
        ipc_socket = discord_socket_path,
    })

    -- Initialize peer manager
    local PeerManager = require("presence.internal.peer_manager")
    self.peer_manager = PeerManager

    -- Seed instance id using unique socket path
    local seed_nums = {}
    self.socket:gsub(".", function(c) table.insert(seed_nums, c:byte()) end)
    self.id = self.discord.generate_uuid(tonumber(table.concat(seed_nums)) / os.clock())
    self.log:debug(string.format("Using id %s", self.id))

    -- Connect to Discord
    self:connect_to_discord()

    vim.api.nvim_set_var("presence_auto_update", options.auto_update)
    vim.fn["presence#SetAutoCmds"]()
    self.log:info("Completed plugin setup")
    vim.api.nvim_set_var("presence_has_setup", 1)
    return self
end

--- Deactivate the plugin, cleaning up timers, Discord, peers, and autocommands.
function PresenceManager:deactivate()
    if self.idle_timer then
        vim.fn.timer_stop(self.idle_timer)
        self.idle_timer = nil
    end
    if self.discord and self.discord.disconnect then
        self.discord:disconnect(function()
            self.log:info("Disconnected from Discord (deactivate)")
        end)
    end
    if self.unregister_self then
        self:unregister_self()
    end
    if vim.api and vim.api.nvim_del_augroup_by_name then
        pcall(vim.api.nvim_del_augroup_by_name, "Presence")
    end
    pcall(vim.api.nvim_del_var, "presence_has_setup")
    pcall(vim.api.nvim_del_var, "presence_auto_update")
    self.log:info("Presence.nvim deactivated.")
end

--- Get the current status of the plugin.
--- @return table
function PresenceManager:status()
    return {
        is_connecting = self.is_connecting,
        is_connected = self.is_connected,
        is_authorizing = self.is_authorizing,
        is_authorized = self.is_authorized,
        workspace = self.workspace,
        socket = self.socket,
        peers = vim.tbl_keys(self.peers or {}),
        last_activity = self.last_activity,
    }
end

--- Reconnect to Discord manually.
function PresenceManager:reconnect()
    self.log:info("Manually reconnecting to Discord...")
    self:connect_to_discord()
end

--- Connect to Discord and authorize the client
function PresenceManager:connect_to_discord()
    if not self.discord then
        self.log:error("Discord client not initialized")
        return
    end

    self.log:info("Connecting to Discord...")
    self.is_connecting = true

    self.discord:connect(function(err)
        self.is_connecting = false

        -- Handle known connection errors
        if err == "EISCONN" then
            self.log:info("Already connected to Discord")
            self.is_connected = true
            self:authorize_discord()
        elseif err == "ECONNREFUSED" then
            self.log:warn("Failed to connect to Discord: " .. err .. " (is Discord running?)")
            return
        elseif err then
            self.log:error("Failed to connect to Discord: " .. err)
            return
        else
            self.log:info("Connected to Discord")
            self.is_connected = true
            self:authorize_discord()
        end
    end)
end

--- Authorize with Discord
function PresenceManager:authorize_discord()
    if not self.discord then
        self.log:error("Discord client not initialized")
        return
    end

    self.log:info("Authorizing with Discord...")
    self.is_authorizing = true

    self.discord:authorize(function(err, response)
        self.is_authorizing = false

        if err and err:find(".*already did handshake.*") then
            self.log:info("Already authorized with Discord")
            self.is_authorized = true
        elseif err then
            self.log:error("Failed to authorize with Discord: " .. err)
            self.is_authorized = false
        else
            self.log:info(string.format("Authorized with Discord for %s", response.data.user.username))
            self.is_authorized = true
        end
    end)
end

--- Update Discord presence for the current buffer.
--- @param buffer string|nil
--- @param should_debounce boolean|nil
function PresenceManager:update(buffer, should_debounce)
    if not self.discord then
        self.log:debug("Discord client not initialized, skipping update")
        return
    end

    -- Get current buffer if not provided
    buffer = buffer or self.WorkspaceUtils.get_current_buffer()

    -- Get file information
    local filename = self.WorkspaceUtils.get_filename(buffer, self.os.path_separator)
    local parent_dirpath = self.WorkspaceUtils.get_dir_path(buffer, self.os.path_separator)
    local extension = filename and self.WorkspaceUtils.get_file_extension(filename) or nil

    -- Get project information
    local project_name, project_path = self.WorkspaceUtils.get_project_name(parent_dirpath, self.os.name,
        self.os.path_separator, self.log)

    -- Determine status text based on file type
    local status_text = "Editing"
    if vim.bo.filetype == "gitcommit" then
        status_text = "Committing changes"
    elseif vim.bo.filetype == "netrw" or vim.bo.filetype == "nerdtree" then
        status_text = "Browsing files"
    elseif not vim.bo.modifiable or vim.bo.readonly then
        status_text = "Reading"
    end

    -- Get file icon/asset
    local asset_key = "code"
    if extension and self.options.file_assets.KNOWN_EXTENSIONS and self.options.file_assets.KNOWN_EXTENSIONS["." .. extension] then
        asset_key = self.options.file_assets.KNOWN_EXTENSIONS["." .. extension].image
    elseif vim.bo.filetype and self.options.file_assets.KNOWN_LANGUAGES then
        for _, lang in ipairs(self.options.file_assets.KNOWN_LANGUAGES) do
            if lang.language == vim.bo.filetype then
                asset_key = lang.image
                break
            end
        end
    end

    -- Create activity data
    local activity = {
        state = string.format("%s %s", status_text, filename or "unnamed buffer"),
        details = project_name and string.format("Working on %s", project_name) or "Working on a project",
        assets = {
            large_image = asset_key,
            large_text = filename or "unnamed buffer",
            small_image = "neovim",
            small_text = "Neovim",
        },
        timestamps = {
            start = os.time(),
        },
    }

    -- Update last activity
    self.last_activity = {
        file = buffer,
        set_at = os.time(),
        workspace = project_path,
    }

    if self.discord.set_activity then
        self.discord:set_activity(activity, function(err)
            if err then
                self.log:error(string.format("Failed to set activity in Discord: %s", err))
            else
                self.log:info("Updated Discord presence")
            end
        end)
    end
end

--- Cancel current Discord presence.
function PresenceManager:cancel()
    if not self.discord then
        self.log:debug("Discord client not initialized, skipping cancel")
        return
    end

    if self.discord.set_activity then
        self.discord:set_activity(nil, function(err)
            if err then
                self.log:error(string.format("Failed to cancel activity in Discord: %s", err))
            else
                self.log:info("Canceled Discord presence")
            end
        end)
    end
end

--- Unregister self from all peers.
function PresenceManager:unregister_self()
    if not self.peer_manager then
        self.log:debug("Peer manager not initialized, skipping unregister")
        return
    end

    if self.peer_manager.unregister_self then
        self.peer_manager.unregister_self(self)
        self.log:info("Unregistered self from all peers")
    end
end

return PresenceManager
