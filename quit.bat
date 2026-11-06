@REM ComfyUI quitting script for Windows
@echo off
setlocal enabledelayedexpansion

set "pid=65535"
@REM Find the ComfyUI process ID through netstat
for /f "tokens=5" %%i in ('netstat -ano ^| findstr :55555') do (
    REM Count PID number, and kill the one that count max
    set "pid=65535"
    for /f "tokens=1" %%j in ('tasklist /FI "PID eq %%i" ^| findstr /I "ComfyUI"') do (
        set "pid=%%i"
    )
    set "pid=%%i"
)
@REM echo Found ComfyUI process with PID !pid!
echo killing ComfyUI process with PID !pid!
taskkill /F /PID !pid! >nul 2>&1