# ---- System dependencies ----
FROM ubuntu:26.04

# Layer 1: apt deps (cached)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates wget git make gcc pkg-config ragel \
    libvirt-dev libaugeas-dev \
    && rm -rf /var/lib/apt/lists/*

# Layer 2: Go toolchain + Go tools (cached)
ENV GOTOOLCHAIN=local
ENV PATH=/usr/local/go/bin:/root/go/bin:$PATH
ENV CGO_ENABLED=1
RUN wget -qO- https://go.dev/dl/go1.26.8.linux-amd64.tar.gz | tar -C /usr/local -xzf - \
    && go install github.com/blynn/nex@latest \
    && go install golang.org/x/tools/cmd/goyacc@latest \
    && go install golang.org/x/tools/cmd/stringer@latest \
    && go install golang.org/x/tools/cmd/goimports@latest

# Layer 3: Download Go module cache (cached -- invalidates on go.mod change)
COPY go.mod go.sum /mgmt/
WORKDIR /mgmt
RUN go mod download

# Layer 4: source code + build (invalidates on source change)
COPY . /mgmt

RUN bash .github/build-test.sh
