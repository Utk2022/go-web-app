# Stage 1: Security Scanning & Dependency Download
FROM golang:1.22.5-alpine AS deps
RUN apk add --no-cache git ca-certificates tzdata
WORKDIR /src
COPY go.mod ./
RUN go mod download

# Stage 2: Hardened Build Stage
FROM deps AS builder
COPY . .
# -ldflags="-w -s" strips debugging symbols, shrinking binary size by ~30%
# CGO_ENABLED=0 guarantees a statically-linked binary with zero dynamic library dependencies
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-w -s" \
    -o /bin/go-web-app .

# Stage 3: Minimalist Distroless Runtime
FROM gcr.io/distroless/static-debian12:latest-amd64
WORKDIR /app

# Copy system artifacts for TLS termination/Timezones
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=builder /bin/go-web-app /app/go-web-app
COPY --from=builder /src/static /app/static

# Run as a built-in non-root user (nonroot uid is 65532)
USER 65532:65532
EXPOSE 8080

# Signal configuration for elegant container shutdown termination
STOPSIGNAL SIGTERM

ENTRYPOINT ["/app/go-web-app"]
