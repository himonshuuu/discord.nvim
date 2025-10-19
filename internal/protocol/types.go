package protocol

import "time"

type InboundMessage struct {
	Action  string  `json:"action"`
	Payload jsonRaw `json:"payload"`
}

// jsonRaw is a small alias to avoid importing encoding/json here.
type jsonRaw []byte

type InitPayload struct {
	ClientID  string `json:"client_id"`
	SessionID string `json:"session_id,omitempty"`
}

type ActivityPayload struct {
	SessionID  string `json:"session_id,omitempty"`
	State      string `json:"state"`
	Details    string `json:"details"`
	LargeImage string `json:"large_image"`
	LargeText  string `json:"large_text"`
	SmallImage string `json:"small_image"`
	SmallText  string `json:"small_text"`
	StartAt    int64  `json:"start_at"`
}

func (a ActivityPayload) StartAtTime() *time.Time {
	if a.StartAt <= 0 {
		return nil
	}
	t := time.Unix(a.StartAt, 0)
	return &t
}

type BasicResponse struct {
	Ok    bool   `json:"ok"`
	Error string `json:"error,omitempty"`
}
