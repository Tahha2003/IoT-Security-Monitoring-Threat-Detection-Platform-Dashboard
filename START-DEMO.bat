@echo off
title IoT Threat Detection — DEMO MODE
color 0A

echo.
echo  ╔══════════════════════════════════════════════════════════╗
echo  ║        IoT IDS — DEMO MODE LAUNCHER                     ║
echo  ╚══════════════════════════════════════════════════════════╝
echo.

REM ── Check Node.js is installed ──────────────────────────────────────────────
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo  [ERROR] Node.js not found!
    echo  Download from: https://nodejs.org
    pause
    exit /b 1
)

REM ── Check ports 3000, 8000, 9090 are free ───────────────────────────────────
echo  Checking ports...
netstat -ano | findstr ":3000 " | findstr "LISTENING" >nul 2>&1
if %errorlevel% equ 0 (
    echo  [WARNING] Port 3000 already in use. Dashboard server may fail.
)
netstat -ano | findstr ":8000 " | findstr "LISTENING" >nul 2>&1
if %errorlevel% equ 0 (
    echo  [WARNING] Port 8000 already in use. API server may fail.
)
netstat -ano | findstr ":9090 " | findstr "LISTENING" >nul 2>&1
if %errorlevel% equ 0 (
    echo  [WARNING] Port 9090 already in use. Prometheus mock may fail.
)

echo.
echo  Starting demo server...
echo.

REM ── Get script directory (works regardless of where you double-click from) ──
set "SCRIPT_DIR=%~dp0"

REM ── Start the demo server in this window ────────────────────────────────────
REM  (keeping it in the same window so you see logs during presentation)
cd /d "%SCRIPT_DIR%"

REM ── Open browser after 2 seconds (runs in background) ───────────────────────
start "" cmd /c "timeout /t 2 /nobreak >nul && start http://localhost:3000"

node "%SCRIPT_DIR%demo-server.js"

REM ── If server crashes, pause so you can read the error ──────────────────────
echo.
echo  [Server stopped]
pause
