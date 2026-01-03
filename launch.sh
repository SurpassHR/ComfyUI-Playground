#!/bin/bash

# ComfyUI launching script for Linux/macOS also suitable for windows bash

params=""
# Check if parameters exist
if [ $# -eq 0 ]; then
    params=""
    echo "No parameters found, using default parameters."
else
    echo "Parameters found: $@"
    params="$@"
fi

echo "Updating workflows"
bash update_workflows.sh

PYTHON="python"  # Linux/macOS uses .venv/bin/python instead of .venv/Scripts/python.exe
export LD_LIBRARY_PATH=/home/hr/Projects/Codes/ComfyUI/.venv/lib/python3.12/site-packages/nvidia/cu13/lib:$LD_LIBRARY_PATH
if [ -z "$params" ]; then
    "$PYTHON" -B main.py \
        --port 55554 \
        --cuda-malloc \
        --preview-method taesd \
        --cache-ram \
        --disable-xformers \
        --output-directory /media/hr/Data/GeneratedImages
else
    TF_ENABLE_ONEDNN_OPTS=0 "$PYTHON" -B main.py \
        "$@" \
        --port 55554 \
        --cuda-malloc \
        --preview-method taesd \
        --async-offload \
        --cache-ram \
        --output-directory /media/hr/Data/GeneratedImages
fi

echo "Uploading workflows"
bash upload_workflows.sh