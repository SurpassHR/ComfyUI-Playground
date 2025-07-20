# ComfyUI launching script for Linux/MacOS

PYTHON=.venv/bin/python
${PYTHON} main.py \
--port 55555 \
--cuda-malloc \
--preview-method taesd \
--use-sage-attention \
--async-offload \
--fast