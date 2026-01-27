<# 
Vortex Systems - Simple Drive Mapper (User)
- Prompts for credentials
- Stores them in Credential Manager (cmdkey)
- Maps standard drives; attempts optional drives (T/I) and skips if access denied
Run as the signed-in user (NOT as Administrator).
#>

$ErrorActionPreference = "Stop"

$Server = "VORTEXFS.hq.vortex-systems.com"
$NetBIOSDomain = "VORTEX-SYSTEMS"   # adjust if your NetBIOS name differs

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
    @{ Letter = "T:"; Share = "Quotations$" },     # <-- change to your real share name if different
    @{ Letter = "I:"; Share = "Crib Catalog$" }    # <-- change to your real share name if different
)

function Read-PlainPassword {
    param([string]$Prompt = "Password")
    $secure = Read-Host -AsSecureString -Prompt $Prompt
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try { [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}

function Normalize-User {
    param([string]$UserInput)
    if ($UserInput -match "\\") { return $UserInput } # already DOMAIN\user or user@domain
    return "$NetBIOSDomain\$UserInput"
}

function Exec-NetUse {
    param(
        [Parameter(Mandatory)] [string] $Letter,
        [Parameter(Mandatory)] [string] $UNC,
        [Parameter(Mandatory)] [string] $User,
        [Parameter(Mandatory)] [string] $Password
    )

    # Remove any existing mapping first (ignore errors)
    cmd /c "net use $Letter /delete /y" | Out-Null

    $quotedUNC = '"' + $UNC + '"'
    $quotedPwd = '"' + ($Password.Replace('"','\"')) + '"'
    $quotedUser = '"' + $User + '"'

    $cmdLine = "net use $Letter $quotedUNC /user:$quotedUser $quotedPwd /persistent:yes"
    $out = cmd /c $cmdLine 2>&1
    return $out
}

function Add-CmdKey {
    param(
        [Parameter(Mandatory)] [string] $Target,
        [Parameter(Mandatory)] [string] $User,
        [Parameter(Mandatory)] [string] $Password
    )
    # Store creds for auto-reconnect after reboot/login
    cmd /c ("cmdkey /add:`"$Target`" /user:`"$User`" /pass:`"$Password`"") | Out-Null
}

Write-Host "==============================="
Write-Host "Vortex Drive Mapper (Simple)"
Write-Host "Server: $Server"
Write-Host "==============================="
Write-Host ""

$userInput = Read-Host "Enter your username (just username, or DOMAIN\username)"
$userNorm  = Normalize-User $userInput
$passPlain = Read-PlainPassword "Enter your password"

# Store creds for the file server so drives persist after reboot
Add-CmdKey -Target $Server -User $userNorm -Password $passPlain

# Map standard drives
Write-Host ""
Write-Host "Mapping standard drives..."
foreach ($d in $DriveMaps) {
    $unc = "\\$Server\{0}" -f $d.Share
    try {
        $out = Exec-NetUse -Letter $d.Letter -UNC $unc -User $userNorm -Password $passPlain
        Write-Host ("[OK] {0} -> {1}" -f $d.Letter, $unc)
    } catch {
        Write-Host ("[SKIP] {0} -> {1}  ({2})" -f $d.Letter, $unc, $_.Exception.Message)
    }
}

# Personal folder (P:)
# Uses the entered username (without domain) when possible.
$shortUser = $userInput
if ($shortUser -match "\\") { $shortUser = $shortUser.Split("\")[-1] }
$personalUNC = "\\$Server\EMPLOYEE$\" + $shortUser

Write-Host ""
Write-Host "Mapping personal drive..."
try {
    $out = Exec-NetUse -Letter "P:" -UNC $personalUNC -User $userNorm -Password $passPlain
    Write-Host ("[OK] P: -> {0}" -f $personalUNC)
} catch {
    Write-Host ("[SKIP] P: -> {0}  ({1})" -f $personalUNC, $_.Exception.Message)
}

# Optional drives
Write-Host ""
Write-Host "Attempting optional drives (if authorized)..."
foreach ($d in $OptionalDriveMaps) {
    $unc = "\\$Server\{0}" -f $d.Share
    try {
        $out = Exec-NetUse -Letter $d.Letter -UNC $unc -User $userNorm -Password $passPlain
        Write-Host ("[OK] {0} -> {1}" -f $d.Letter, $unc)
    } catch {
        Write-Host ("[SKIP] {0} -> {1}" -f $d.Letter, $unc)
    }
}

Write-Host ""
Write-Host "Done. Open File Explorer -> This PC to verify."
Write-Host "If drives don't show, reboot once (credentials are saved for $Server)."
