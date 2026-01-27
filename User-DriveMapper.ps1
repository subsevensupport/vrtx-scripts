<#
Vortex Systems - Simple Drive Mapper (User) - FIXED
- Prompts for credentials
- Stores them in Credential Manager (cmdkey) for the file server target
- Maps drives with proper success/failure checks (no false [OK])
- Handles share names with spaces by quoting UNC paths
- Quietly removes existing mappings (suppresses NET HELPMSG 2250 noise)

Run this as the signed-in user (NOT as Administrator).
#>

$ErrorActionPreference = "Stop"

# ====== EDIT THESE IF NEEDED ======
$Server        = "VORTEXFS.hq.vortex-systems.com"
$NetBIOSDomain = "VORTEX-SYSTEMS"   # adjust if your NetBIOS name differs (e.g. VORTEX)
$ClearExistingConnectionsToServer = $true  # helps avoid NET USE error 1219
# =================================

# Drive definitions (edit share names here if needed)
$DriveMaps = @(
    @{ Letter = "U:"; Share = "BUSINESS$" },
    @{ Letter = "O:"; Share = "EMPLOYEE$" },
    @{ Letter = "R:"; Share = "ENGINEERING RECORDS$" },  # space is OK (quoted)
    @{ Letter = "Q:"; Share = "ENGINEERING$" },
    @{ Letter = "N:"; Share = "FINANCE-HR$" },
    @{ Letter = "S:"; Share = "SOFTWARE$" },
    @{ Letter = "V:"; Share = "VORTEX$" }
)

# Optional drives (will be attempted; failures are OK)
$OptionalDriveMaps = @(
    @{ Letter = "T:"; Share = "Quotations$" },      # <-- change to your real share name if different
    @{ Letter = "I:"; Share = "Crib Catalog$" }     # <-- change to your real share name if different
)

function Read-PlainPassword {
    param([string]$Prompt = "Password")
    $sec = Read-Host -AsSecureString $Prompt
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
    try { [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}

function Normalize-User {
    param([Parameter(Mandatory)][string]$UserInput)
    # If user typed DOMAIN\user or user@domain, keep it as-is.
    if ($UserInput -match '\\' -or $UserInput -match '@') { return $UserInput }
    return "$NetBIOSDomain\$UserInput"
}

function Remove-DriveQuiet {
    param([Parameter(Mandatory)][string]$Letter)
    cmd /c "net use $Letter /delete /y" > $null 2>&1
}

function Map-Drive {
    param(
        [Parameter(Mandatory)][string]$Letter,
        [Parameter(Mandatory)][string]$UNC,
        [Parameter(Mandatory)][string]$User,
        [Parameter(Mandatory)][string]$Password,
        [switch]$Optional
    )

    Remove-DriveQuiet -Letter $Letter

    # Quote UNC + username + password (handles spaces safely)
    $qUNC  = '"' + $UNC + '"'
    $qUser = '"' + $User + '"'
    $qPwd  = '"' + ($Password.Replace('"','\"')) + '"'

    $out = cmd /c "net use $Letter $qUNC /user:$qUser $qPwd /persistent:yes" 2>&1
    $rc = $LASTEXITCODE

    if ($rc -eq 0) {
        Write-Host "[OK]   $Letter -> $UNC" -ForegroundColor Green
        return $true
    }

    if ($Optional) {
        Write-Host "[SKIP] $Letter -> $UNC" -ForegroundColor Yellow
        Write-Host "       $out" -ForegroundColor DarkYellow
        return $false
    }

    Write-Host "[FAIL] $Letter -> $UNC" -ForegroundColor Red
    Write-Host "       $out" -ForegroundColor Red
    return $false
}

function Add-CmdKey {
    param(
        [Parameter(Mandatory)][string]$Target,
        [Parameter(Mandatory)][string]$User,
        [Parameter(Mandatory)][string]$Password
    )
    # Store creds for auto-reconnect after reboot/login
    $qTarget = '"' + $Target + '"'
    $qUser   = '"' + $User + '"'
    $qPwd    = '"' + ($Password.Replace('"','\"')) + '"'
    cmd /c "cmdkey /add:$qTarget /user:$qUser /pass:$qPwd" > $null 2>&1
}

Write-Host ""
Write-Host "Vortex Drive Mapper (Fixed)" -ForegroundColor Cyan
Write-Host "Server: $Server" -ForegroundColor DarkCyan
Write-Host ""

# Gather credentials
$userInput = Read-Host "Username (e.g. jsmith OR $NetBIOSDomain\jsmith OR jsmith@domain)"
$user = Normalize-User -UserInput $userInput
$pwd  = Read-PlainPassword -Prompt "Password"

# Helpful to avoid error 1219 (multiple connections under different creds)
if ($ClearExistingConnectionsToServer) {
    cmd /c "net use \\$Server\* /delete /y" > $null 2>&1
}

# Save creds for the server so Windows can reconnect
Add-CmdKey -Target $Server -User $user -Password $pwd

# Map required drives
$failed = @()
foreach ($m in $DriveMaps) {
    $unc = "\\$Server\$($m.Share)"
    $ok = Map-Drive -Letter $m.Letter -UNC $unc -User $user -Password $pwd
    if (-not $ok) { $failed += $m.Letter }
}

# Map optional drives
foreach ($m in $OptionalDriveMaps) {
    $unc = "\\$Server\$($m.Share)"
    Map-Drive -Letter $m.Letter -UNC $unc -User $user -Password $pwd -Optional
}

Write-Host ""
if ($failed.Count -gt 0) {
    Write-Host "Done (with failures): $($failed -join ', ')" -ForegroundColor Red
    Write-Host "Tip: Run 'net use' to check existing connections and look for error 1219/5/53/67." -ForegroundColor DarkRed
    exit 1
} else {
    Write-Host "Done. All required drives mapped." -ForegroundColor Green
}
