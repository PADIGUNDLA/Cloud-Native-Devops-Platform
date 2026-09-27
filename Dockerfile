# -------------------------
# Stage 1: Build
# -------------------------

FROM golang:1.27-alpine AS builder

WORKDIR /app

COPY app/go.mod ./

COPY app/ ./

RUN go build -o devops-dashboard .

# -------------------------
# Stage 2: Runtime
# -------------------------

FROM alpine:3.22

WORKDIR /app

RUN addgroup -S appgroup && \
    adduser -S appuser -G appgroup

COPY --from=builder /app/devops-dashboard .

RUN chown appuser:appgroup /app/devops-dashboard

USER appuser

EXPOSE 8080

CMD ["./devops-dashboard"]
