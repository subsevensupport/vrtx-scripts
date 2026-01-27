# =====================================================================
#  Vortex Systems - ULTRA SIMPLE Drive Mapper
#  No credential storage, no fancy stuff - just map drives!
# =====================================================================

param([string]$Option)

$Server = "VORTEXFS.hq.vortex-systems.com"
$Domain = "hq.vortex-systems.com"

# All shares
$Shares = @(
    @{L = "U:"; P = "\\$Server\BUSINESS$"; N = "BUSINESS"},
    @{L = "O:"; P = "\\$Server\EMPLOYEE$"; N = "EMPLOYEE"},
    @{L = "R:"; P = "\\$Server\ENGINEERING RECORDS$"; N = "ENGINEERING RECORDS"},
    @{L = "Q:"; P = "\\$Server\ENGINEERING$"; N = "ENGINEERING"},
    @{L = "N:"; P = "\\$Server\FINANCE-HR$"; N = "FINANCE-HR"},
    @{L = "S:"; P = "\\$Server\SOFTWARE$"; N = "SOFTWARE"},
    @{L = "V:"; P = "\\$Server\VORTEX"; N = "VORTEX"}
)

$SpecialShares = @(
    @{L = "T:"; P = "\\$Server\0-quotations$"; N = "Quotations"},
    @{L = "I:"; P = "\\$Server\crib-catalog$"; N = "Crib Catalog"}
)

# Get credentials - SAME METHOD AS PRINTER SCRIPT
function Get-Creds {
    Write-Host ""
    Write-Host "Authentication required" -ForegroundColor Yellow
    Write-Host ""
    
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
    
    $fullUsername = "$Domain\$username"
    
    Write-Host ""
    Write-Host "[OK] Using credentials for: $fullUsername" -ForegroundColor Green
    
    # Return both username and password for use
    return @{
        FullUsername = $fullUsername
        Username = $username
        Password = $password
    }
}

# Map drive using cmdkey + net use (SAME AS PRINTER SCRIPT METHOD)
function Map-Drive {
    param($Letter, $Path, $Name)
    
    Write-Host "  $Name..." -ForegroundColor Cyan -NoNewline
    
    try {
        # Remove if exists
        if (Test-Path $Letter) {
            net use $Letter /delete /yes 2>&1 | Out-Null
        }
        
        # Map using stored credentials (from cmdkey)
        $result = net use $Letter $Path /persistent:yes 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host " Mapped" -ForegroundColor Green
            return $true
        } else {
            Write-Host " Failed" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host " Failed" -ForegroundColor Red
        return $false
    }
}

# MENU
if (-not $Option) {
    Clear-Host
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  VORTEX SYSTEMS - DRIVE MAPPER" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1. Map Standard Drives" -ForegroundColor White
    Write-Host "  2. Map Special Shares" -ForegroundColor White
    Write-Host "  3. Remove All" -ForegroundColor White
    Write-Host ""
    $Option = Read-Host "Choose (1-3)"
}

# OPTION 1: Standard
if ($Option -eq "1") {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Mapping Standard Drives" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
    # Get credentials (same as printer script)
    $cred = Get-Creds
    
    # Store credentials using cmdkey (same as printer script)
    Write-Host "Storing credentials..." -ForegroundColor Gray
    & cmdkey /add:$Server /user:$cred.FullUsername /pass:$cred.Password 2>&1 | Out-Null
    
    Write-Host ""
    Write-Host "Mapping drives..." -ForegroundColor Yellow
    Write-Host ""
    
    $count = 0
    
    foreach ($s in $Shares) {
        if (Map-Drive -Letter $s.L -Path $s.P -Name $s.N) { $count++ }
    }
    
    # Personal
    Write-Host ""
    Write-Host "Mapping personal folder..." -ForegroundColor Yellow
    Write-Host ""
    $personalPath = "\\$Server\EMPLOYEE$\$($cred.Username)"
    if (Map-Drive -Letter "P:" -Path $personalPath -Name "Personal") { $count++ }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Mapped: $count drives" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
}

# OPTION 2: Special
elseif ($Option -eq "2") {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Mapping Special Shares" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
    # Get credentials (same as printer script)
    $cred = Get-Creds
    
    # Store credentials using cmdkey (same as printer script)
    Write-Host "Storing credentials..." -ForegroundColor Gray
    & cmdkey /add:$Server /user:$cred.FullUsername /pass:$cred.Password 2>&1 | Out-Null
    
    Write-Host ""
    Write-Host "Mapping special shares..." -ForegroundColor Yellow
    Write-Host ""
    
    $count = 0
    
    foreach ($s in $SpecialShares) {
        if (Map-Drive -Letter $s.L -Path $s.P -Name $s.N) { $count++ }
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Mapped: $count shares" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
}

# OPTION 3: Remove
elseif ($Option -eq "3") {
    Write-Host ""
    Write-Host "Removing all drives..." -ForegroundColor Cyan
    Write-Host ""
    
    # Clear cmdkey
    & cmdkey /delete:$Server 2>&1 | Out-Null
    
    # Remove all drives
    foreach ($s in $Shares + $SpecialShares) {
        if (Test-Path $s.L) {
            net use $s.L /delete /yes 2>&1 | Out-Null
            Write-Host "  Removed $($s.L)" -ForegroundColor Gray
        }
    }
    if (Test-Path "P:") {
        net use P: /delete /yes 2>&1 | Out-Null
        Write-Host "  Removed P:" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "[OK] All removed" -ForegroundColor Green
}

Write-Host ""
pause
