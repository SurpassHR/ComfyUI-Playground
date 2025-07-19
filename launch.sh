# ComfyUI launching script for Linux/MacOS

PYTHON=.venv/bin/python
${PYTHON} main.py \
--port 55555 \
--cuda-malloc \
--preview-method taesd \
--use-sage-attention \
--reserve-vram 0.5 \
--async-offload \
--fast