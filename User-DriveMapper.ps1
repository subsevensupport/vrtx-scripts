# =====================================================================
#  Vortex Systems - Network Drive Mapper
#  Using direct net use (proven to work)
# =====================================================================

param([string]$Option)

$ServerFQDN = "VORTEXFS.hq.vortex-systems.com"
$Domain = "hq.vortex-systems.com"

# Standard shares
$StandardShares = @(
    @{Letter = "U:"; Path = "\\$ServerFQDN\BUSINESS$"; Name = "BUSINESS"},
    @{Letter = "O:"; Path = "\\$ServerFQDN\EMPLOYEE$"; Name = "EMPLOYEE"},
    @{Letter = "R:"; Path = "\\$ServerFQDN\ENGINEERING RECORDS$"; Name = "ENGINEERING RECORDS"},
    @{Letter = "Q:"; Path = "\\$ServerFQDN\ENGINEERING$"; Name = "ENGINEERING"},
    @{Letter = "N:"; Path = "\\$ServerFQDN\FINANCE-HR$"; Name = "FINANCE-HR"},
    @{Letter = "S:"; Path = "\\$ServerFQDN\SOFTWARE$"; Name = "SOFTWARE"},
    @{Letter = "V:"; Path = "\\$ServerFQDN\VORTEX"; Name = "VORTEX"}
)

# Special shares
$SpecialShares = @(
    @{Letter = "T:"; Path = "\\$ServerFQDN\0-quotations$"; Name = "Quotations"},
    @{Letter = "I:"; Path = "\\$ServerFQDN\crib-catalog$"; Name = "Crib Catalog"}
)

# Get stored credentials
function Get-StoredCreds {
    try {
        $regPath = "HKCU:\Software\Vortex\DriveMapper"
        if (Test-Path $regPath) {
            $props = Get-ItemProperty -Path $regPath
            if ($props.Username -and $props.Password) {
                $password = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($props.Password))
                return @{Username = $props.Username; Password = $password}
            }
        }
    } catch {}
    return $null
}

# Store credentials
function Save-Creds {
    param([string]$Username, [string]$Password)
    try {
        $regPath = "HKCU:\Software\Vortex\DriveMapper"
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }
        $passwordBase64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Password))
        Set-ItemProperty -Path $regPath -Name "Username" -Value $Username -Force
        Set-ItemProperty -Path $regPath -Name "Password" -Value $passwordBase64 -Force
    } catch {}
}

# Get credentials
function Get-Creds {
    $stored = Get-StoredCreds
    if ($stored) {
        Write-Host "Using stored credentials for: $($stored.Username)" -ForegroundColor Green
        return $stored
    }
    
    Write-Host ""
    Write-Host "Enter your credentials" -ForegroundColor Cyan
    $username = Read-Host "Username (no domain)"
    $password_secure = Read-Host "Password" -AsSecureString
    $password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password_secure))
    
    Save-Creds -Username $username -Password $password
    return @{Username = $username; Password = $password}
}

# Clear all sessions
function Clear-Sessions {
    Write-Host "Clearing existing connections..." -ForegroundColor Cyan
    
    # Clear all drive letters
    foreach ($share in $StandardShares) {
        if (Test-Path $share.Letter) {
            net use $share.Letter /delete /yes 2>&1 | Out-Null
        }
    }
    foreach ($share in $SpecialShares) {
        if (Test-Path $share.Letter) {
            net use $share.Letter /delete /yes 2>&1 | Out-Null
        }
    }
    if (Test-Path "P:") {
        net use P: /delete /yes 2>&1 | Out-Null
    }
    
    # Clear server sessions
    net use \\$ServerFQDN /delete /yes 2>&1 | Out-Null
    
    Write-Host "[OK] Cleared" -ForegroundColor Green
    Write-Host ""
}

# Map a drive - USING METHOD THAT WORKS!
function Map-Drive {
    param([string]$Letter, [string]$Path, [string]$Name, [string]$Username, [string]$Password)
    
    try {
        # Use net use with credentials DIRECTLY (this is what works manually!)
        $domainUser = "$Domain\$Username"
        
        # Call net use with credentials
        $result = cmd /c "net use $Letter `"$Path`" /user:$domainUser $Password /persistent:yes 2>&1"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] $Letter -> $Name" -ForegroundColor Green
            return $true
        } else {
            Write-Host "[SKIP] $Letter -> $Name" -ForegroundColor Yellow
            Write-Host "       Error: $result" -ForegroundColor DarkGray
            return $false
        }
    } catch {
        Write-Host "[SKIP] $Letter -> $Name" -ForegroundColor Yellow
        Write-Host "       Exception: $($_.Exception.Message)" -ForegroundColor DarkGray
        return $false
    }
}

# MENU
if (-not $Option) {
    Clear-Host
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "           VORTEX SYSTEMS - NETWORK DRIVE MAPPER" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1. Map Standard Drives (U, O, R, Q, N, S, V, P)" -ForegroundColor White
    Write-Host "  2. Map Special Shares (T: Quotations, I: Crib)" -ForegroundColor White
    Write-Host "  3. Remove All Drives" -ForegroundColor White
    Write-Host ""
    $Option = Read-Host "Enter option (1-3)"
}

# OPTION 1: MAP STANDARD DRIVES
if ($Option -eq "1") {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "               MAPPING STANDARD DRIVES" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $cred = Get-Creds
    $username = $cred.Username
    $password = $cred.Password
    
    Write-Host ""
    Clear-Sessions
    
    Write-Host "Mapping standard drives..." -ForegroundColor Cyan
    Write-Host ""
    
    $successCount = 0
    
    foreach ($share in $StandardShares) {
        if (Map-Drive -Letter $share.Letter -Path $share.Path -Name $share.Name -Username $username -Password $password) {
            $successCount++
        }
        Start-Sleep -Milliseconds 300
    }
    
    Write-Host ""
    Write-Host "Mapping personal folder..." -ForegroundColor Cyan
    $personalPath = "\\$ServerFQDN\EMPLOYEE$\$username"
    if (Map-Drive -Letter "P:" -Path $personalPath -Name "Personal" -Username $username -Password $password) {
        $successCount++
    }
    
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "Drives mapped: $successCount" -ForegroundColor Green
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
}

# OPTION 2: MAP SPECIAL SHARES
elseif ($Option -eq "2") {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "               MAPPING SPECIAL SHARES" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Special shares (requires specific permissions):" -ForegroundColor Yellow
    Write-Host "  T: Quotations - Requires FS_SP_BUSS_0-Quotations_RW" -ForegroundColor Yellow
    Write-Host "  I: Crib Catalog - Requires FS_SP_VTX_Crib-Catalog_RW" -ForegroundColor Yellow
    Write-Host ""
    
    $cred = Get-Creds
    $username = $cred.Username
    $password = $cred.Password
    
    Write-Host ""
    Write-Host "Mapping special shares..." -ForegroundColor Cyan
    Write-Host ""
    
    $successCount = 0
    
    foreach ($share in $SpecialShares) {
        if (Map-Drive -Letter $share.Letter -Path $share.Path -Name $share.Name -Username $username -Password $password) {
            $successCount++
        }
        Start-Sleep -Milliseconds 300
    }
    
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "Special shares mapped: $successCount" -ForegroundColor Green
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
}

# OPTION 3: REMOVE ALL
elseif ($Option -eq "3") {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "                    REMOVE ALL DRIVES" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $confirm = Read-Host "Remove all drives and credentials? (Y/N)"
    if ($confirm -ne "Y") {
        Write-Host "Cancelled." -ForegroundColor Yellow
        exit
    }
    
    Write-Host ""
    Write-Host "Removing..." -ForegroundColor Cyan
    Write-Host ""
    
    Clear-Sessions
    
    try {
        $regPath = "HKCU:\Software\Vortex\DriveMapper"
        if (Test-Path $regPath) {
            Remove-Item -Path $regPath -Recurse -Force
            Write-Host "[OK] Credentials cleared" -ForegroundColor Green
        }
    } catch {}
    
    Write-Host ""
    Write-Host "[OK] All removed" -ForegroundColor Green
    Write-Host ""
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
