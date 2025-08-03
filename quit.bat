@REM ComfyUI quitting script for Windows
@echo off
setlocal enabledelayedexpansion

set pid=65535
@REM Find the ComfyUI process ID through netstat
for /f "tokens=5" %%i in ('netstat -ano ^| findstr :55555') do (
    set "pid=%%i"
)
@REM echo Found ComfyUI process with PID !pid!
taskkill /F /PID !pid! >nul 2>&1