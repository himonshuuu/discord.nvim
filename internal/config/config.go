package config

import (
	"os"
	"path/filepath"
)

// Default configuration values
const (
	DefaultSocketPath = "/tmp/presenced.sock"
	DefaultLogLevel   = "info"
)

// Config holds the application configuration
type Config struct {
	SocketPath string
	LogLevel   string
}

// Load returns the configuration with defaults applied
func Load() *Config {
	return &Config{
		SocketPath: getEnvOrDefault("PRESENCE_SOCKET_PATH", DefaultSocketPath),
		LogLevel:   getEnvOrDefault("PRESENCE_LOG_LEVEL", DefaultLogLevel),
	}
}

// getEnvOrDefault returns the environment variable value or the default if not set
func getEnvOrDefault(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

// GetSocketDir returns the directory containing the socket file
func (c *Config) GetSocketDir() string {
	return filepath.Dir(c.SocketPath)
}
