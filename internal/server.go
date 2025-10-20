package internal

import (
	"errors"
	"io"
	"log"
	"os"

	// "os/exec"
	"sync"
	"sync/atomic"
	"syscall"
	"time"

	msgpack "github.com/vmihailenco/msgpack/v5"
)

type Server struct {
	wg            sync.WaitGroup
	client        Service
	closed        chan struct{}
	activeClients int32
	shuttingDown  atomic.Bool
	debug         bool
	logger        *log.Logger
}

func New(client Service) *Server {
	debug := os.Getenv("DISCORD_NVIM_DEBUG") == "1"
	logger := log.New(os.Stderr, "[discord-nvim] ", log.LstdFlags|log.Lshortfile)

	return &Server{
		client: client,
		closed: make(chan struct{}),
		debug:  debug,
		logger: logger,
	}
}

type message struct {
	Type       string `msgpack:"type"`
	ClientID   string `msgpack:"client_id,omitempty"`
	Details    string `msgpack:"details,omitempty"`
	State      string `msgpack:"state,omitempty"`
	LargeImage string `msgpack:"large_image,omitempty"`
	LargeText  string `msgpack:"large_text,omitempty"`
	SmallImage string `msgpack:"small_image,omitempty"`
	SmallText  string `msgpack:"small_text,omitempty"`
	StartAt    int64  `msgpack:"start_at,omitempty"`
}

func (s *Server) Start() error {
	if s.debug {
		s.logger.Println("Starting discord-nvim daemon")
	}

	s.wg.Add(1)
	go func() {
		defer s.wg.Done()
		dec := msgpack.NewDecoder(os.Stdin)
		for {
			var msg *message
			if err := dec.Decode(&msg); err != nil {
				if errors.Is(err, io.EOF) {
					if s.debug {
						s.logger.Println("Received EOF, shutting down")
					}
					s.Kill()
					return
				}
				if s.debug {
					s.logger.Printf("Decode error: %v", err)
				}
				select {
				case <-s.closed:
					return
				default:
				}
				continue
			}

			if s.debug {
				s.logger.Printf("Received message: type=%s", msg.Type)
			}

			_ = atomic.AddInt32(&s.activeClients, 1)
			_ = atomic.AddInt32(&s.activeClients, -1)

			if err := s.handleMessage(msg); err != nil {
				if s.debug {
					s.logger.Printf("Error handling message: %v", err)
				}
			} else if s.debug {
				s.logger.Printf("Successfully handled message: type=%s", msg.Type)
			}

			if s.shuttingDown.Load() {
				s.Kill()
				return
			}
		}
	}()
	return nil
}

func (s *Server) handleMessage(msg *message) error {

	// _ = exec.Command("notify-send", msg.Type).Run()
	// _ = exec.Command("notify-send", msg.State).Run()
	// _ = exec.Command("notify-send", msg.Details).Run()

	switch msg.Type {
	case "INIT":
		if s.debug {
			s.logger.Printf("Handling INIT with client_id=%s", msg.ClientID)
		}
		if msg.ClientID == "" {
			return errors.New("missing client id")
		}
		if err := s.client.Connect(msg.ClientID); err != nil {
			if s.debug {
				s.logger.Printf("Failed to connect to Discord: %v", err)
			}
			return err
		}
		if s.debug {
			s.logger.Println("Successfully connected to Discord")
		}
		return nil
	case "ACT":
		if s.debug {
			s.logger.Printf("Handling ACT: details=%s, state=%s, large_image=%s",
				msg.Details, msg.State, msg.LargeImage)
		}
		var startTimePtr *time.Time
		if msg.StartAt != 0 {
			t := time.Unix(msg.StartAt, 0)
			startTimePtr = &t
		}
		if err := s.client.SetActivity(
			msg.Details,
			msg.State,
			msg.LargeImage,
			msg.LargeText,
			msg.SmallImage,
			msg.SmallText,
			startTimePtr,
		); err != nil {
			if s.debug {
				s.logger.Printf("Failed to set activity: %v", err)
			}
			return err
		}
		if s.debug {
			s.logger.Println("Successfully set Discord activity")
		}
		return nil
	case "CLEAR":
		if s.debug {
			s.logger.Println("Handling CLEAR")
		}
		if err := s.client.Clear(); err != nil {
			if s.debug {
				s.logger.Printf("Failed to clear activity: %v", err)
			}
			return err
		}
		if s.debug {
			s.logger.Println("Successfully cleared Discord activity")
		}
		return nil
	case "SHUTDOWN":
		if s.debug {
			s.logger.Println("Handling SHUTDOWN")
		}
		if s.shuttingDown.CompareAndSwap(false, true) {
			go func() {
				s.Close()
				s.Kill()
			}()
		}
		return nil
	default:
		if s.debug {
			s.logger.Printf("Unknown message type: %s", msg.Type)
		}
		return errors.New("unknown command")
	}
}

func (s *Server) Close() error {
	if s.debug {
		s.logger.Println("Closing server")
	}
	select {
	case <-s.closed:
	default:
		close(s.closed)
	}
	s.wg.Wait()
	if s.debug {
		s.logger.Println("Server closed")
	}
	return nil
}

// Kill terminates the current process forcefully.
// Used to ensure the daemon will exit itself on shutdown.
func (s *Server) Kill() {
	if s.debug {
		s.logger.Println("Killing daemon process")
	}
	p, err := os.FindProcess(os.Getpid())
	if err == nil {
		_ = p.Signal(syscall.SIGTERM)
	} else {
		os.Exit(0)
	}
	time.AfterFunc(1*time.Second, func() { os.Exit(0) })
}
