#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Use the installed compiler; don't silently download a toolchain or modules.
export GOTOOLCHAIN=local GOPROXY=off GOSUMDB=off
go version
go test ./...
go vet ./...
mkdir -p bin
# Atomic update: safe even if a previous copy is running during a local test.
CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o bin/plura-syslog-sender.new .
mv -f bin/plura-syslog-sender.new bin/plura-syslog-sender
bin/plura-syslog-sender -version
printf 'Built: %s/bin/plura-syslog-sender\n' "$PWD"
