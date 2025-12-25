# llama-swappo-halo: LLM proxy + llama.cpp for AMD Strix Halo (GMKtec EVO X2)
#
# kyuz0/amd-strix-halo-toolboxes already includes llama.cpp with ROCm
# We just add llama-swappo (Go proxy with Ollama API translation)
#
# Build: ./build.sh
# Build+Push: ./build.sh --ghcr

ARG BACKEND=rocm-6.4.4-rocwmma

# Build llama-swappo binary
FROM alpine:latest AS builder

RUN apk add --no-cache git go nodejs npm ca-certificates

WORKDIR /build
RUN git clone https://github.com/mootikins/llama-swappo.git && \
    cd llama-swappo && \
    cd ui && npm install && npm run build && \
    cd .. && \
    CGO_ENABLED=0 go build -o llama-swap . && \
    strip llama-swap

# Use kyuz0 toolbox which has llama.cpp + ROCm pre-built
FROM docker.io/kyuz0/amd-strix-halo-toolboxes:${BACKEND}

WORKDIR /app
RUN mkdir -p /models

# Copy llama-swappo binary
COPY --from=builder /build/llama-swappo/llama-swap /app/llama-swap
RUN chmod +x /app/llama-swap

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

EXPOSE 8080
ENTRYPOINT ["/app/llama-swap"]
