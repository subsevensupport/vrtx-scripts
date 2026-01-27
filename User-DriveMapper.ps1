# =====================================================================
#  Vortex Systems - Network Drive Mapper (SIMPLIFIED)
#  Works like GUI - simple and reliable
# =====================================================================

param(
    [ValidateSet("1","2","3","4")]
    [string]$Option
)

# Configuration
$ServerFQDN = "VORTEXFS.hq.vortex-systems.com"
$Domain = "hq.vortex-systems.com"
$LogFolder = "C:\VortexLogs"
$LogFile = Join-Path $LogFolder "DriveMapper_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Create log folder
if (-not (Test-Path $LogFolder)) {
    New-Item -Path $LogFolder -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
}

# Logging function
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    try {
        Add-Content -Path $LogFile -Value "[$timestamp] $Message" -ErrorAction SilentlyContinue
    } catch {}
}

Write-Log "=== Script started by $env:USERNAME on $env:COMPUTERNAME ==="

# All shares - will try to map all, server enforces permissions
$AllShares = @(
    @{Letter = "U:"; Path = "\\$ServerFQDN\BUSINESS$"; Name = "BUSINESS"},
    @{Letter = "O:"; Path = "\\$ServerFQDN\EMPLOYEE$"; Name = "EMPLOYEE"},
    @{Letter = "R:"; Path = "\\$ServerFQDN\ENGINEERING RECORDS$"; Name = "ENGINEERING RECORDS"},
    @{Letter = "Q:"; Path = "\\$ServerFQDN\ENGINEERING$"; Name = "ENGINEERING"},
    @{Letter = "N:"; Path = "\\$ServerFQDN\FINANCE-HR$"; Name = "FINANCE-HR"},
    @{Letter = "S:"; Path = "\\$ServerFQDN\SOFTWARE$"; Name = "SOFTWARE"},
    @{Letter = "V:"; Path = "\\$ServerFQDN\VORTEX"; Name = "VORTEX"},
    @{Letter = "T:"; Path = "\\$ServerFQDN\0-quotations$"; Name = "Quotations"},
    @{Letter = "I:"; Path = "\\$ServerFQDN\crib-catalog$"; Name = "Crib Catalog"}
)

# Simple credential prompt
function Get-Credentials {
    Write-Host ""
    Write-Host "Enter your credentials" -ForegroundColor Cyan
    Write-Host ""
    
    $username = Read-Host "Username (just username, no domain)"
    $password_secure = Read-Host "Password" -AsSecureString
    $password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password_secure))
    
    return @{
        Username = $username
        Password = $password
        UPN = "$username@$Domain"
    }
}

# Simple drive mapping function - exactly like GUI
function Map-Drive {
    param(
        [string]$Letter,
        [string]$Path,
        [string]$Name,
        [string]$Username,
        [string]$Password
    )
    
    try {
        # Remove if already mapped
        if (Test-Path $Letter) {
            net use $Letter /delete /yes 2>&1 | Out-Null
        }
        
        # Map using WScript.Network (exactly like GUI)
        $network = New-Object -ComObject WScript.Network
        $network.MapNetworkDrive($Letter, $Path, $true, "$Domain\$Username", $Password)
        
        Write-Host "[OK] $Letter -> $Name" -ForegroundColor Green
        Write-Log "Mapped $Letter to $Path"
        return $true
        
    } catch {
        # If access denied, skip silently (server enforces permissions)
        if ($_.Exception.Message -match "access|denied|1326") {
            Write-Host "[SKIP] $Letter -> $Name (no permission)" -ForegroundColor Yellow
            Write-Log "Skipped $Letter - no permission"
        } else {
            Write-Host "[SKIP] $Letter -> $Name ($($_.Exception.Message))" -ForegroundColor Yellow
            Write-Log "Failed $Letter - $($_.Exception.Message)"
        }
        return $false
    }
}

# MAIN MENU
if (-not $Option) {
    Clear-Host
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "           VORTEX SYSTEMS - NETWORK DRIVE MAPPER" -ForegroundColor Cyan
    Write-Host "                    Simplified Version" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Select an option:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  1. Map My Drives" -ForegroundColor White
    Write-Host "  2. Remove All Drives" -ForegroundColor White
    Write-Host ""
    
    $Option = Read-Host "Enter option (1-2)"
}

Write-Log "User selected option: $Option"

# OPTION 1: MAP DRIVES
if ($Option -eq "1") {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "                    MAPPING NETWORK DRIVES" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Get credentials
    $cred = Get-Credentials
    $username = $cred.Username
    $password = $cred.Password
    
    Write-Host ""
    Write-Host "Mapping drives..." -ForegroundColor Cyan
    Write-Host ""
    
    $successCount = 0
    
    # Map all standard drives
    foreach ($share in $AllShares) {
        if (Map-Drive -Letter $share.Letter -Path $share.Path -Name $share.Name -Username $username -Password $password) {
            $successCount++
        }
        Start-Sleep -Milliseconds 200
    }
    
    # Map personal folder
    Write-Host ""
    Write-Host "Mapping personal folder..." -ForegroundColor Cyan
    $personalPath = "\\$ServerFQDN\EMPLOYEE$\$username"
    if (Map-Drive -Letter "P:" -Path $personalPath -Name "Personal" -Username $username -Password $password) {
        $successCount++
    }
    
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "                         COMPLETE" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Drives mapped successfully: $successCount" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your drives are ready to use!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Note: Drives will auto-reconnect at next login" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Log "=== Completed - $successCount drives mapped ==="
}

# OPTION 2: REMOVE ALL DRIVES
elseif ($Option -eq "2") {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "                    REMOVE ALL DRIVES" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $confirm = Read-Host "Remove all mapped drives? (Y/N)"
    if ($confirm -ne "Y") {
        Write-Host "Cancelled." -ForegroundColor Yellow
        exit
    }
    
    Write-Host ""
    Write-Host "Removing drives..." -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($share in $AllShares) {
        if (Test-Path $share.Letter) {
            try {
                net use $share.Letter /delete /yes 2>&1 | Out-Null
                Write-Host "[OK] Removed $($share.Letter)" -ForegroundColor Green
            } catch {
                Write-Host "[SKIP] $($share.Letter)" -ForegroundColor Yellow
            }
        }
    }
    
    if (Test-Path "P:") {
        net use P: /delete /yes 2>&1 | Out-Null
        Write-Host "[OK] Removed P:" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "All drives removed." -ForegroundColor Green
    Write-Host ""
    
    Write-Log "=== All drives removed ==="
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Write-Log "=== Script completed ==="
