# ============================================================================
# VORTEX SYSTEMS - PRINTER SETUP (PART 1: ADMIN CONFIGURATION)
# ============================================================================
# Purpose: One-time setup to configure Point and Print
# Run as: Administrator
# Run on: Each PC (only once)
# 
# This enables automatic driver installation from trusted print servers
# ============================================================================

# Configuration
$printServers = @(
    "VORTEXFS.hq.vortex-systems.com",
    "SMARTWORKSPC"
)

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host " Vortex Systems - Point and Print Configuration" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (!$isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator" -ForegroundColor Red
    Write-Host ""
    Write-Host "Right-click the BAT file and select 'Run as administrator'" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Running as Administrator..." -ForegroundColor Green
Write-Host ""

# ============================================================================
# CONFIGURE POINT AND PRINT
# ============================================================================

Write-Host "Configuring Point and Print..." -ForegroundColor Yellow
Write-Host ""

try {
    $regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint"
    
    # Create registry path if it doesn't exist
    if (!(Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
        Write-Host "  Created registry path" -ForegroundColor Gray
    }
    
    # Configure Point and Print to trust print servers
    Set-ItemProperty -Path $regPath -Name "TrustedServers" -Value 1 -Type DWord -Force
    Write-Host "  Enabled trusted servers mode" -ForegroundColor Green
    
    # Add server list (comma-separated)
    $serverList = $printServers -join ","
    Set-ItemProperty -Path $regPath -Name "ServerList" -Value $serverList -Type String -Force
    Write-Host "  Added trusted servers:" -ForegroundColor Green
    foreach ($server in $printServers) {
        Write-Host "    - $server" -ForegroundColor Gray
    }
    
    # Disable prompts for new connections
    Set-ItemProperty -Path $regPath -Name "NoWarningNoElevationOnInstall" -Value 1 -Type DWord -Force
    Write-Host "  Disabled prompts for new printer installations" -ForegroundColor Green
    
    # Disable prompts for driver updates
    Set-ItemProperty -Path $regPath -Name "UpdatePromptSettings" -Value 0 -Type DWord -Force
    Write-Host "  Disabled prompts for driver updates" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "Point and Print configured successfully!" -ForegroundColor Green
    
}
catch {
    Write-Host ""
    Write-Host "  ERROR: Could not configure Point and Print" -ForegroundColor Red
    Write-Host "  $_" -ForegroundColor Red
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# ============================================================================
# TEST CONNECTIVITY TO PRINT SERVERS
# ============================================================================

Write-Host ""
Write-Host "Testing connectivity to print servers..." -ForegroundColor Yellow
Write-Host ""

$allReachable = $true

foreach ($server in $printServers) {
    Write-Host "  Testing $server..." -ForegroundColor Cyan -NoNewline
    
    try {
        if (Test-Connection -ComputerName $server -Count 2 -Quiet -ErrorAction Stop) {
            Write-Host " Connected" -ForegroundColor Green
        }
        else {
            Write-Host " WARNING: Cannot reach server" -ForegroundColor Yellow
            $allReachable = $false
        }
    }
    catch {
        Write-Host " WARNING: Cannot reach server" -ForegroundColor Yellow
        $allReachable = $false
    }
}

Write-Host ""

if (!$allReachable) {
    Write-Host "WARNING: Some print servers are not reachable" -ForegroundColor Yellow
    Write-Host "Ensure PC is on VPN or internal network" -ForegroundColor Gray
    Write-Host ""
}

# ============================================================================
# SUMMARY
# ============================================================================

Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host " CONFIGURATION COMPLETE" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This PC is now configured for automatic printer installation" -ForegroundColor Green
Write-Host ""
Write-Host "What happens next:" -ForegroundColor Yellow
Write-Host "  1. Users log in to this PC" -ForegroundColor Gray
Write-Host "  2. User runs Part 2 script (Deploy-Printers-Users.ps1)" -ForegroundColor Gray
Write-Host "  3. Printers install automatically based on group membership" -ForegroundColor Gray
Write-Host "  4. Drivers download and install without admin prompts" -ForegroundColor Gray
Write-Host ""
Write-Host "Configured servers:" -ForegroundColor Yellow
foreach ($server in $printServers) {
    Write-Host "  - $server" -ForegroundColor Gray
}
Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

Read-Host "Press Enter to close"
exit 0
