<# 
User-DriveMapper (SSO version)
- Maps drives using the CURRENT logged-in user's domain credentials (Kerberos/SSO)
- No prompts, no cmdkey, no net use password arguments
- Uses New-PSDrive -Persist for reliable mappings (including shares with spaces)
- IMPORTANT: Use ONE consistent server name everywhere (prefer short name, not FQDN)

Run as the logged-in user (not elevated unless you have a reason).
#>

[CmdletBinding()]
param(
    [string]$Server = "VORTEXFS",
    [switch]$ResetConnections
)

$ErrorActionPreference = "Stop"

function Write-Ok($msg){ Write-Host "[OK]  $msg" -ForegroundColor Green }
function Write-Warn($msg){ Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Fail($msg){ Write-Host "[FAIL] $msg" -ForegroundColor Red }

function Remove-Drive($Letter) {
    # Remove existing PSDrive mapping if present
    try {
        if (Get-PSDrive -Name $Letter.TrimEnd(':') -ErrorAction SilentlyContinue) {
            Remove-PSDrive -Name $Letter.TrimEnd(':') -Force -ErrorAction SilentlyContinue
        }
    } catch {}

    # Also remove any existing net use mapping quietly
    cmd /c "net use $Letter /delete /y" >$null 2>&1
}

function Map-Drive($Letter, $UNC) {
    Remove-Drive $Letter

    try {
        New-PSDrive -Name $Letter.TrimEnd(':') -PSProvider FileSystem -Root $UNC -Persist -Scope Global | Out-Null
        Write-Ok "$Letter -> $UNC"
        return $true
    } catch {
        Write-Fail "$Letter -> $UNC"
        Write-Warn $_.Exception.Message
        return $false
    }
}

# Optional: clear existing SMB connections to this server (fixes “multiple connections” / error 1219)
if ($ResetConnections) {
    Write-Warn "ResetConnections enabled: clearing existing SMB connections to \\$Server\*"
    cmd /c "net use \\$Server\* /delete /y" >$null 2>&1
}

# Build UNC roots (keep server name consistent!)
$O = "\\$Server\EMPLOYEE$"
$P = "\\$Server\EMPLOYEE$\$env:USERNAME"
$R = "\\$Server\ENGINEERING RECORDS$"
$Q = "\\$Server\ENGINEERING$"
$N = "\\$Server\FINANCE-HR$"

Write-Host ""
Write-Host "Mapping drives using SSO against \\$Server ..." -ForegroundColor Cyan
Write-Host ""

# Drive mappings (edit letters/paths here if you want)
Map-Drive "O:" $O | Out-Null
Map-Drive "P:" $P | Out-Null
Map-Drive "R:" $R | Out-Null
Map-Drive "Q:" $Q | Out-Null
Map-Drive "N:" $N | Out-Null

Write-Host ""
Write-Ok "Done. If any drive shows [FAIL], try: .\User-DriveMapper_SSO.ps1 -ResetConnections"
