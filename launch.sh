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
        --fast
else
    "$PYTHON" main.py \
        --port 55554 \
        --cuda-malloc \
        --preview-method taesd \
        --use-sage-attention \
        --async-offload \
        --disable-xformers \
        --fast
        $params
fi