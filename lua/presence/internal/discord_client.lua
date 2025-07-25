-- discord.lua: Discord connection and activity logic
-- This module handles Discord RPC connection, authorization, and activity updates.

---@diagnostic disable: undefined-global

local ok_struct, struct = pcall(require, "deps.struct")
local ok_msgpack, msgpack = pcall(require, "deps.msgpack")
local ok_serpent, serpent = pcall(require, "deps.serpent")
if not (ok_struct and ok_msgpack and ok_serpent) then
    vim.schedule(function()
        vim.notify(
            "[presence.nvim] Warning: Missing required dependencies (struct, msgpack, or serpent). Discord integration will not work.",
            vim.log.levels.ERROR)
    end)
    return {}
end

local DiscordClient = {}

DiscordClient.opcodes = {
    auth = 0,
    frame = 1,
    closed = 2,
}
DiscordClient.events = {
    READY = "READY",
    ERROR = "ERROR",
}

function DiscordClient:init(options)
    self.log = options.logger
    self.client_id = options.client_id
    self.ipc_socket = options.ipc_socket
    self.pipe = vim.loop.new_pipe(false)
    self.reading_started = false
    self.pending_requests = {}
    return self
end

function DiscordClient:connect(on_connect)
    if self.pipe:is_closing() then
        self.pipe = vim.loop.new_pipe(false)
    end
    self.pipe:connect(self.ipc_socket, on_connect)
end

function DiscordClient:is_connected()
    return self.pipe:is_active()
end

function DiscordClient:disconnect(on_close)
    self.pipe:shutdown()
    if not self.pipe:is_closing() then
        self.pipe:close(on_close)
    end
end

function DiscordClient:call(opcode, payload, on_response)
    -- Always generate a nonce for every request
    if not payload.nonce then
        payload.nonce = DiscordClient.generate_uuid()
    end
    self.pending_requests[payload.nonce] = on_response
    DiscordClient.encode_json(payload, function(success, body)
        if not success then
            self.log:warn(string.format("Failed to encode payload: %s", vim.inspect(body)))
            return
        end
        -- Only start reading once
        if not self.reading_started then
            self.pipe:read_start(function(err, chunk)
                self:read_message(err, chunk)
            end)
            self.reading_started = true
        end
        local message = struct.pack("<ii", opcode, #body) .. body
        self.pipe:write(message, function(err)
            if err then
                local err_format = "Pipe write error - %s"
                local err_message = string.format(err_format, err)
                if tostring(err):find("EPIPE") then
                    self.log:error("[presence.nvim] Pipe broken (EPIPE), attempting to reconnect...")
                    -- Only retry once per call to avoid infinite loops
                    if payload._has_retried then
                        self.log:error("[presence.nvim] Already retried after EPIPE, aborting.")
                        on_response(err_message)
                        return
                    end
                    payload._has_retried = true
                    self:disconnect(function()
                        self:connect(function(connect_err)
                            if connect_err then
                                self.log:error("Reconnect failed: " .. tostring(connect_err))
                                on_response(err_message)
                            else
                                self.log:debug("Reconnected to Discord, retrying activity update...")
                                -- Retry the original call
                                self:call(opcode, payload, on_response)
                            end
                        end)
                    end)
                else
                    on_response(err_message)
                end
            else
                self.log:debug("Wrote message to pipe")
            end
        end)
    end)
end

function DiscordClient:read_message(err, chunk)
    if err then
        local err_format = "Pipe read error - %s"
        local err_message = string.format(err_format, err)
        self.log:error(err_message)
        return
    elseif chunk then
        local message = chunk:match("({.+)")
        local response_opcode = struct.unpack("<ii", chunk)
        DiscordClient.decode_json(message, function(success, response)
            if response_opcode ~= self.opcodes.frame then
                local err_format = "Received unexpected opcode - %s (code %s)"
                local err_message = string.format(err_format, response and response.message or "?",
                    response and response.code or "?")
                self.log:error(err_message)
                return
            end
            if not success then
                self.log:warn(string.format("Failed to decode payload: %s", vim.inspect(message)))
                return
            end
            if response.evt == self.events.ERROR then
                local data = response.data
                local err_format = "Received error event - %s (code %s)"
                local err_message = string.format(err_format, data.message, data.code)
                if response.nonce and self.pending_requests[response.nonce] then
                    self.pending_requests[response.nonce](err_message)
                    self.pending_requests[response.nonce] = nil
                else
                    self.log:error(err_message)
                end
                return
            end
            if response.nonce and self.pending_requests[response.nonce] then
                self.pending_requests[response.nonce](nil, response)
                self.pending_requests[response.nonce] = nil
            else
                self.log:warn(string.format("Received response with unknown or missing nonce: %s", vim.inspect(response)))
            end
        end)
    else
        self.log:warn("Pipe was closed")
    end
end

function DiscordClient:authorize(on_authorize)
    local payload = {
        client_id = self.client_id,
        v = 1,
        nonce = DiscordClient.generate_uuid(),
    }
    self:call(self.opcodes.auth, payload, on_authorize)
end

function DiscordClient:set_activity(activity, on_response)
    local payload = {
        cmd = "SET_ACTIVITY",
        nonce = DiscordClient.generate_uuid(),
        args = {
            activity = activity,
            pid = vim.loop:os_getpid(),
        },
    }
    self:call(self.opcodes.frame, payload, on_response)
end

function DiscordClient.generate_uuid(seed)
    local index = 0
    local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    local uuid = template:gsub("[xy]", function(char)
        index = index + 1
        math.randomseed((seed or os.clock()) / index)
        local n = char == "x" and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format("%x", n)
    end)
    return uuid
end

function DiscordClient.decode_json(t, on_done)
    vim.schedule(function()
        on_done(pcall(function()
            return vim.fn.json_decode(t)
        end))
    end)
end

function DiscordClient.encode_json(t, on_done)
    vim.schedule(function()
        on_done(pcall(function()
            return vim.fn.json_encode(t)
        end))
    end)
end

return DiscordClient
