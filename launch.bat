@REM ComfyUI launching script for Windows
@echo off

set PYTHON=.venv\Scripts\python.exe
%PYTHON% main.py ^
--port 55555 ^
--cuda-malloc ^
--preview-method taesd ^
--use-sage-attention ^
--async-offload ^
--fast