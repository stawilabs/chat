# Do not default TARGETARCH — buildx injects the target platform per-arch.
# A default of amd64 previously published x86-64 binaries under the arm64
# manifest (exec format error on arm nodes).
ARG TARGETOS
ARG TARGETARCH

# ---------- Builder ----------
FROM --platform=$BUILDPLATFORM golang:1.26 AS builder
ARG TARGETOS
ARG TARGETARCH

WORKDIR /app

# Inject version info from build args
ARG REPOSITORY
ARG VERSION=dev
ARG REVISION=none
ARG BUILDTIME

# Cache dependencies first
COPY go.mod go.sum ./
RUN go mod download

# Copy the actual source
COPY ./pkg ./pkg
COPY ./apps/default/service/models ./apps/default/service/models
COPY ./apps/default/service/repository ./apps/default/service/repository
COPY ./apps/gateway ./apps/gateway

# Build static binary for target platform
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -trimpath \
     -ldflags="-s -w \
         -X github.com/pitabwire/frame/v2/version.Repository=${REPOSITORY} \
         -X github.com/pitabwire/frame/v2/version.Version=${VERSION} \
         -X github.com/pitabwire/frame/v2/version.Commit=${REVISION} \
         -X github.com/pitabwire/frame/v2/version.Date=${BUILDTIME}" \
    -o /gateway ./apps/gateway/cmd/main.go

# ---------- Final ----------
FROM cgr.dev/chainguard/static:latest
# Add Maintainer Info
LABEL maintainer="Bwire Peter <bwire517@gmail.com>"

# Use non-root user
USER 65532:65532

# Expose your app ports
EXPOSE 80

# Add OCI metadata labels
ARG REPOSITORY
ARG VERSION
ARG REVISION
ARG BUILDTIME
LABEL org.opencontainers.image.title="Stawi Chat Gateway"
LABEL org.opencontainers.image.version=$VERSION
LABEL org.opencontainers.image.revision=$REVISION
LABEL org.opencontainers.image.created=$BUILDTIME
LABEL org.opencontainers.image.source=$REPOSITORY

WORKDIR /
# Copy binary from builder
COPY --from=builder /gateway /gateway

# Set entrypoint
ENTRYPOINT ["/gateway"]
