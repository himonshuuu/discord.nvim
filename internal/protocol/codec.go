package protocol

import (
	"bufio"
	"encoding/json"
	"io"
)

type Codec struct {
	enc *json.Encoder
	dec *json.Decoder
	bw  *bufio.Writer
}

func NewCodec(r io.Reader, w io.Writer) *Codec {
	br := bufio.NewReader(r)
	bw := bufio.NewWriter(w)
	return &Codec{
		enc: json.NewEncoder(bw),
		dec: json.NewDecoder(br),
		bw:  bw,
	}
}

func (c *Codec) ReadMessage() (InboundMessage, error) {
	var raw map[string]json.RawMessage
	if err := c.dec.Decode(&raw); err != nil {
		return InboundMessage{}, err
	}
	var msg InboundMessage
	if v, ok := raw["action"]; ok {
		_ = json.Unmarshal(v, &msg.Action)
	}
	if v, ok := raw["payload"]; ok {
		msg.Payload = jsonRaw(v)
	}
	return msg, nil
}

func (c *Codec) WriteJSON(v any) error {
	if err := c.enc.Encode(v); err != nil {
		return err
	}
	return c.bw.Flush()
}
