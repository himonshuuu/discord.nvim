---@diagnostic disable: undefined-global
---
--- EventHandlers: Handles all Neovim event callbacks for Presence.
---
--- @class EventHandlers
--- @field last_activity table
--- @field options table
--- @field idle_timer number|nil
--- @field log Logger
--- @field update function
--- @field unregister_self function
--- @field cancel function


local EventHandlers = {}

--- @class Logger
--- @field debug function

local function is_quickfix()
    return vim.bo.filetype == "qf"
end

function EventHandlers.handle_focus_gained(self, ...)
    self.log:debug("Handling FocusGained event...")
    if next(self.last_activity) == nil and os.getenv("TMUX") then
        self.log:debug("Skipping presence update for FocusGained event triggered by tmux...")
        return
    end
    if is_quickfix() then
        self.log:debug("Skipping presence update for quickfix window...")
        return
    end
    self:update()
end

function EventHandlers.handle_text_changed(self, ...)
    self.log:debug("Handling TextChanged event...")
    self:update(nil, true)
end

function EventHandlers.handle_vim_leave_pre(self, ...)
    self.log:debug("Handling VimLeavePre event...")
    self:unregister_self()
    self:cancel()
end

function EventHandlers.handle_win_enter(self, ...)
    self.log:debug("Handling WinEnter event...")
    vim.schedule(function()
        if is_quickfix() then
            self.log:debug("Skipping presence update for quickfix window...")
            return
        end
        self:update()
    end)
end

function EventHandlers.handle_win_leave(self, ...)
    self.log:debug("Handling WinLeave event...")
    local current_window = vim.api.nvim_get_current_win()
    vim.schedule(function()
        if is_quickfix() then
            self.log:debug("Not canceling presence due to switching to quickfix window...")
            return
        end
        if current_window ~= vim.api.nvim_get_current_win() then
            self.log:debug("Not canceling presence due to switching to a window within the same instance...")
            return
        end
        self.log:debug("Canceling presence due to leaving window...")
        self:cancel()
    end)
end

function EventHandlers.handle_buf_enter(self, ...)
    self.log:debug("Handling BufEnter event...")
    if is_quickfix() then
        self.log:debug("Skipping presence update for quickfix window...")
        return
    end
    self:update()
end

function EventHandlers.handle_buf_add(self, ...)
    self.log:debug("Handling BufAdd event...")
    vim.schedule(function()
        if is_quickfix() then
            self.log:debug("Skipping presence update for quickfix window...")
            return
        end
        self:update()
    end)
end

function EventHandlers.handle_cursor_moved(self, ...)
    self.log:debug("Handling CursorMoved event...")
    if not self.options.idle_treatment then
        self.log:debug("Skipping treatment for idle state...")
        return
    end
    if not self.idle_timer then
        self.idle_timer = vim.fn.timer_start(self.options.idle_timeout * 1000, function()
            print("this is the idletimer :)")
        end)
    end
end

return EventHandlers
