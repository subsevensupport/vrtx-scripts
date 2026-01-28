# =====================================================================
#  Vortex Systems - Complete Setup
#  ONE script, ONE login, EVERYTHING works!
# =====================================================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  VORTEX SYSTEMS - SETUP" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Enter your credentials once." -ForegroundColor Yellow
Write-Host "They will be used for all drives and printers." -ForegroundColor Yellow
Write-Host ""

# Get credentials ONCE
$username = Read-Host "Username (no domain)"
$securePass = Read-Host "Password" -AsSecureString
$password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePass))

$fullUsername = "hq.vortex-systems.com\$username"

Write-Host ""
Write-Host "Storing credentials for all servers..." -ForegroundColor Cyan

# Store credentials for BOTH servers
cmdkey /add:VORTEXFS.hq.vortex-systems.com /user:$fullUsername /pass:$password 2>&1 | Out-Null
cmdkey /add:SMARTWORKSPC /user:$fullUsername /pass:$password 2>&1 | Out-Null

Write-Host "[OK] Credentials stored" -ForegroundColor Green
Write-Host ""

# Clear any existing connections
Write-Host "Clearing old connections..." -ForegroundColor Cyan
net use U: /delete /yes 2>&1 | Out-Null
net use O: /delete /yes 2>&1 | Out-Null
net use R: /delete /yes 2>&1 | Out-Null
net use Q: /delete /yes 2>&1 | Out-Null
net use N: /delete /yes 2>&1 | Out-Null
net use S: /delete /yes 2>&1 | Out-Null
net use V: /delete /yes 2>&1 | Out-Null
net use P: /delete /yes 2>&1 | Out-Null
net use T: /delete /yes 2>&1 | Out-Null
net use I: /delete /yes 2>&1 | Out-Null

Write-Host "[OK] Cleared" -ForegroundColor Green
Write-Host ""

# Map drives
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  MAPPING DRIVES" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Mapping standard drives..." -ForegroundColor Yellow
Write-Host ""

# U: BUSINESS
Write-Host "  U: BUSINESS..." -NoNewline
net use U: "\\VORTEXFS.hq.vortex-systems.com\BUSINESS$" /persistent:yes 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) { Write-Host " OK" -ForegroundColor Green } else { Write-Host " FAILED" -ForegroundColor Red }

# O: EMPLOYEE
Write-Host "  O: EMPLOYEE..." -NoNewline
net use O: "\\VORTEXFS.hq.vortex-systems.com\EMPLOYEE$" /persistent:yes 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) { Write-Host " OK" -ForegroundColor Green } else { Write-Host " FAILED" -ForegroundColor Red }

# R: ENGINEERING RECORDS
Write-Host "  R: ENGINEERING RECORDS..." -NoNewline
net use R: "\\VORTEXFS.hq.vortex-systems.com\ENGINEERING RECORDS$" /persistent:yes 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) { Write-Host " OK" -ForegroundColor Green } else { Write-Host " FAILED" -ForegroundColor Red }

# Q: ENGINEERING
Write-Host "  Q: ENGINEERING..." -NoNewline
net use Q: "\\VORTEXFS.hq.vortex-systems.com\ENGINEERING$" /persistent:yes 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) { Write-Host " OK" -ForegroundColor Green } else { Write-Host " FAILED" -ForegroundColor Red }

# N: FINANCE-HR
Write-Host "  N: FINANCE-HR..." -NoNewline
net use N: "\\VORTEXFS.hq.vortex-systems.com\FINANCE-HR$" /persistent:yes 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) { Write-Host " OK" -ForegroundColor Green } else { Write-Host " FAILED" -ForegroundColor Red }

# S: SOFTWARE
Write-Host "  S: SOFTWARE..." -NoNewline
net use S: "\\VORTEXFS.hq.vortex-systems.com\SOFTWARE$" /persistent:yes 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) { Write-Host " OK" -ForegroundColor Green } else { Write-Host " FAILED" -ForegroundColor Red }

# V: VORTEX
Write-Host "  V: VORTEX..." -NoNewline
net use V: "\\VORTEXFS.hq.vortex-systems.com\VORTEX" /persistent:yes 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) { Write-Host " OK" -ForegroundColor Green } else { Write-Host " FAILED" -ForegroundColor Red }

# P: Personal
Write-Host "  P: Personal..." -NoNewline
net use P: "\\VORTEXFS.hq.vortex-systems.com\EMPLOYEE$\$username" /persistent:yes 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) { Write-Host " OK" -ForegroundColor Green } else { Write-Host " FAILED" -ForegroundColor Red }

Write-Host ""
Write-Host "Mapping special shares..." -ForegroundColor Yellow
Write-Host ""

# T: Quotations
Write-Host "  T: Quotations..." -NoNewline
net use T: "\\VORTEXFS.hq.vortex-systems.com\0-quotations$" /persistent:yes 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) { Write-Host " OK" -ForegroundColor Green } else { Write-Host " SKIP (no permission)" -ForegroundColor Gray }

# I: Crib Catalog
Write-Host "  I: Crib Catalog..." -NoNewline
net use I: "\\VORTEXFS.hq.vortex-systems.com\crib-catalog$" /persistent:yes 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) { Write-Host " OK" -ForegroundColor Green } else { Write-Host " SKIP (no permission)" -ForegroundColor Gray }

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  INSTALLING PRINTERS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# SHOP-PRNT
Write-Host "  SHOP-PRNT..." -NoNewline
try {
    Add-Printer -ConnectionName "\\VORTEXFS.hq.vortex-systems.com\SHOP-PRNT" -ErrorAction Stop 2>&1 | Out-Null
    Write-Host " OK" -ForegroundColor Green
} catch {
    if ($_.Exception.Message -like "*already installed*") {
        Write-Host " Already installed" -ForegroundColor Gray
    } elseif ($_.Exception.Message -like "*Access is denied*") {
        Write-Host " SKIP (no permission)" -ForegroundColor Gray
    } else {
        Write-Host " FAILED" -ForegroundColor Red
    }
}

# SHOP-CLR-PRNT
Write-Host "  SHOP-CLR-PRNT..." -NoNewline
try {
    Add-Printer -ConnectionName "\\VORTEXFS.hq.vortex-systems.com\SHOP-CLR-PRNT" -ErrorAction Stop 2>&1 | Out-Null
    Write-Host " OK" -ForegroundColor Green
} catch {
    if ($_.Exception.Message -like "*already installed*") {
        Write-Host " Already installed" -ForegroundColor Gray
    } elseif ($_.Exception.Message -like "*Access is denied*") {
        Write-Host " SKIP (no permission)" -ForegroundColor Gray
    } else {
        Write-Host " FAILED" -ForegroundColor Red
    }
}

# MGNT-PRNT
Write-Host "  MGNT-PRNT..." -NoNewline
try {
    Add-Printer -ConnectionName "\\VORTEXFS.hq.vortex-systems.com\MGNT-PRNT" -ErrorAction Stop 2>&1 | Out-Null
    Write-Host " OK" -ForegroundColor Green
} catch {
    if ($_.Exception.Message -like "*already installed*") {
        Write-Host " Already installed" -ForegroundColor Gray
    } elseif ($_.Exception.Message -like "*Access is denied*") {
        Write-Host " SKIP (no permission)" -ForegroundColor Gray
    } else {
        Write-Host " FAILED" -ForegroundColor Red
    }
}

# LOBBY-PRNT
Write-Host "  LOBBY-PRNT..." -NoNewline
try {
    Add-Printer -ConnectionName "\\VORTEXFS.hq.vortex-systems.com\LOBBY-PRNT" -ErrorAction Stop 2>&1 | Out-Null
    Write-Host " OK" -ForegroundColor Green
} catch {
    if ($_.Exception.Message -like "*already installed*") {
        Write-Host " Already installed" -ForegroundColor Gray
    } elseif ($_.Exception.Message -like "*Access is denied*") {
        Write-Host " SKIP (no permission)" -ForegroundColor Gray
    } else {
        Write-Host " FAILED" -ForegroundColor Red
    }
}

# PLOTTER
Write-Host "  PLOTTER..." -NoNewline
try {
    Add-Printer -ConnectionName "\\SMARTWORKSPC\Canon-TM-305" -ErrorAction Stop 2>&1 | Out-Null
    Write-Host " OK" -ForegroundColor Green
} catch {
    if ($_.Exception.Message -like "*already installed*") {
        Write-Host " Already installed" -ForegroundColor Gray
    } elseif ($_.Exception.Message -like "*Access is denied*") {
        Write-Host " SKIP (no permission)" -ForegroundColor Gray
    } else {
        Write-Host " FAILED" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SETUP COMPLETE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "All drives and printers have been configured!" -ForegroundColor Green
Write-Host ""
Write-Host "IMPORTANT: Please REBOOT your computer now." -ForegroundColor Yellow
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
