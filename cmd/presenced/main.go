package main

import (
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/himonshuuu/presence.nvim/daemon/internal/presence"
	"github.com/himonshuuu/presence.nvim/daemon/internal/server"
)

func main() {
	srv := server.New(&presence.Client{})
	if err := srv.Start(); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}

	sigc := make(chan os.Signal, 1)
	signal.Notify(sigc, syscall.SIGINT, syscall.SIGTERM)
	<-sigc

	if err := srv.Close(); err != nil {
		log.Printf("Error during shutdown: %v", err)
	}
}
