# =====================================================================
#  Vortex Systems - Network Drive Mapper (SIMPLE)
#  - Clears all sessions to server
#  - Stores credentials
#  - Removes existing shares before mapping
# =====================================================================

param([string]$Option)

$ServerFQDN = "VORTEXFS.hq.vortex-systems.com"
$Domain = "hq.vortex-systems.com"

# All shares
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

# Get stored credentials
function Get-StoredCreds {
    try {
        $regPath = "HKCU:\Software\Vortex\DriveMapper"
        if (Test-Path $regPath) {
            $props = Get-ItemProperty -Path $regPath
            if ($props.Username -and $props.Password) {
                $password = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($props.Password))
                return @{
                    Username = $props.Username
                    Password = $password
                }
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

# Map a drive
function Map-Drive {
    param([string]$Letter, [string]$Path, [string]$Name, [string]$Username, [string]$Password)
    
    try {
        $network = New-Object -ComObject WScript.Network
        $network.MapNetworkDrive($Letter, $Path, $true, "$Domain\$Username", $Password)
        Write-Host "[OK] $Letter -> $Name" -ForegroundColor Green
        return $true
    } catch {
        if ($_.Exception.Message -match "access|denied|1326") {
            Write-Host "[SKIP] $Letter -> $Name (no permission)" -ForegroundColor Yellow
            Write-Host $_.Exception.Message
        } else {
            Write-Host "[SKIP] $Letter -> $Name" -ForegroundColor Yellow
            Write-Host $_.Exception.Message
        }
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
    Write-Host "  1. Map My Drives" -ForegroundColor White
    Write-Host "  2. Remove All Drives" -ForegroundColor White
    Write-Host ""
    $Option = Read-Host "Enter option (1-2)"
}

# OPTION 1: MAP DRIVES
if ($Option -eq "1") {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "                    MAPPING NETWORK DRIVES" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Get credentials
    $cred = Get-Creds
    $username = $cred.Username
    $password = $cred.Password
    
    Write-Host ""
    Write-Host "Step 1: Clearing all existing sessions to server..." -ForegroundColor Cyan
    
    # CRITICAL: Clear ALL sessions to server to prevent "multiple connections" error
    net use \\$ServerFQDN /delete /yes 2>&1 | Out-Null
    
    # Also disconnect all drive letters
    foreach ($share in $AllShares) {
        if (Test-Path $share.Letter) {
            net use $share.Letter /delete /yes 2>&1 | Out-Null
        }
    }
    if (Test-Path "P:") {
        net use P: /delete /yes 2>&1 | Out-Null
    }
    
    Write-Host "[OK] All existing connections cleared" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "Step 2: Mapping drives..." -ForegroundColor Cyan
    Write-Host ""
    
    $successCount = 0
    
    # Map all shares
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
    Write-Host "Drives mapped: $successCount" -ForegroundColor Green
    Write-Host "Credentials stored for next time" -ForegroundColor Green
    Write-Host ""
}

# OPTION 2: REMOVE ALL
elseif ($Option -eq "2") {
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
    
    # Clear server sessions
    net use \\$ServerFQDN /delete /yes 2>&1 | Out-Null
    
    # Remove all drives
    foreach ($share in $AllShares) {
        if (Test-Path $share.Letter) {
            net use $share.Letter /delete /yes 2>&1 | Out-Null
        }
    }
    if (Test-Path "P:") {
        net use P: /delete /yes 2>&1 | Out-Null
    }
    
    # Clear stored credentials
    try {
        $regPath = "HKCU:\Software\Vortex\DriveMapper"
        if (Test-Path $regPath) {
            Remove-Item -Path $regPath -Recurse -Force
        }
    } catch {}
    
    Write-Host "[OK] All drives and credentials removed" -ForegroundColor Green
    Write-Host ""
}

Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
