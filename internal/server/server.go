package server

import (
	"io"
	"net"
	"os"
	"sync"
	"sync/atomic"

	"github.com/himonshuuu/discord.nvim/daemon/internal/config"
	"github.com/himonshuuu/discord.nvim/daemon/internal/handler"
	"github.com/himonshuuu/discord.nvim/daemon/internal/logger"
	"github.com/himonshuuu/discord.nvim/daemon/internal/presence"
	"github.com/himonshuuu/discord.nvim/daemon/internal/protocol"
)

type Server struct {
	addr          string
	ln            net.Listener
	wg            sync.WaitGroup
	handler       *handler.Handler
	logger        *logger.Logger
	closed        chan struct{}
	activeClients int32
}

func New(client presence.Service) *Server {
	cfg := config.Load()
	return &Server{
		addr:    cfg.SocketPath,
		handler: handler.New(client),
		logger:  logger.New(),
		closed:  make(chan struct{}),
	}
}

func (s *Server) Start() error {
	// Remove stale socket if present
	_ = os.Remove(s.addr)
	ln, err := net.Listen("unix", s.addr)
	if err != nil {
		return err
	}
	s.ln = ln
	s.logger.Info("Server started on %s", s.addr)

	s.wg.Add(1)
	go func() {
		defer s.wg.Done()
		for {
			conn, err := s.ln.Accept()
			if err != nil {
				select {
				case <-s.closed:
					return
				default:
					s.logger.Error("Accept error: %v", err)
					continue
				}
			}
			s.wg.Add(1)
			go s.handleConn(conn)
		}
	}()
	return nil
}

func (s *Server) handleConn(c net.Conn) {
	defer s.wg.Done()
	defer c.Close()

	// Increment active client count
	atomic.AddInt32(&s.activeClients, 1)
	s.logger.Debug("New client connected from %s (total clients: %d)", c.RemoteAddr(), atomic.LoadInt32(&s.activeClients))

	// Decrement active client count when connection closes
	defer func() {
		count := atomic.AddInt32(&s.activeClients, -1)
		s.logger.Debug("Client disconnected (remaining clients: %d)", count)

		// If no clients remain, initiate graceful shutdown
		if count == 0 {
			s.logger.Info("No active clients remaining, initiating shutdown")
			go func() {
				select {
				case <-s.closed:
					// Already shutting down
				default:
					close(s.closed)
				}
			}()
		}
	}()

	codec := protocol.NewCodec(c, c)

	for {
		msg, err := codec.ReadMessage()
		if err != nil {
			if err == io.EOF {
				s.logger.Debug("Client disconnected")
				return
			}
			s.logger.Error("Read error: %v", err)
			_ = codec.WriteJSON(protocol.BasicResponse{Ok: false, Error: err.Error()})
			return
		}

		s.logger.Debug("Handling action: %s", msg.Action)
		resp := s.handler.Handle(msg)
		_ = codec.WriteJSON(resp)

		// Remove the shutdown action - clients should just disconnect
		// The daemon will auto-shutdown when no clients remain
	}
}

func (s *Server) Close() error {
	s.logger.Info("Shutting down server...")

	// Only close the channel if it's not already closed
	select {
	case <-s.closed:
		// Already closed
	default:
		close(s.closed)
	}

	if s.ln != nil {
		_ = s.ln.Close()
	}
	s.wg.Wait()
	_ = os.Remove(s.addr)
	s.logger.Info("Server shutdown complete")
	return nil
}
