.PHONY: build
build:
	go build -v -o xray-node -trimpath -ldflags "-s -w -buildid="

.PHONY: clean
clean:
	rm -rf xray-node

.PHONY: test
test:
	go test -v ./...

.DEFAULT_GOAL := build
