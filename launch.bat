@REM ComfyUI launching script for Windows
@echo off

set PYTHON=.venv\Scripts\python.exe
%PYTHON% main.py ^
--port 55555 ^
--cuda-malloc ^
--preview-method taesd ^
--use-sage-attention ^
--reserve-vram 0.5 ^
--async-offload ^
--fast