BIN_DIR := bin
BIN := $(BIN_DIR)/discord-nvim-daemon
PKG := ./cmd/daemon

PLATFORMS := linux/amd64 linux/arm64 darwin/amd64 darwin/arm64 windows/amd64

.PHONY: all build build-all install fmt tidy clean release deps

all: build

deps:
	go mod download

build: deps
	@mkdir -p $(BIN_DIR)
	CGO_ENABLED=0 go build -ldflags="-s -w" -o $(BIN) $(PKG)

install: deps
	go install $(PKG)

fmt:
	go fmt ./...

tidy:
	go mod tidy

build-all: deps
	@mkdir -p $(BIN_DIR)
	@for platform in $(PLATFORMS); do \
		OS=$$(echo $$platform | cut -d'/' -f1); \
		ARCH=$$(echo $$platform | cut -d'/' -f2); \
		EXT=""; \
		if [ "$$OS" = "windows" ]; then EXT=".exe"; fi; \
		OUT=$(BIN_DIR)/discord-nvim-daemon-$$OS-$$ARCH$$EXT; \
		echo "Building $$OUT..."; \
		CGO_ENABLED=0 GOOS=$$OS GOARCH=$$ARCH go build -ldflags="-s -w" -o $$OUT $(PKG); \
	done

release: build-all
	@echo "Built binaries:"
	@ls -la $(BIN_DIR)/

clean:
	rm -rf $(BIN_DIR)