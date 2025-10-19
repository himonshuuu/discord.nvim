BIN_DIR=bin
BIN=$(BIN_DIR)/presenced
PKG=./cmd/presenced

# Cross-compilation targets
PLATFORMS := linux/amd64 linux/arm64 darwin/amd64 darwin/arm64 windows/amd64

.PHONY: all build build-all install fmt tidy clean release

all: build

deps:
	go get ./...

build:
	mkdir -p $(BIN_DIR)
	CGO_ENABLED=0 go build -ldflags="-s -w" -o $(BIN) $(PKG)

install:
	go install $(PKG)

fmt:
	go fmt ./...

tidy: 
	go mod tidy

build-all:
	@for platform in $(PLATFORMS); do \
		OS=$$(echo $$platform | cut -d'/' -f1); \
		ARCH=$$(echo $$platform | cut -d'/' -f2); \
		EXT=""; \
		if [ $$OS = "windows" ]; then EXT=".exe"; fi; \
		echo "Building $$OS/$$ARCH..."; \
		CGO_ENABLED=0 GOOS=$$OS GOARCH=$$ARCH go build -ldflags="-s -w" -o $(BIN_DIR)/presenced-$$OS-$$ARCH$$EXT $(PKG); \
	done

release: build-all
	@echo "Built binaries:"
	@ls -la $(BIN_DIR)/

clean:
	rm -rf $(BIN_DIR)