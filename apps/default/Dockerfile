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
COPY ./apps/default ./apps/default

# Build static binary for target platform
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -trimpath \
     -ldflags="-s -w \
         -X github.com/pitabwire/frame/version.Repository=${REPOSITORY} \
         -X github.com/pitabwire/frame/version.Version=${VERSION} \
         -X github.com/pitabwire/frame/version.Commit=${REVISION} \
         -X github.com/pitabwire/frame/version.Date=${BUILDTIME}" \
    -o /drone ./apps/default/cmd/main.go

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
LABEL org.opencontainers.image.title="Drone Service"
LABEL org.opencontainers.image.version=$VERSION
LABEL org.opencontainers.image.revision=$REVISION
LABEL org.opencontainers.image.created=$BUILDTIME
LABEL org.opencontainers.image.source=$REPOSITORY

WORKDIR /
# Copy binary from builder
COPY --from=builder /drone /drone
# Required for DO_MIGRATION: frame defaults MIGRATION_PATH to ./migrations/0001.
# Omitting this silently skips SQL patches (composite PK), so create_hypertable fails with TS103.
COPY --from=builder /app/apps/default/migrations /migrations

# Set entrypoint
ENTRYPOINT ["/drone"]
