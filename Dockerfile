FROM golang:1.25.0 AS base
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=amd64 \
    go build \
        -trimpath \
        -buildvcs=false \
        -ldflags="-s -w" \
        -o /app/main .

FROM gcr.io/distroless/static-debian13:nonroot
WORKDIR /app
#RUN adduser --system --group --no-create-home appuser
#RUN adduser --disabled-password --gecos '' --no-create-home appuser
COPY --from=base /app/main .
COPY --from=base /app/static ./static
EXPOSE 8080
USER nonroot:nonroot
#USER appuser:appuser
ENTRYPOINT ["/app/main"]
