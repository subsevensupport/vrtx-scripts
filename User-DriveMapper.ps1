# =====================================================================
#  Vortex Systems - Network Drive Mapper
#  Version 2.0 - Final Release
#  
#  For workgroup PCs accessing on-premises file server
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
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    try {
        Add-Content -Path $LogFile -Value "[$timestamp] [$Level] $Message" -ErrorAction SilentlyContinue
    } catch {}
}

Write-Log "Script started by $env:USERNAME on $env:COMPUTERNAME"


# Standard shares
$Shares = @(
    @{Letter = "U:"; Path = "\\$ServerFQDN\BUSINESS$"; Name = "BUSINESS"},
    @{Letter = "O:"; Path = "\\$ServerFQDN\EMPLOYEE$"; Name = "EMPLOYEE"; RequireWrite = $true},
    @{Letter = "R:"; Path = "\\$ServerFQDN\ENGINEERING RECORDS$"; Name = "ENGINEERING RECORDS"},
    @{Letter = "Q:"; Path = "\\$ServerFQDN\ENGINEERING$"; Name = "ENGINEERING"},
    @{Letter = "N:"; Path = "\\$ServerFQDN\FINANCE-HR$"; Name = "FINANCE-HR"},
    @{Letter = "S:"; Path = "\\$ServerFQDN\SOFTWARE$"; Name = "SOFTWARE"},
    @{Letter = "V:"; Path = "\\$ServerFQDN\VORTEX"; Name = "VORTEX"}
)

# Special shares (require AD group membership)
$SpecialShares = @(
    @{
        Letter = "T:"
        Path = "\\$ServerFQDN\0-quotations$"
        Name = "Quotations"
        RequiredADGroups = @("FS_SP_BUSS_0-Quotations_RW")
        RequireWrite = $true
    },
    @{
        Letter = "I:"
        Path = "\\$ServerFQDN\crib-catalog$"
        Name = "Crib Catalog"
        RequiredADGroups = @("FS_SP_VTX_Crib-Catalog_RW")
        RequireWrite = $true
    }
)

# Function to test share access using net use (FIXED - MORE RELIABLE)
function Test-ShareAccess {
    param(
        [string]$UNCPath,
        [string]$UserUPN,
        [string]$Password
    )
    try {
        $testDrive = "Z:"
        net use $testDrive /delete /yes 2>&1 | Out-Null
        $result = net use $testDrive $UNCPath /user:$UserUPN $Password 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            net use $testDrive /delete /yes 2>&1 | Out-Null
            return $true
        } else {
            Write-Log "Access test failed for $UNCPath : $result" "DEBUG"
            return $false
        }
    } catch {
        Write-Log "Access test error for $UNCPath : $($_.Exception.Message)" "DEBUG"
        return $false
    }
}

# Function to test write access
function Test-WriteAccess {
    param(
        [string]$UNCPath,
        [string]$UserUPN,
        [string]$Password
    )
    
    try {
        $testDrive = "Z:"
        net use $testDrive /delete /yes 2>&1 | Out-Null
        $result = net use $testDrive $UNCPath /user:$UserUPN $Password 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            return $false
        }
        
        $testFile = "${testDrive}\~vortex_write_test_$(Get-Date -Format 'yyyyMMddHHmmss').tmp"
        try {
            New-Item -Path $testFile -ItemType File -Force -ErrorAction Stop | Out-Null
            Remove-Item -Path $testFile -Force -ErrorAction SilentlyContinue
            net use $testDrive /delete /yes 2>&1 | Out-Null
            return $true
        } catch {
            net use $testDrive /delete /yes 2>&1 | Out-Null
            Write-Log "Write test failed for $UNCPath : $($_.Exception.Message)" "DEBUG"
            return $false
        }
    } catch {
        net use $testDrive /delete /yes 2>&1 | Out-Null
        return $false
    }
}

# Function to get user AD groups via LDAP
function Get-UserADGroups {
    param([string]$Username)
    
    try {
        $searcher = New-Object System.DirectoryServices.DirectorySearcher
        $searcher.SearchRoot = New-Object System.DirectoryServices.DirectoryEntry("LDAP://hq.vortex-systems.com")
        $searcher.Filter = "(&(objectCategory=person)(objectClass=user)(sAMAccountName=$Username))"
        $searcher.PropertiesToLoad.Add("memberOf") | Out-Null
        
        $result = $searcher.FindOne()
        if ($result) {
            $groups = @()
            foreach ($groupDN in $result.Properties["memberOf"]) {
                if ($groupDN -match 'CN=([^,]+)') {
                    $groups += $matches[1]
                }
            }
            Write-Log "Found $($groups.Count) AD groups for $Username"
            return $groups
        }
    } catch {
        Write-Log "AD group lookup failed: $($_.Exception.Message)" "WARNING"
    }
    return @()
}

# Function to get credentials
function Get-CustomCredential {
    param([string]$Purpose = "network drive mapping")
    
    Write-Host ""
    Write-Host "Enter your credentials for $Purpose" -ForegroundColor Cyan
    Write-Host ""
    
    $username = Read-Host "Username (no domain, just username)"
    $password_secure = Read-Host "Password" -AsSecureString
    $password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password_secure))
    
    return @{
        Username = $username
        Password = $password
        UPN = "$username@$Domain"
    }
}

# Function to store credentials
function Store-Credentials {
    param(
        [string]$Username,
        [string]$Password,
        [string]$UPN
    )
    
    try {
        $regPath = "HKCU:\Software\Vortex\DriveMapper"
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }
        
        $passwordBytes = [System.Text.Encoding]::UTF8.GetBytes($Password)
        $passwordBase64 = [Convert]::ToBase64String($passwordBytes)
        
        Set-ItemProperty -Path $regPath -Name "UPN" -Value $UPN -Force
        Set-ItemProperty -Path $regPath -Name "Username" -Value $Username -Force
        Set-ItemProperty -Path $regPath -Name "Password" -Value $passwordBase64 -Force
        
        Write-Log "Credentials stored successfully"
        return $true
    } catch {
        Write-Log "Failed to store credentials: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Function to retrieve stored credentials
function Get-StoredCredentials {
    try {
        $regPath = "HKCU:\Software\Vortex\DriveMapper"
        if (Test-Path $regPath) {
            $props = Get-ItemProperty -Path $regPath
            if ($props.UPN -and $props.Username -and $props.Password) {
                $passwordBytes = [Convert]::FromBase64String($props.Password)
                $password = [System.Text.Encoding]::UTF8.GetString($passwordBytes)
                
                return @{
                    Username = $props.Username
                    Password = $password
                    UPN = $props.UPN
                }
            }
        }
    } catch {
        Write-Log "Failed to retrieve stored credentials: $($_.Exception.Message)" "WARNING"
    }
    return $null
}

# Function to fix trust relationship
function Fix-TrustRelationship {
    Write-Host "Configuring trust relationship..." -ForegroundColor Cyan
    Write-Log "Applying trust relationship fix"
    
    try {
        $zonePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\vortex-systems.com"
        if (-not (Test-Path $zonePath)) {
            New-Item -Path $zonePath -Force | Out-Null
        }
        
        Set-ItemProperty -Path $zonePath -Name "file" -Value 1 -Type DWord -Force
        
        $hqPath = "$zonePath\hq"
        if (-not (Test-Path $hqPath)) {
            New-Item -Path $hqPath -Force | Out-Null
        }
        Set-ItemProperty -Path $hqPath -Name "file" -Value 1 -Type DWord -Force
        
        Write-Host "[OK] Trust relationship configured" -ForegroundColor Green
        Write-Log "Trust relationship configured successfully"
        
        Write-Host ""
        Write-Host "IMPORTANT: You must REBOOT for the trust fix to take effect!" -ForegroundColor Yellow
        Write-Host ""
        
        return $true
    } catch {
        Write-Host "[WARNING] Failed to configure trust relationship" -ForegroundColor Yellow
        Write-Log "Trust relationship fix failed: $($_.Exception.Message)" "WARNING"
        return $false
    }
}

# Function to map a drive with full persistence
function Map-NetworkDrive {
    param(
        [string]$DriveLetter,
        [string]$UNCPath,
        [string]$UserUPN,
        [string]$Password,
        [string]$Label = ""
    )
    
    try {
        if (Test-Path $DriveLetter) {
            net use $DriveLetter /delete /yes 2>&1 | Out-Null
        }
        
        # Store credentials using cmdkey (handles special characters automatically)
        cmdkey /add:$ServerFQDN /user:$UserUPN /pass:$Password 2>&1 | Out-Null
        cmdkey /add:$UNCPath /user:$UserUPN /pass:$Password 2>&1 | Out-Null
        
        # Map drive using stored credentials (no password in command line)
        $result = net use $DriveLetter $UNCPath /persistent:yes 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            throw "net use failed: $result"
        }
        
        $letter = $DriveLetter.TrimEnd(':')
        $regPath = "HKCU:\Network\$letter"
        
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }
        
        Set-ItemProperty -Path $regPath -Name "RemotePath" -Value $UNCPath -Force
        Set-ItemProperty -Path $regPath -Name "UserName" -Value $UserUPN -Force
        Set-ItemProperty -Path $regPath -Name "ProviderName" -Value "Microsoft Windows Network" -Force
        Set-ItemProperty -Path $regPath -Name "ProviderType" -Value 0x20000 -Type DWord -Force
        Set-ItemProperty -Path $regPath -Name "ConnectionType" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $regPath -Name "ConnectFlags" -Value 0 -Type DWord -Force
        Set-ItemProperty -Path $regPath -Name "DeferFlags" -Value 4 -Type DWord -Force
        
        net use $DriveLetter /persistent:yes 2>&1 | Out-Null
        
        $signature = @'
[DllImport("shell32.dll", CharSet = CharSet.Auto)]
public static extern int SHChangeNotify(int eventId, int flags, IntPtr item1, IntPtr item2);
'@
        $type = Add-Type -MemberDefinition $signature -Name ShellNotify -Namespace Win32 -PassThru -ErrorAction SilentlyContinue
        if ($type) {
            $type::SHChangeNotify(0x8000000, 0x1000, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null
        }
        
        Write-Host "[OK] $DriveLetter -> $Label" -ForegroundColor Green
        Write-Log "Mapped $DriveLetter to $UNCPath successfully"
        return $true
        
    } catch {
        Write-Host "[FAILED] $DriveLetter -> $Label : $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "Failed to map $DriveLetter : $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Function to remove all drives
function Remove-AllDrives {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "                    REMOVE ALL DRIVES" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "This will:" -ForegroundColor Yellow
    Write-Host "  * Remove all mapped drives" -ForegroundColor Yellow
    Write-Host "  * Clear stored credentials" -ForegroundColor Yellow
    Write-Host "  * Clear all registry settings" -ForegroundColor Yellow
    Write-Host ""
    
    $confirm = Read-Host "Are you sure? (Y/N)"
    if ($confirm -ne "Y") {
        Write-Host "Cancelled." -ForegroundColor Yellow
        return
    }
    
    Write-Host ""
    Write-Host "Removing drives..." -ForegroundColor Cyan
    
    $allDrives = $Shares + $SpecialShares
    foreach ($drive in $allDrives) {
        if (Test-Path $drive.Letter) {
            try {
                net use $drive.Letter /delete /yes 2>&1 | Out-Null
                Write-Host "[OK] Removed $($drive.Letter)" -ForegroundColor Green
            } catch {
                Write-Host "[WARNING] Could not remove $($drive.Letter)" -ForegroundColor Yellow
            }
        }
    }
    
    if (Test-Path "P:") {
        net use P: /delete /yes 2>&1 | Out-Null
        Write-Host "[OK] Removed P:" -ForegroundColor Green
    }
    
    cmdkey /delete:$ServerFQDN 2>&1 | Out-Null
    foreach ($drive in $allDrives) {
        cmdkey /delete:$($drive.Path) 2>&1 | Out-Null
    }
    
    try {
        $regPath = "HKCU:\Software\Vortex\DriveMapper"
        if (Test-Path $regPath) {
            Remove-Item -Path $regPath -Recurse -Force
            Write-Host "[OK] Cleared stored settings" -ForegroundColor Green
        }
    } catch {}
    
    Write-Host ""
    Write-Host "All drives and credentials removed." -ForegroundColor Green
    Write-Host ""
    Write-Log "All drives and credentials removed"
}

# MAIN MENU
if (-not $Option) {
    Clear-Host
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "           VORTEX SYSTEMS - NETWORK DRIVE MAPPER" -ForegroundColor Cyan
    Write-Host "                    Version 2.0 Final" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Select an option:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  1. Map My Drives (Standard setup)" -ForegroundColor White
    Write-Host "  2. Update Password Only" -ForegroundColor White
    Write-Host "  3. Fix Connection Issues (Trust relationship)" -ForegroundColor White
    Write-Host "  4. Remove Everything (Uninstall)" -ForegroundColor White
    Write-Host ""
    
    $Option = Read-Host "Enter option (1-4)"
}

Write-Log "User selected option: $Option"

# OPTION 1: MAP DRIVES
if ($Option -eq "1") {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "                    MAPPING NETWORK DRIVES" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $stored = Get-StoredCredentials
    if ($stored) {
        Write-Host "Using stored credentials for: $($stored.Username)" -ForegroundColor Green
        $username = $stored.Username
        $password = $stored.Password
        $upn = $stored.UPN
    } else {
        $cred = Get-CustomCredential
        $username = $cred.Username
        $password = $cred.Password
        $upn = $cred.UPN
        
        Write-Host ""
        Write-Host "Testing credentials..." -ForegroundColor Cyan
        
        # Store credentials temporarily for test
        $testPath = $Shares[0].Path
        cmdkey /add:$ServerFQDN /user:$upn /pass:$password 2>&1 | Out-Null
        
        # Try to connect using stored credentials
        $testResult = net use * $testPath 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host ""
            Write-Host "[ERROR] Invalid credentials or cannot reach server" -ForegroundColor Red
            Write-Host "Please check your username/password and network connection." -ForegroundColor Red
            Write-Host "Error details: $testResult" -ForegroundColor Red
            Write-Host ""
            Write-Log "Credential test failed: $testResult" "ERROR"
            pause
            exit 1
        }
        
        # Clean up test connection
        net use * /delete /yes 2>&1 | Out-Null
        
        Write-Host "[OK] Credentials verified" -ForegroundColor Green
        
        Store-Credentials -Username $username -Password $password -UPN $upn
    }
    
    if ($isAdmin) {
        Fix-TrustRelationship | Out-Null
    } else {
        Write-Host "[INFO] Run as administrator for trust relationship fix" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "Checking permissions..." -ForegroundColor Cyan
    $userGroups = Get-UserADGroups -Username $username
    
    $accessibleSpecialShares = @()
    foreach ($share in $SpecialShares) {
        $hasGroup = $false
        foreach ($reqGroup in $share.RequiredADGroups) {
            if ($userGroups -contains $reqGroup) {
                $hasGroup = $true
                Write-Host "[OK] You are in group: $reqGroup" -ForegroundColor Green
                break
            }
        }
        
        if ($hasGroup) {
            $accessibleSpecialShares += $share
        } else {
            Write-Host "[SKIP] Not in required group for: $($share.Name)" -ForegroundColor Yellow
        }
    }
    
    Write-Host ""
    Write-Host "Mapping standard drives..." -ForegroundColor Cyan
    $successCount = 0
    
    foreach ($share in $Shares) {
        # Just try to map - if it works, great. If not, skip it.
        if (Map-NetworkDrive -DriveLetter $share.Letter -UNCPath $share.Path -UserUPN $upn -Password $password -Label $share.Name) {
            $successCount++
        }
    }
    
    Write-Host ""
    Write-Host "Mapping personal folder..." -ForegroundColor Cyan
    $personalPath = "\\$ServerFQDN\EMPLOYEE$\$username"
    if (Map-NetworkDrive -DriveLetter "P:" -UNCPath $personalPath -UserUPN $upn -Password $password -Label "Personal") {
        $successCount++
    }
    
    if ($accessibleSpecialShares.Count -gt 0) {
        Write-Host ""
        Write-Host "Mapping special shares..." -ForegroundColor Cyan
        foreach ($share in $accessibleSpecialShares) {
            if (Map-NetworkDrive -DriveLetter $share.Letter -UNCPath $share.Path -UserUPN $upn -Password $password -Label $share.Name) {
                $successCount++
            }
        }
    }
    
    try {
        $regPath = "HKCU:\Software\Vortex\DriveMapper"
        $sharesList = ($Shares + @(@{Letter="P:"}) + $accessibleSpecialShares | ForEach-Object { $_.Letter }) -join ","
        Set-ItemProperty -Path $regPath -Name "AccessibleShares" -Value $sharesList -Force
    } catch {}
    
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "                         SUMMARY" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Drives mapped successfully: $successCount" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "Verifying persistence settings..." -ForegroundColor Cyan
    $persistentCount = 0
    foreach ($drive in (Get-PSDrive -PSProvider FileSystem | Where-Object { $_.DisplayRoot -like "\\$ServerFQDN\*" })) {
        $letter = $drive.Name
        $regPath = "HKCU:\Network\$letter"
        if (Test-Path $regPath) {
            $props = Get-ItemProperty -Path $regPath
            if ($props.ConnectionType -eq 1) {
                $persistentCount++
            }
        }
    }
    Write-Host "[OK] $persistentCount drives configured for auto-reconnect" -ForegroundColor Green
    
    Write-Host ""
    if ($isAdmin) {
        Write-Host "Network wait enabled: Drives will be ready when Windows starts" -ForegroundColor Green
        Write-Host ""
        Write-Host "IMPORTANT: Please REBOOT for all settings to take effect!" -ForegroundColor Yellow
        Write-Host "After reboot:" -ForegroundColor Cyan
        Write-Host "  * Trust relationship will be active" -ForegroundColor Cyan
        Write-Host "  * Drives will reconnect automatically" -ForegroundColor Cyan
        Write-Host "  * No red X icons at startup" -ForegroundColor Cyan
    } else {
        Write-Host "For best results, run Quick-Setup.bat as administrator" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Log "Drive mapping completed - $successCount drives mapped"
}

# OPTION 2: UPDATE PASSWORD
elseif ($Option -eq "2") {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "                    UPDATE PASSWORD" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $cred = Get-CustomCredential -Purpose "password update"
    $username = $cred.Username
    $password = $cred.Password
    $upn = $cred.UPN
    
    Write-Host ""
    Write-Host "Testing new credentials..." -ForegroundColor Cyan
    
    # Store credentials temporarily for test
    $testPath = $Shares[0].Path
    cmdkey /add:$ServerFQDN /user:$upn /pass:$password 2>&1 | Out-Null
    
    # Try to connect using stored credentials
    $testResult = net use * $testPath 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "[ERROR] Invalid credentials" -ForegroundColor Red
        Write-Host "Error details: $testResult" -ForegroundColor Red
        Write-Host ""
        Write-Log "Password update failed - invalid credentials: $testResult" "ERROR"
        pause
        exit 1
    }
    
    net use * /delete /yes 2>&1 | Out-Null
    Write-Host "[OK] Credentials verified" -ForegroundColor Green
    
    Store-Credentials -Username $username -Password $password -UPN $upn
    
    cmdkey /delete:$ServerFQDN 2>&1 | Out-Null
    cmdkey /add:$ServerFQDN /user:$upn /pass:$password 2>&1 | Out-Null
    
    Write-Host ""
    Write-Host "Updating existing drives..." -ForegroundColor Cyan
    
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.DisplayRoot -like "\\$ServerFQDN\*" }
    foreach ($drive in $drives) {
        try {
            $letter = $drive.Name + ":"
            $path = $drive.DisplayRoot
            
            net use $letter /delete /yes 2>&1 | Out-Null
            
            # Store credentials for this path
            cmdkey /add:$path /user:$upn /pass:$password 2>&1 | Out-Null
            
            # Reconnect using stored credentials
            net use $letter $path /persistent:yes 2>&1 | Out-Null
            
            Write-Host "[OK] Updated $letter" -ForegroundColor Green
        } catch {
            Write-Host "[WARNING] Could not update $letter" -ForegroundColor Yellow
        }
    }
    
    Write-Host ""
    Write-Host "Password updated successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Log "Password updated successfully"
}

# OPTION 3: FIX CONNECTION ISSUES
elseif ($Option -eq "3") {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "                FIX CONNECTION ISSUES" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    if (Fix-TrustRelationship) {
        Write-Host "Trust relationship has been configured." -ForegroundColor Green
        Write-Host ""
        Write-Host "Please REBOOT your computer now." -ForegroundColor Yellow
        Write-Host ""
        
        $reboot = Read-Host "Reboot now? (Y/N)"
        if ($reboot -eq "Y") {
            Write-Host "Rebooting in 10 seconds..." -ForegroundColor Yellow
            shutdown /r /t 10 /c "Applying network trust relationship fix"
        }
    }
}

# OPTION 4: REMOVE EVERYTHING
elseif ($Option -eq "4") {
    Remove-AllDrives
}

# DONE
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Write-Log "Script completed"
