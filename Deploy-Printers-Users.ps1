# ============================================================================
# VORTEX SYSTEMS - PRINTER DEPLOYMENT (SERVER-AUTHORITATIVE)
# ============================================================================
# Purpose: Install printers based on PRINT SERVER permissions
# Model:   Client attempts install, server enforces access (like file shares)
# Works:   Workgroup PCs, nested AD groups, no LDAP, no RSAT
# ============================================================================

# ============================================================================
# CONFIGURATION
# ============================================================================

# Print servers (both domain-joined)
$printServers = @(
    "VORTEXFS.hq.vortex-systems.com",
    "SMARTWORKSPC"
)

# Printer list (server enforces permissions)
$printerMap = @{
    "SHOP-PRNT" = @{
        Server = "VORTEXFS.hq.vortex-systems.com"
        Printer = "SHOP-PRNT"
    }
    "SHOP-CLR-PRNT" = @{
        Server = "VORTEXFS.hq.vortex-systems.com"
        Printer = "SHOP-CLR-PRNT"
    }
    "MGNT-PRNT" = @{
        Server = "VORTEXFS.hq.vortex-systems.com"
        Printer = "MGNT-PRNT"
    }
    "LOBBY-PRNT" = @{
        Server = "VORTEXFS.hq.vortex-systems.com"
        Printer = "LOBBY-PRNT"
    }
    "PLOTTER" = @{
        Server = "SMARTWORKSPC"
        Printer = "Canon-TM-305"
    }
}

# ============================================================================
# AUTHENTICATION - Check if credentials needed
# ============================================================================

$ServerFQDN = "VORTEXFS.hq.vortex-systems.com"
$SmartworksPC = "SMARTWORKSPC"

$hasVortexAccess = Get-Printer -ComputerName $ServerFQDN -ErrorAction SilentlyContinue
$hasSmartworksAccess = Get-Printer -ComputerName $SmartworksPC -ErrorAction SilentlyContinue

if (-not $hasVortexAccess -or -not $hasSmartworksAccess) {
    Write-Host ""
    Write-Host "Authentication required for print servers" -ForegroundColor Yellow
    Write-Host ""
    
    # Clear existing connections
    & net use /delete "\\$ServerFQDN\*" /yes 2>&1 | Out-Null
    & net use /delete "\\$SmartworksPC\*" /yes 2>&1 | Out-Null
    & cmdkey /delete:$ServerFQDN 2>&1 | Out-Null
    & cmdkey /delete:$SmartworksPC 2>&1 | Out-Null
    
    $username = Read-Host "Username (no domain)"
    
    if ([string]::IsNullOrWhiteSpace($username)) {
        Write-Error "Authentication cancelled."
        exit 1
    }
    
    $securePass = Read-Host "Password" -AsSecureString
    $password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePass))
    
    if ([string]::IsNullOrWhiteSpace($password)) {
        Write-Error "Authentication cancelled."
        exit 1
    }
    
    $fullUsername = "VORTEX-SYSTEMS\$username"
    
    # Store credentials for both servers
    & cmdkey /add:$ServerFQDN /user:$fullUsername /pass:$password
    & cmdkey /add:$SmartworksPC /user:$fullUsername /pass:$password
    
    Write-Host "Credentials stored. Restarting script..." -ForegroundColor Green
    Start-Sleep -Seconds 2
    
    Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Wait
    exit 0
}

# ============================================================================
# HEADER
# ============================================================================

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host " Vortex Systems - Printer Deployment" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "User: $env:USERNAME" -ForegroundColor Gray
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor Gray
Write-Host ""

# ============================================================================
# STEP 1: GET CURRENT USER PRINTERS (ONLY FROM VORTEX SERVERS)
# ============================================================================

Write-Host "Step 1: Checking currently installed printers..." -ForegroundColor Yellow

$currentUserPrinters = Get-Printer | Where-Object {
    $_.Type -eq "Connection" -and (
        $_.Name -like "\\VORTEXFS.hq.vortex-systems.com\*" -or
        $_.Name -like "\\SMARTWORKSPC\*"
    )
}

$currentPrinterPaths = @()
if ($currentUserPrinters) {
    $currentPrinterPaths = $currentUserPrinters.Name
    Write-Host "  Found $($currentPrinterPaths.Count) installed printer(s)" -ForegroundColor Gray
} else {
    Write-Host "  No printers currently installed" -ForegroundColor Gray
}

Write-Host ""

# ============================================================================
# STEP 2: ATTEMPT PRINTER INSTALLS (SERVER DECIDES)
# ============================================================================

Write-Host "Step 2: Installing printers (server-enforced permissions)..." -ForegroundColor Yellow
Write-Host ""

$installedPrinters = @()
$added = 0
$existing = 0
$skipped = 0
$failed = 0

foreach ($entry in $printerMap.Values) {
    $server = $entry.Server
    $printer = $entry.Printer
    $path = "\\$server\$printer"

    Write-Host "  $printer on $server..." -ForegroundColor Cyan -NoNewline

    if ($currentPrinterPaths -contains $path) {
        Write-Host " Already installed" -ForegroundColor Gray
        $existing++
        $installedPrinters += $path
        continue
    }

    try {
        Add-Printer -ConnectionName $path -ErrorAction Stop
        Write-Host " Installed" -ForegroundColor Green
        $added++
        $installedPrinters += $path
        Start-Sleep -Seconds 1
    }
    catch {
        $errMsg = $_.Exception.Message
        if ($errMsg -like "*Access is denied*") {
            Write-Host " Skipped (no permission)" -ForegroundColor Gray
            $skipped++
        }
        else {
            Write-Host " Failed: $errMsg" -ForegroundColor Red
            $failed++
        }
    }
}

Write-Host ""

# ============================================================================
# STEP 3: REMOVE PRINTERS USER NO LONGER HAS ACCESS TO
# ============================================================================

Write-Host "Step 3: Removing unauthorized printers..." -ForegroundColor Yellow

$removed = 0

foreach ($printer in $currentUserPrinters) {
    if ($installedPrinters -notcontains $printer.Name) {
        Write-Host "  Removing $($printer.Name)..." -ForegroundColor Yellow -NoNewline
        try {
            Remove-Printer -Name $printer.Name -ErrorAction Stop
            Write-Host " Removed" -ForegroundColor Green
            $removed++
        }
        catch {
            Write-Host " Failed" -ForegroundColor Red
        }
    }
}

if ($removed -eq 0) {
    Write-Host "  No printers to remove" -ForegroundColor Gray
}

Write-Host ""

# ============================================================================
# SUMMARY
# ============================================================================

Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host " SUMMARY" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Added:        $added" -ForegroundColor Green
Write-Host "Existing:     $existing" -ForegroundColor Gray
Write-Host "Skipped:      $skipped (no permission)" -ForegroundColor Gray
Write-Host "Removed:      $removed" -ForegroundColor Yellow
Write-Host "Failed:       $failed" -ForegroundColor Red
Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

Read-Host "Press Enter to close"
exit $(if ($failed -gt 0) { 1 } else { 0 })