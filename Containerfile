# llama-swappo-halo: LLM proxy for AMD Strix Halo
#
# Build: buildah bud -t llama-swappo-halo .
#
# For STT support, use Containerfile.stt or run whisper-stt as sidecar

ARG BACKEND=rocm-6.4.4-rocwmma

# Build llama-swappo
FROM alpine:latest AS builder

RUN apk add --no-cache git go nodejs npm ca-certificates

WORKDIR /build
RUN git clone https://github.com/mootikins/llama-swappo.git && \
    cd llama-swappo/ui && npm install && npm run build && \
    cd .. && CGO_ENABLED=0 go build -o llama-swap . && strip llama-swap

# Runtime
FROM kyuz0/amd-strix-halo-toolboxes:${BACKEND}

WORKDIR /app
RUN mkdir -p /models

COPY --from=builder /build/llama-swappo/llama-swap /app/llama-swap
RUN chmod +x /app/llama-swap

ENV PATH="/app:${PATH}"

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

EXPOSE 8080
ENTRYPOINT ["/app/llama-swap"]
