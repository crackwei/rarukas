VETARGS?=-all
GOFMT_FILES?=$$(find . -name '*.go' | grep -v vendor)
BIN_NAME?=rarukas
CURRENT_VERSION = $(gobump show -r version/)
GO_FILES?=$(shell find . -name '*.go')

BUILD_LDFLAGS = "-s -w \
	  -X github.com/rarukas/rarukas/version.Revision=`git rev-parse --short HEAD`"

BUILD_X_TARGETS= \
	build-linux-amd64 \
	build-linux-386 \
	build-darwin-amd64 \
	build-windows-amd64 \
	build-windows-386

.PHONY: default
default: test build

.PHONY: run
run:
	go run $(CURDIR)/*.go $(ARGS)

.PHONY: clean
clean:
	rm -Rf bin/*

.PHONY: tools
tools:
	go get -u github.com/golang/dep/cmd/dep
	go get -u github.com/motemen/gobump
	go get -v github.com/alecthomas/gometalinter
	gometalinter --install

.PHONY: install
install:
	go install

.PHONY: build-all
build-all: build build-server

.PHONY: build
build: bin/rarukas

bin/rarukas: $(GO_FILES)
	CGO_ENABLED=0 go build -ldflags $(BUILD_LDFLAGS) -o bin/rarukas *.go

build-x: bin/rarukas_$(GOOS)-$(GOARCH)$(SUFFIX)

.PHONY: build-x-all
build-x-all: $(BUILD_X_TARGETS)

build-windows-amd64:
	$(MAKE) build-x GOOS=windows GOARCH=amd64 SUFFIX=.exe

build-windows-386:
	@$(MAKE) build-x GOOS=windows GOARCH=386 SUFFIX=.exe

build-linux-amd64:
	@$(MAKE) build-x GOOS=linux GOARCH=amd64

build-linux-386:
	@$(MAKE) build-x GOOS=linux GOARCH=386

build-darwin-amd64:
	@$(MAKE) build-x GOOS=darwin GOARCH=amd64

bin/rarukas_$(GOOS)-$(GOARCH)$(SUFFIX): $(GO_FILES)
	go build -o bin/rarukas_$(GOOS)-$(GOARCH)$(SUFFIX) *.go


.PHONY: build-server
build-server: bin/rarukas-server

bin/rarukas-server: $(GO_FILES)
	CGO_ENABLED=0 go build -ldflags $(BUILD_LDFLAGS) -o bin/rarukas-server cmd/rarukas-server/main.go

.PHONY: docker-build
docker-build:
	docker build -t rarukas/rarukas:dev .

.PHONY: docker-build-server
docker-build-server:
	docker build -f image/alpine/Dockerfile -t rarukas/rarukas-server:alpine .
	docker build -f image/ansible/Dockerfile -t rarukas/rarukas-server:ansible .
	docker build -f image/centos/Dockerfile -t rarukas/rarukas-server:centos .
	docker build -f image/sacloud/Dockerfile -t rarukas/rarukas-server:sacloud .
	docker build -f image/ubuntu/Dockerfile -t rarukas/rarukas-server:ubuntu .

.PHONY: test
test: lint
	go test ./... $(TESTARGS) -v -timeout=30m -parallel=4 ;

.PHONY: lint
lint: fmt
	gometalinter --vendor --skip=vendor/ --cyclo-over=16 --disable=gas --disable=maligned --deadline=2m ./...
	@echo

.PHONY: fmt
fmt:
	gofmt -s -l -w $(GOFMT_FILES)

.PHONY: bump-patch bump-minor bump-major
bump-patch:
	gobump patch -w version/

bump-minor:
	gobump minor -w version/

bump-major:
	gobump major -w version/