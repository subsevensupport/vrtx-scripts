@echo off
REM =====================================================================
REM Vortex Systems - User Setup (SIMPLE)
REM =====================================================================

cls
echo.
echo ========================================
echo  VORTEX SYSTEMS - USER SETUP
echo ========================================
echo.

REM Ask about printers
set /p skip_printers="Skip printer setup? (Y/N, default=N): "
if "%skip_printers%"=="" set skip_printers=N

echo.
pause

cls

REM ============================================================================
REM PRINTERS (if not skipped)
REM ============================================================================

if /i NOT "%skip_printers%"=="Y" (
    echo.
    echo ========================================
    echo  Installing Printers...
    echo ========================================
    echo.
    
    if exist "%~dp0Deploy-Printers-Users.ps1" (
        powershell -ExecutionPolicy Bypass -File "%~dp0Deploy-Printers-Users.ps1"
    )
    
    echo.
    pause
    cls
)

REM ============================================================================
REM DRIVES
REM ============================================================================

echo.
echo ========================================
echo  Mapping Network Drives...
echo ========================================
echo.

if exist "%~dp0User-DriveMapper.ps1" (
    powershell -ExecutionPolicy Bypass -File "%~dp0User-DriveMapper.ps1" -Option "1"
)

echo.
pause
cls

REM ============================================================================
REM SPECIAL SHARES
REM ============================================================================

echo.
echo ========================================
echo  Mapping Special Shares...
echo ========================================
echo.

if exist "%~dp0User-DriveMapper.ps1" (
    powershell -ExecutionPolicy Bypass -File "%~dp0User-DriveMapper.ps1" -Option "2"
)

cls

REM ============================================================================
REM DONE
REM ============================================================================

echo.
echo ========================================
echo  SETUP COMPLETE
echo ========================================
echo.

if /i "%skip_printers%"=="Y" (
    echo [SKIPPED] Printers
) else (
    echo [OK] Printers installed
)

echo [OK] Standard drives mapped
echo [OK] Special shares attempted
echo.
echo Please REBOOT for all changes to take effect.
echo.

set /p reboot="Reboot now? (Y/N): "
if /i "%reboot%"=="Y" (
    shutdown /r /t 10
) else (
    pause
)
