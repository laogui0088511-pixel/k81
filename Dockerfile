# Build Stage
FROM golang:1.20 AS builder

# Set go mod installation source and proxy
ARG GO111MODULE=on
ARG GOPROXY=https://goproxy.cn,direct
ENV GO111MODULE=$GO111MODULE
ENV GOPROXY=$GOPROXY

# Set up the working directory
WORKDIR /openim/openim-server

COPY go.mod go.sum ./
# go.mod contains: replace github.com/OpenIMSDK/protocol => ./pkg/protocol
# The replaced local module must exist before `go mod download`.
COPY pkg/protocol ./pkg/protocol
RUN go mod download

# Copy all files to the container
ADD . .

RUN make clean
RUN make build

FROM ghcr.io/openim-sigs/openim-ubuntu-image:latest

WORKDIR ${SERVER_WORKDIR}

# Copy scripts, config, and binary files to the production image
COPY --from=builder ${OPENIM_SERVER_BINDIR} /openim/openim-server/_output/bin
COPY --from=builder /openim/openim-server/scripts /openim/openim-server/scripts
COPY --from=builder /openim/openim-server/config /openim/openim-server/config

# Ensure shell scripts are executable (Windows checkouts don't preserve +x)
RUN find /openim/openim-server/scripts -type f -name "*.sh" -exec chmod +x {} \; \
 && chmod +x /openim/openim-server/_output/bin/platforms/*/* 2>/dev/null || true

CMD ["/bin/bash", "/openim/openim-server/scripts/docker-start-all.sh"]
