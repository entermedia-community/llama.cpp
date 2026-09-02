#!/bin/bash
set -euo pipefail

# Llama server launcher
# All configurations are set in /root/.env or in the .env file in the same directory as this script.

# Load environment variables if .env exists
if [ -f "/root/.env" ]; then
    set -a
    source "/root/.env"
    set +a
elif [ -f "$(dirname "$0")/.env" ]; then
    set -a
    source "$(dirname "$0")/.env"
    set +a
fi

# Kill any existing llama-server processes and free up ports 8080 and 7600
pkill llama-server || true
lsof -ti :8080,7600 | xargs -r kill -9 2>/dev/null || true

LOGFILE=/root/logs/llama
mkdir -p "$LOGFILE"

export CUDA_VISIBLE_DEVICES="${LLAMA_GPU:-0}"
export LLAMA_ARG_PORT="${LLAMA_PORT:-7600}"
export LLAMA_ARG_HOST="${LLAMA_HOST:-0.0.0.0}"

LLAMA_TEMP="${LLAMA_TEMP:-0.7}"
LLAMA_TOP_P="${LLAMA_TOP_P:-0.80}"
LLAMA_TOP_K="${LLAMA_TOP_K:-20}"
LLAMA_MIN_P="${LLAMA_MIN_P:-0.0}"
LLAMA_PRESENCE_PENALTY="${LLAMA_PRESENCE_PENALTY:-1.5}"
LLAMA_REPEAT_PENALTY="${LLAMA_REPEAT_PENALTY:-1.0}"
LLAMA_CTX_SIZE="${LLAMA_CTX_SIZE:-32768}"
LLAMA_REASONING="${LLAMA_REASONING:-off}"

LLAMA_SERVER_BIN="/root/llama.cpp/build/bin/llama-server"
if [ ! -f "$LLAMA_SERVER_BIN" ]; then
    LLAMA_SERVER_BIN="/root/llama.cpp/llama-server"
fi

#nohup sh -c '
"$LLAMA_SERVER_BIN" \
    --model unsloth/Qwen3.8-27B-GGUF/Qwen3.8-27B-UD-Q4_K_XL.gguf \
    --mmproj unsloth/Qwen3.8-27B-GGUF/mmproj-F16.gguf \
    --model "/root/unsloth/${LLAMA_MODEL}/${LLAMA_MODEL_FILE}" \
    --mmproj "/root/unsloth/${LLAMA_MODEL}/mmproj-F16.gguf" \
     --temp "$LLAMA_TEMP" \
    --top-p "$LLAMA_TOP_P" \
    --top-k "$LLAMA_TOP_K" \
    --min-p "$LLAMA_MIN_P" \
    --presence-penalty "$LLAMA_PRESENCE_PENALTY" \
    --repeat-penalty "$LLAMA_REPEAT_PENALTY" \
    --ctx-size "$LLAMA_CTX_SIZE" \
    --reasoning "$LLAMA_REASONING" \
    --n-gpu-layers 999 \
    2>&1 | multilog t s5000000 n3 "$LOGFILE" &
#' >/dev/null 2>&1 &

#echo "Server started. Checking log for GPU offload:"
#sleep 2
#grep -E "CUDA|offload|vram" server.log || tail -n 25 server.log