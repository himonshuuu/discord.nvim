package internal

import (
	"time"

	richpresence "github.com/hugolgst/rich-go/client"
)

type Service interface {
	Connect(clientID string) error
	SetActivity(details, state, largeImage, largeText, smallImage, smallText string, start *time.Time) error
	Clear() error
}

type Client struct {
	connected bool
	clientID  string
}

func (c *Client) Connect(clientID string) error {
	if c.connected && c.clientID == clientID {
		return nil
	}
	if err := richpresence.Login(clientID); err != nil {
		return err
	}
	c.connected = true
	c.clientID = clientID
	return nil
}

func (c *Client) SetActivity(details, state, largeImage, largeText, smallImage, smallText string, start *time.Time) error {
	act := richpresence.Activity{
		State:      state,
		Details:    details,
		LargeImage: largeImage,
		LargeText:  largeText,
		SmallImage: smallImage,
		SmallText:  smallText,
	}
	if start != nil {
		act.Timestamps = &richpresence.Timestamps{Start: start}
	}
	return richpresence.SetActivity(act)
}

func (c *Client) Clear() error {
	return richpresence.SetActivity(richpresence.Activity{})
}
