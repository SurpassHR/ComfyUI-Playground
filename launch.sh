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

PYTHON=".venv/bin/python"  # Linux/macOS uses .venv/bin/python instead of .venv/Scripts/python.exe

if [ -z "$params" ]; then
    "$PYTHON" main.py \
        --port 55555 \
        --cuda-malloc \
        --preview-method taesd \
        --use-sage-attention \
        --async-offload \
        --fast
else
    "$PYTHON" main.py \
        --port 55555 \
        --cuda-malloc \
        --preview-method taesd \
        --use-sage-attention \
        --async-offload \
        --fast \
        $params
fi