---@diagnostic disable: undefined-global
---
--- PeerManager: Handles peer registration, synchronization, and activity sharing.
---
--- @class PeerManager
--- @field peers table
--- @field socket string
--- @field workspace string|nil
--- @field workspaces table
--- @field log Logger
--- @field update function
--- @field call_remote_method function
--- @field cancel function
--- @field id string
--- @field options table
--- @field get_nvim_socket_paths function
--- @field register_peer function
--- @field unregister_peer function
--- @field unregister_peer_and_set_activity function
--- @field register_and_sync_peer function
--- @field register_self function
--- @field unregister_self function
--- @field sync_self function

local PeerManager = {}

function PeerManager.register_peer(self, id, socket)
    self.log:debug(string.format("Registering peer %s...", id))
    self.peers[id] = {
        socket = socket,
        workspace = nil,
    }
    self.log:info(string.format("Registered peer %s", id))
end

function PeerManager.unregister_peer(self, id, peer)
    self.log:debug(string.format("Unregistering peer %s... %s", id, vim.inspect(peer)))
    local should_remove_workspace = peer.workspace ~= self.workspace
    local peers = {}
    for peer_id, peer_data in pairs(self.peers) do
        if peer_id ~= id then
            peers[peer_id] = peer_data
            if should_remove_workspace and peer.workspace == peer_data.workspace then
                should_remove_workspace = false
            end
        end
    end
    self.peers = peers
    local workspaces = {}
    if should_remove_workspace then
        self.log:debug(string.format("Should remove workspace %s", peer.workspace))
        for workspace, data in pairs(self.workspaces) do
            if workspace ~= peer.workspace then
                workspaces[workspace] = data
            end
        end
        self.workspaces = workspaces
    end
    self.log:info(string.format("Unregistered peer %s", id))
end

function PeerManager.unregister_peer_and_set_activity(self, id, peer)
    self:unregister_peer(id, peer)
    self:update()
end

function PeerManager.register_and_sync_peer(self, id, socket)
    self:register_peer(id, socket)
    self.log:debug("Syncing data with newly registered peer...")
    local peers = {
        [self.id] = {
            socket = self.socket,
            workspace = self.workspace,
        }
    }
    for peer_id, peer in pairs(self.peers) do
        if peer_id ~= id then
            peers[peer_id] = peer
        end
    end
    self:call_remote_method(socket, "sync_self", { {
        last_activity = self.last_activity,
        peers = peers,
        workspaces = self.workspaces,
    } })
end

function PeerManager.register_self(self)
    self:get_nvim_socket_paths(function(sockets)
        if #sockets == 0 then
            self.log:debug("No other remote nvim instances")
            return
        end
        self.log:debug(string.format("Registering as a new peer to %d instance(s)...", #sockets))
        self:call_remote_method(sockets[1], "register_and_sync_peer", { self.id, self.socket })
        if #sockets == 1 then return end
        for i = 2, #sockets do
            self:call_remote_method(sockets[i], "register_peer", { self.id, self.socket })
        end
    end)
end

function PeerManager.unregister_self(self)
    local self_as_peer = {
        socket = self.socket,
        workspace = self.workspace,
    }
    local i = 1
    for id, peer in pairs(self.peers) do
        if self.options.auto_update and i == 1 then
            self.log:debug(string.format("Unregistering self and setting activity for peer %s...", id))
            self:call_remote_method(peer.socket, "unregister_peer_and_set_activity", { self.id, self_as_peer })
        else
            self.log:debug(string.format("Unregistering self to peer %s...", id))
            self:call_remote_method(peer.socket, "unregister_peer", { self.id, self_as_peer })
        end
        i = i + 1
    end
end

function PeerManager.sync_self(self, data)
    self.log:debug(string.format("Syncing data from remote peer...", vim.inspect(data)))
    for key, value in pairs(data) do
        self[key] = value
    end
    self.log:info("Synced runtime data from remote peer")
end

function PeerManager.sync_self_activity(self)
    local self_as_peer = {
        socket = self.socket,
        workspace = self.workspace,
    }
    for id, peer in pairs(self.peers) do
        self.log:debug(string.format("Syncing activity to peer %s...", id))
        local peers = { [self.id] = self_as_peer }
        for peer_id, peer_data in pairs(self.peers) do
            if peer_id ~= id then
                peers[peer_id] = {
                    socket = peer_data.socket,
                    workspace = peer_data.workspace,
                }
            end
        end
        self:call_remote_method(peer.socket, "sync_peer_activity", { {
            last_activity = self.last_activity,
            peers = peers,
            workspaces = self.workspaces,
        } })
    end
end

function PeerManager.sync_peer_activity(self, data)
    self.log:debug(string.format("Syncing peer activity %s...", vim.inspect(data)))
    self:cancel()
    self:sync_self(data)
end

return PeerManager
