# Multi-stage build for packaging SNS Slack Forwarder Lambda function
# Stage 1: Build the Lambda package from source
# Stage 2: Extract the packaged artifact

# ============================================================ build stage ===

FROM golang:1.25-alpine AS build

ARG BOT_VERSION=latest
ARG BOT_REPO=https://github.com/cruxstack/aws-sns-slack-forwarder-go.git

RUN apk add --no-cache git make zip

WORKDIR /build

# Clone the SNS Slack Forwarder repository
RUN git clone --depth 1 \
      $([ "$BOT_VERSION" = "latest" ] && echo "$BOT_REPO" || echo "$BOT_REPO --branch $BOT_VERSION") \
      . && \
    ls -la


# Build the Lambda package (example: Go-based approach)
RUN make build

# ========================================================= package stage ===

FROM alpine:latest AS package

COPY --from=build /build/dist/bootstrap /opt/app/dist/bootstrap

RUN apk add zip \
    && cd /opt/app/dist \
    && zip -r /tmp/package.zip .
