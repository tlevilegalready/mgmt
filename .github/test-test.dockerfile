# ---- Test runner Dockerfile ----------------------------------------------------------------------------------------------
# Usage: docker build -t mgmt-test -f .github/test-test.dockerfile .
#        docker run --rm mgmt-test
# Mirrors .github/workflows/test.yaml go-tests jobs

FROM ubuntu:26.04

# Layer 1: System deps (cached)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates wget git make gcc pkg-config ragel curl inotify-tools \
    libvirt-dev libaugeas-dev \
    ruby ruby-dev \
    && rm -rf /var/lib/apt/lists/*

# Layer 2: Go toolchain + Go tools (cached)
ENV GOTOOLCHAIN=local
ENV PATH=/usr/local/go/bin:/root/go/bin:$PATH
ENV CGO_ENABLED=1
RUN wget -qO- https://go.dev/dl/go1.26.8.linux-amd64.tar.gz | tar -C /usr/local -xzf - \
    && go install github.com/blynn/nex@latest \
    && go install golang.org/x/tools/cmd/goyacc@latest \
    && go install golang.org/x/tools/cmd/stringer@latest \
    && go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# Layer 3: Download Go module cache (cached)
COPY go.mod go.sum /mgmt/
WORKDIR /mgmt
RUN go mod download

# Layer 4: Source + test runner
COPY . /mgmt

RUN bash .github/test-test.sh
