.PHONY: build
build:
	go build -v -o nboard-node -trimpath -ldflags "-s -w -buildid="

.PHONY: clean
clean:
	rm -rf nboard-node

.PHONY: test
test:
	go test -v ./...

.DEFAULT_GOAL := build
