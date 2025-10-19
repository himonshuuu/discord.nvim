package handler

import (
	"encoding/json"

	"github.com/himonshuuu/presence.nvim/daemon/internal/presence"
	"github.com/himonshuuu/presence.nvim/daemon/internal/protocol"
)

type Handler struct {
	client presence.Service
}

func New(client presence.Service) *Handler {
	return &Handler{client: client}
}

func (h *Handler) Handle(msg protocol.InboundMessage) protocol.BasicResponse {
	switch msg.Action {
	case "init":
		var p protocol.InitPayload
		if err := json.Unmarshal(msg.Payload, &p); err != nil {
			return protocol.BasicResponse{Ok: false, Error: err.Error()}
		}
		if err := h.client.Connect(p.ClientID); err != nil {
			return protocol.BasicResponse{Ok: false, Error: err.Error()}
		}
		return protocol.BasicResponse{Ok: true}
	case "set_activity":
		var p protocol.ActivityPayload
		if err := json.Unmarshal(msg.Payload, &p); err != nil {
			return protocol.BasicResponse{Ok: false, Error: err.Error()}
		}
		if err := h.client.SetActivity(
			p.Details, p.State, p.LargeImage, p.LargeText, p.SmallImage, p.SmallText, p.StartAtTime(),
		); err != nil {
			return protocol.BasicResponse{Ok: false, Error: err.Error()}
		}
		return protocol.BasicResponse{Ok: true}
	case "clear":
		if err := h.client.Clear(); err != nil {
			return protocol.BasicResponse{Ok: false, Error: err.Error()}
		}
		return protocol.BasicResponse{Ok: true}
	default:
		return protocol.BasicResponse{Ok: false, Error: "unknown action"}
	}
}
