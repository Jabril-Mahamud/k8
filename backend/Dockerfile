# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY main.go ./

# Build the binary
RUN CGO_ENABLED=0 GOOS=linux go build -o backend main.go

# Runtime stage - super small image!
FROM alpine:latest

WORKDIR /app

# Copy just the binary from builder stage
COPY --from=builder /app/backend .

EXPOSE 3000

CMD ["./backend"]