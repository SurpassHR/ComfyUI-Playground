@REM ComfyUI launching script for Windows
@echo off

set params=
@REM Judge if parameters are exist and get them
if "%1"=="" (
    set params=
    echo No parameters found, using default parameters.
) else (
    echo Parameters found: %*
    set params="%*"
)

set PYTHON=.venv\Scripts\python.exe
if "%params%"=="" (
    %PYTHON% main.py ^
    --port 55555 ^
    --cuda-malloc ^
    --preview-method taesd ^
    --use-sage-attention ^
    --async-offload ^
    --fast
) else (
    %PYTHON% main.py ^
    --port 55555 ^
    --cuda-malloc ^
    --preview-method taesd ^
    --use-sage-attention ^
    --async-offload ^
    --fast ^
    %params%
)