.PHONY: build
build:
	go build -v -o nohara-node -trimpath -ldflags "-s -w -buildid="

.PHONY: clean
clean:
	rm -rf nohara-node

.PHONY: test
test:
	go test -v ./...

.DEFAULT_GOAL := build
