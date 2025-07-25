---@diagnostic disable: undefined-global
---
--- Presence: Main entry point for Presence.nvim
---
--- @class Presence
--- @field PresenceManager PresenceManager
--- @field WorkspaceUtils WorkspaceUtils
--- @field PeerManager PeerManager
--- @field EventHandlers EventHandlers
--- @field Helpers Helpers
---

local PresenceManager = require("presence.internal.manager")
local DiscordClient = require("presence.internal.discord_client")
local WorkspaceUtils = require("presence.internal.workspace_utils")
local PeerManager = require("presence.internal.peer_manager")
local EventHandlers = require("presence.internal.event_handlers")
local Helpers = require("presence.internal.helpers")

PresenceManager.DiscordClient = DiscordClient
PresenceManager.WorkspaceUtils = WorkspaceUtils
PresenceManager.PeerManager = PeerManager
PresenceManager.EventHandlers = EventHandlers
PresenceManager.Helpers = Helpers

PresenceManager.handle_buf_enter = function(...)
    return EventHandlers.handle_buf_enter(PresenceManager, ...)
end
PresenceManager.handle_win_enter = function(...)
    return EventHandlers.handle_win_enter(PresenceManager, ...)
end
PresenceManager.handle_win_leave = function(...)
    return EventHandlers.handle_win_leave(PresenceManager, ...)
end
PresenceManager.handle_focus_gained = function(...)
    return EventHandlers.handle_focus_gained(PresenceManager, ...)
end
PresenceManager.handle_text_changed = function(...)
    return EventHandlers.handle_text_changed(PresenceManager, ...)
end
PresenceManager.handle_vim_leave_pre = function(...)
    return EventHandlers.handle_vim_leave_pre(PresenceManager, ...)
end
PresenceManager.handle_buf_add = function(...)
    return EventHandlers.handle_buf_add(PresenceManager, ...)
end
PresenceManager.handle_cursor_moved = function(...)
    return EventHandlers.handle_cursor_moved(PresenceManager, ...)
end

-- Returns Discord icon if connected, else empty string
function PresenceManager.statusline()
    if PresenceManager:is_connected() then
        return ' '
    else
        return ''
    end
end

if vim.api and vim.api.nvim_create_user_command then
    vim.api.nvim_create_user_command("PresenceDeactivate", function()
        PresenceManager:deactivate()
    end, { desc = "Deactivate Presence.nvim and disconnect from Discord" })
    vim.api.nvim_create_user_command("PresenceStatus", function()
        print(vim.inspect(PresenceManager:status()))
    end, { desc = "Show Presence.nvim status" })
    vim.api.nvim_create_user_command("PresenceReconnect", function()
        PresenceManager:reconnect()
    end, { desc = "Reconnect Presence.nvim to Discord" })
end

return PresenceManager
