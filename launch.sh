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
    "$PYTHON" -B main.py \
        --port 55554 \
        --cuda-malloc \
        --preview-method taesd \
        --async-offload \
        --cache-ram \
        --disable-xformers \
        --output-directory F:\\GeneratedImages
else
    TF_ENABLE_ONEDNN_OPTS=0 "$PYTHON" -B main.py \
        --port 55554 \
        --cuda-malloc \
        --preview-method taesd \
        --async-offload \
        --cache-ram \
        --output-directory F:\\GeneratedImages \
        "$@"
fi
