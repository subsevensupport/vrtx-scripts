@echo off
REM ============================================================================
REM Vortex Systems - User Setup
REM 
REM Run this as a REGULAR USER (not administrator)
REM 
REM This configures:
REM   1. Your network printers
REM   2. Your network drives (U:, O:, R:, Q:, N:, S:, V:, P:, T:, I:)
REM
REM Prerequisites: IT must have run "1-Admin-Setup.bat" first
REM ============================================================================

cls
echo.
echo ============================================================================
echo  VORTEX SYSTEMS - USER SETUP
echo ============================================================================
echo.
echo This script will configure:
echo   - Your network printers (based on your permissions)
echo   - Your network drives (based on your permissions)
echo.
echo Run this as a REGULAR USER (do NOT run as administrator)
echo.
echo You will be prompted for your username and password.
echo Your credentials will be stored securely for future use.
echo.
echo ============================================================================
echo.
echo Press any key to continue...
pause >nul

cls

REM ============================================================================
REM STEP 1: Deploy User Printers
REM ============================================================================

echo.
echo ============================================================================
echo  STEP 1 of 2: Installing Your Printers
echo ============================================================================
echo.
echo You will be prompted for your domain username and password.
echo.

if exist "%~dp0Deploy-Printers-Users.ps1" (
    powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0Deploy-Printers-Users.ps1"
    echo.
    
    REM Check if script succeeded
    if %errorlevel% equ 0 (
        echo [OK] Printer installation complete
    ) else (
        echo [WARNING] Some printers may not have installed
        echo          This is normal if you don't have permission to all printers
    )
    echo.
) else (
    echo [WARNING] Deploy-Printers-Users.ps1 not found - skipping printer setup
    echo.
)

echo ============================================================================
echo.
echo Press any key to continue to drive mapping...
pause >nul

cls

REM ============================================================================
REM STEP 2: Map Network Drives
REM ============================================================================

echo.
echo ============================================================================
echo  STEP 2 of 2: Mapping Your Network Drives
echo ============================================================================
echo.
echo You will be prompted for your username and password again.
echo (This is separate from printer credentials)
echo.

if exist "%~dp0User-DriveMapper.ps1" (
    powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0User-DriveMapper.ps1" -Option "1"
    echo.
    
    REM Check if script succeeded
    if %errorlevel% equ 0 (
        echo [OK] Drive mapping complete
    ) else (
        echo [WARNING] Some drives may not have mapped
        echo          Check your credentials and network connection
    )
    echo.
) else (
    echo [WARNING] User-DriveMapper.ps1 not found - skipping drive mapping
    echo.
)

echo ============================================================================
echo.
echo                    USER SETUP COMPLETE
echo.
echo ============================================================================
echo.
echo What was configured:
echo   [OK] Network printers installed (based on your permissions)
echo   [OK] Network drives mapped (based on your permissions)
echo.
echo Your printers:
echo   - Check "Devices and Printers" in Control Panel
echo   - You only see printers you have permission to use
echo.
echo Your drives:
echo   - Check File Explorer for mapped drives
echo   - Common drives: U:, O:, R:, Q:, N:, S:, V:, P:
echo   - Special drives (if authorized): T:, I:
echo.
echo Important:
echo   - A REBOOT is recommended for all settings to take effect
echo   - Your drives will auto-reconnect after reboot
echo   - Your printers are ready to use immediately
echo.
echo ============================================================================
echo.

set /p reboot="Would you like to reboot now? (Y/N): "
if /i "%reboot%"=="Y" (
    echo.
    echo Rebooting in 10 seconds...
    echo Press Ctrl+C to cancel
    shutdown /r /t 10 /c "Applying Vortex Systems configuration"
) else (
    echo.
    echo Please reboot when convenient for best results.
    echo.
    pause
)
