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

# Get credentials using Windows dialog (handles special chars!)
function Get-Creds {
    $cred = Get-Credential -Message "Enter your domain credentials" -UserName "$Domain\"
    if (!$cred) {
        Write-Host "Cancelled." -ForegroundColor Yellow
        exit
    }
    return $cred
}

# Map drive using PSCredential (safest method)
function Map-Drive {
    param($Letter, $Path, $Name, $Cred)
    
    try {
        # Remove if exists
        if (Test-Path $Letter) {
            Remove-PSDrive -Name $Letter.TrimEnd(':') -Force -ErrorAction SilentlyContinue
            net use $Letter /delete /yes 2>&1 | Out-Null
        }
        
        # Map using New-PSDrive (handles special chars in password!)
        New-PSDrive -Name $Letter.TrimEnd(':') -PSProvider FileSystem -Root $Path -Credential $Cred -Persist -Scope Global -ErrorAction Stop | Out-Null
        
        Write-Host "[OK] $Letter -> $Name" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "[SKIP] $Letter -> $Name" -ForegroundColor Yellow
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
    Write-Host "Mapping standard drives..." -ForegroundColor Cyan
    Write-Host ""
    
    $cred = Get-Creds
    $count = 0
    
    foreach ($s in $Shares) {
        if (Map-Drive -Letter $s.L -Path $s.P -Name $s.N -Cred $cred) { $count++ }
    }
    
    # Personal
    $username = $cred.UserName.Split('\')[-1]
    $personalPath = "\\$Server\EMPLOYEE$\$username"
    if (Map-Drive -Letter "P:" -Path $personalPath -Name "Personal" -Cred $cred) { $count++ }
    
    Write-Host ""
    Write-Host "Mapped: $count drives" -ForegroundColor Green
}

# OPTION 2: Special
elseif ($Option -eq "2") {
    Write-Host ""
    Write-Host "Mapping special shares..." -ForegroundColor Cyan
    Write-Host ""
    
    $cred = Get-Creds
    $count = 0
    
    foreach ($s in $SpecialShares) {
        if (Map-Drive -Letter $s.L -Path $s.P -Name $s.N -Cred $cred) { $count++ }
    }
    
    Write-Host ""
    Write-Host "Mapped: $count shares" -ForegroundColor Green
}

# OPTION 3: Remove
elseif ($Option -eq "3") {
    Write-Host ""
    Write-Host "Removing all drives..." -ForegroundColor Cyan
    
    foreach ($s in $Shares + $SpecialShares) {
        if (Test-Path $s.L) {
            Remove-PSDrive -Name $s.L.TrimEnd(':') -Force -ErrorAction SilentlyContinue
            net use $s.L /delete /yes 2>&1 | Out-Null
        }
    }
    if (Test-Path "P:") {
        Remove-PSDrive -Name "P" -Force -ErrorAction SilentlyContinue
        net use P: /delete /yes 2>&1 | Out-Null
    }
    
    Write-Host "[OK] All removed" -ForegroundColor Green
}

Write-Host ""
pause
