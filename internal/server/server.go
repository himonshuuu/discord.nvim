package server

import (
	"io"
	"net"
	"os"
	"sync"

	"github.com/himonshuuu/presence.nvim/daemon/internal/config"
	"github.com/himonshuuu/presence.nvim/daemon/internal/handler"
	"github.com/himonshuuu/presence.nvim/daemon/internal/logger"
	"github.com/himonshuuu/presence.nvim/daemon/internal/presence"
	"github.com/himonshuuu/presence.nvim/daemon/internal/protocol"
)

type Server struct {
	addr    string
	ln      net.Listener
	wg      sync.WaitGroup
	handler *handler.Handler
	logger  *logger.Logger
	closed  chan struct{}
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

	s.logger.Debug("New client connected from %s", c.RemoteAddr())
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

		if msg.Action == "shutdown" {
			s.logger.Info("Shutdown requested by client")
			return
		}
	}
}

func (s *Server) Close() error {
	s.logger.Info("Shutting down server...")
	close(s.closed)
	if s.ln != nil {
		_ = s.ln.Close()
	}
	s.wg.Wait()
	_ = os.Remove(s.addr)
	s.logger.Info("Server shutdown complete")
	return nil
}
