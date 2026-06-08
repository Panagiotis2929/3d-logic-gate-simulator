# ── Build stage ──────────────────────────────────────────────────────────────
FROM golang:1.22-alpine AS builder

WORKDIR /app

# Download dependencies first (cache layer)
COPY go.mod go.sum ./
RUN go mod download

# Copy source
COPY . .

# Build with optimisations; CGO disabled for fully static binary
RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags="-s -w" \
    -o /bin/server \
    ./cmd/server

# ── Runtime stage ─────────────────────────────────────────────────────────────
FROM scratch

# Copy CA certificates (needed if the server makes HTTPS calls)
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

COPY --from=builder /bin/server /server

EXPOSE 8080

ENTRYPOINT ["/server"]
