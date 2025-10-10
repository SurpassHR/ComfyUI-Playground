#!/bin/bash

# ComfyUI launching script for Linux/macOS

params=""
# Check if parameters exist
if [ $# -eq 0 ]; then
    params=""
    echo "No parameters found, using default parameters."
else
    echo "Parameters found: $@"
    params="$@"
fi

PYTHON="python"  # Linux/macOS uses .venv/bin/python instead of .venv/Scripts/python.exe

if [ -z "$params" ]; then
    "$PYTHON" main.py \
        --port 55554 \
        --cuda-malloc \
        --preview-method taesd \
        --use-sage-attention \
        --async-offload \
        --disable-xformers \
        --fast fp16_accumulation \
        --fp16-unet \
        --fp16-vae \
        --fp16-text-enc \
        --cache-lru 12 \
        --normalvram
else
    "$PYTHON" main.py \
        --port 55554 \
        --cuda-malloc \
        --preview-method taesd \
        --use-sage-attention \
        --async-offload \
        --disable-xformers \
        --fast fp16_accumulation \
        --fp16-unet \
        --fp16-vae \
        --fp16-text-enc \
        --cache-lru 12 \
        --normalvram \
        "$@"
fi