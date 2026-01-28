@echo off
REM =====================================================================
REM Vortex Systems - Complete Setup
REM Login ONCE, setup EVERYTHING
REM =====================================================================

cls
echo.
echo ========================================
echo  VORTEX SYSTEMS - COMPLETE SETUP
echo ========================================
echo.
echo This will setup:
echo   - All network drives
echo   - All printers
echo.
echo You will login ONCE at the start.
echo.
pause

cls

REM Run the all-in-one setup script
if exist "%~dp0Setup-Everything.ps1" (
    powershell -ExecutionPolicy Bypass -File "%~dp0Setup-Everything.ps1"
) else (
    echo ERROR: Setup-Everything.ps1 not found!
    pause
    exit 1
)

REM Done
cls
echo.
echo ========================================
echo  SETUP COMPLETE
echo ========================================
echo.
echo Your computer is now configured with:
echo   - Network drives (U, O, R, Q, N, S, V, P)
echo   - Special shares (T, I) if you have access
echo   - All printers you have access to
echo.
echo IMPORTANT: Please REBOOT now!
echo.

set /p reboot="Reboot now? (Y/N): "
if /i "%reboot%"=="Y" (
    echo.
    echo Rebooting in 10 seconds...
    shutdown /r /t 10
) else (
    echo.
    echo Please reboot when convenient.
    pause
)
