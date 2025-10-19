package logger

import (
	"log"
	"os"
)

// Logger provides structured logging
type Logger struct {
	info  *log.Logger
	error *log.Logger
	debug *log.Logger
}

// New creates a new logger instance
func New() *Logger {
	return &Logger{
		info:  log.New(os.Stdout, "[INFO] ", log.LstdFlags),
		error: log.New(os.Stderr, "[ERROR] ", log.LstdFlags),
		debug: log.New(os.Stdout, "[DEBUG] ", log.LstdFlags),
	}
}

// Info logs an info message
func (l *Logger) Info(msg string, args ...interface{}) {
	if len(args) > 0 {
		l.info.Printf(msg, args...)
	} else {
		l.info.Print(msg)
	}
}

// Error logs an error message
func (l *Logger) Error(msg string, args ...interface{}) {
	if len(args) > 0 {
		l.error.Printf(msg, args...)
	} else {
		l.error.Print(msg)
	}
}

func (l *Logger) Debug(msg string, args ...interface{}) {
	if len(args) > 0 {
		l.debug.Printf(msg, args...)
	} else {
		l.debug.Print(msg)
	}
}
