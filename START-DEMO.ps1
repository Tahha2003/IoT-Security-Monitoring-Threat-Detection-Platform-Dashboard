# ──────────────────────────────────────────────────────────────────────────────
#  IoT Threat Detection — DEMO MODE LAUNCHER  (PowerShell version)
#  Run with:  .\START-DEMO.ps1
#  Or right-click → "Run with PowerShell"
# ──────────────────────────────────────────────────────────────────────────────

$Host.UI.RawUI.WindowTitle = "IoT IDS — DEMO MODE"

Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║        IoT IDS — DEMO MODE LAUNCHER                     ║" -ForegroundColor Cyan
Write-Host "  ╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ── Check Node.js ──────────────────────────────────────────────────────────────
$nodePath = Get-Command node -ErrorAction SilentlyContinue
if (-not $nodePath) {
    Write-Host "  [ERROR] Node.js not found!" -ForegroundColor Red
    Write-Host "  Download from: https://nodejs.org" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}
$nodeVer = (node --version)
Write-Host "  Node.js : $nodeVer" -ForegroundColor Green

# ── Check ports ────────────────────────────────────────────────────────────────
Write-Host "  Checking ports..." -ForegroundColor Gray
@(3000, 8000, 9090) | ForEach-Object {
    $port = $_
    $inUse = netstat -ano | Select-String ":$port " | Select-String "LISTENING"
    if ($inUse) {
        Write-Host "  [WARNING] Port $port is already in use — free it before starting!" -ForegroundColor Yellow
    } else {
        Write-Host "  Port $port : free" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "  Starting mock server..." -ForegroundColor Cyan
Write-Host "  (browser will open automatically in 3 seconds)" -ForegroundColor Gray
Write-Host ""

# ── Get script directory ───────────────────────────────────────────────────────
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $scriptDir) { $scriptDir = Get-Location }

# ── Open browser after 3 seconds (background job) ─────────────────────────────
Start-Job -ScriptBlock {
    Start-Sleep -Seconds 3
    Start-Process "http://localhost:3000"
} | Out-Null

# ── Run the demo server (foreground — logs visible during presentation) ────────
Set-Location $scriptDir
node "$scriptDir\demo-server.js"

# ── Landed here means server stopped ──────────────────────────────────────────
Write-Host ""
Write-Host "  [Server stopped]" -ForegroundColor Yellow
Read-Host "Press Enter to exit"
