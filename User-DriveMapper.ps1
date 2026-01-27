<#
Vortex Systems - Simple Drive Mapper (Prompt once, reuse creds) - FIX
Goal:
- User is NOT the same as the currently logged-in Windows user
- Prompt ONCE for username/password (like your printer script)
- Store creds for the file server in Credential Manager (cmdkey)
- Map all drives WITHOUT re-supplying creds (no second prompt)
- No asking for share names; shares/letters are hard-coded below

Run this as the signed-in Windows user (not elevated unless you have a reason).
#>

$ErrorActionPreference = "Stop"

# ====== EDIT THESE IF NEEDED ======
$Server        = "VORTEXFS.hq.vortex-systems.com"
$NetBIOSDomain = "VORTEX-SYSTEMS"   # adjust if your NetBIOS name differs
$ClearExistingConnectionsToServer = $true  # helps avoid NET USE error 1219
# =================================

# Drive definitions (edit share names/letters here only if you want to)
$DriveMaps = @(
    @{ Letter = "U:"; Share = "BUSINESS$" },
    @{ Letter = "O:"; Share = "EMPLOYEE$" },
    @{ Letter = "R:"; Share = "ENGINEERING RECORDS$" },  # space is OK
    @{ Letter = "Q:"; Share = "ENGINEERING$" },
    @{ Letter = "N:"; Share = "FINANCE-HR$" },
    @{ Letter = "S:"; Share = "SOFTWARE$" },
    @{ Letter = "V:"; Share = "VORTEX$" }
)

# Optional drives (attempt; OK to fail)
$OptionalDriveMaps = @(
    @{ Letter = "T:"; Share = "Quotations$" },
    @{ Letter = "I:"; Share = "Crib Catalog$" }
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
    if ($UserInput -match '\\' -or $UserInput -match '@') { return $UserInput }
    return "$NetBIOSDomain\$UserInput"
}

function Remove-DriveQuiet {
    param([Parameter(Mandatory)][string]$Letter)
    cmd /c "net use $Letter /delete /y" > $null 2>&1
}

function Add-CmdKey {
    param(
        [Parameter(Mandatory)][string]$Target,
        [Parameter(Mandatory)][string]$User,
        [Parameter(Mandatory)][string]$Password
    )
    $qTarget = '"' + $Target + '"'
    $qUser   = '"' + $User + '"'
    $qPwd    = '"' + ($Password.Replace('"','\"')) + '"'
    cmd /c "cmdkey /add:$qTarget /user:$qUser /pass:$qPwd" > $null 2>&1
}

function Map-Drive {
    param(
        [Parameter(Mandatory)][string]$Letter,
        [Parameter(Mandatory)][string]$UNC,
        [switch]$Optional
    )

    Remove-DriveQuiet -Letter $Letter

    # Quote UNC to support spaces in share names
    $qUNC = '"' + $UNC + '"'

    # IMPORTANT: Do NOT pass /user or password here.
    # We rely on cmdkey stored credentials so it won't prompt again.
    $out = cmd /c "net use $Letter $qUNC /persistent:yes" 2>&1
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

Write-Host ""
Write-Host "Vortex Drive Mapper (Prompt once, reuse creds)" -ForegroundColor Cyan
Write-Host "Server: $Server" -ForegroundColor DarkCyan
Write-Host ""

# Gather credentials ONCE
$userInput = Read-Host "Username (e.g. jsmith OR $NetBIOSDomain\jsmith OR jsmith@domain)"
$user = Normalize-User -UserInput $userInput
$pwd  = Read-PlainPassword -Prompt "Password"

# Use both FQDN + short name targets (prevents “second prompt” when apps hit \VORTEXFS vs \VORTEXFS.hq...)
$ServerShort = ($Server -split '\.')[0]

# Clear any existing sessions first (prevents error 1219 and stale creds)
if ($ClearExistingConnectionsToServer) {
    cmd /c "net use \\$Server\* /delete /y" > $null 2>&1
    cmd /c "net use \\$ServerShort\* /delete /y" > $null 2>&1
}

# Store creds for both names so whichever one Windows uses, it won't prompt again
Add-CmdKey -Target $Server -User $user -Password $pwd
Add-CmdKey -Target $ServerShort -User $user -Password $pwd

# Map required drives
$failed = @()
foreach ($m in $DriveMaps) {
    $unc = "\\$Server\$($m.Share)"
    $ok = Map-Drive -Letter $m.Letter -UNC $unc
    if (-not $ok) { $failed += $m.Letter }
}

# Map optional drives
foreach ($m in $OptionalDriveMaps) {
    $unc = "\\$Server\$($m.Share)"
    Map-Drive -Letter $m.Letter -UNC $unc -Optional
}

Write-Host ""
if ($failed.Count -gt 0) {
    Write-Host "Done (with failures): $($failed -join ', ')" -ForegroundColor Red
    Write-Host "Tip: Run 'net use' to inspect sessions; 1219 means conflicting creds to the same server." -ForegroundColor DarkRed
    exit 1
} else {
    Write-Host "Done. All required drives mapped." -ForegroundColor Green
}
