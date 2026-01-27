$Server = "VORTEXFS.hq.vortex-systems.com"

$Maps = @(
  @{ Letter="O:"; Share="EMPLOYEE$" },
  @{ Letter="R:"; Share="ENGINEERING RECORDS$" },
  @{ Letter="Q:"; Share="ENGINEERING$" },
  @{ Letter="N:"; Share="FINANCE-HR$" }
)

function Run($c){ cmd /c $c }

Write-Host ""
Write-Host "Vortex Drive Mapper (printer-auth style)" -ForegroundColor Cyan
Write-Host ""

# Prompt once (same as printer script)
$user = Read-Host "Username (DOMAIN\\user or user@domain)"
$sec  = Read-Host "Password" -AsSecureString
$pwd  = [Runtime.InteropServices.Marshal]::PtrToStringBSTR(
          [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
        )

# Remove only drive letters (NOT server sessions)
foreach ($m in $Maps) {
    Run "net use $($m.Letter) /delete /y" > $null 2>&1
}

# Authenticate once (this is what printers rely on)
Write-Host "Authenticating to \\$Server\IPC$ ..." -ForegroundColor Yellow
Run "net use \\$Server\IPC$ /user:`"$user`" `"$pwd`" /persistent:no"

# Map drives exactly like you would type manually
Write-Host ""
foreach ($m in $Maps) {
    $unc = "\\$Server\$($m.Share)"
    Write-Host "Mapping $($m.Letter) -> $unc"
    Run "net use $($m.Letter) `"$unc`" /persistent:yes"
}

Write-Host ""
Write-Host "Done. (Printer auth session preserved)" -ForegroundColor Green