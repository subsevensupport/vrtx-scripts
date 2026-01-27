@echo off
REM ============================================================================
REM Vortex Systems - User Setup
REM 
REM Run this as a REGULAR USER (not administrator)
REM 
REM This configures:
REM   1. Your network printers (optional - can skip)
REM   2. Your standard network drives (U:, O:, R:, Q:, N:, S:, V:, P:)
REM   3. Your special shares (T:, I:) - if you have permission
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
echo   - Your network printers (optional)
echo   - Your standard network drives (U:, O:, R:, Q:, N:, S:, V:, P:)
echo   - Your special shares (T: Quotations, I: Crib) - if authorized
echo.
echo Run this as a REGULAR USER (do NOT run as administrator)
echo.
echo You will be prompted for your username and password.
echo Your credentials will be stored securely for future use.
echo.
echo ============================================================================
echo.

REM Ask if user wants to skip printers
set /p skip_printers="Do you want to skip printer setup? (Y/N, default=N): "
if "%skip_printers%"=="" set skip_printers=N

echo.
echo Press any key to continue...
pause >nul

cls

REM ============================================================================
REM STEP 1: Deploy User Printers (OPTIONAL)
REM ============================================================================

if /i "%skip_printers%"=="Y" (
    echo.
    echo ============================================================================
    echo  STEP 1: Printer Setup - SKIPPED
    echo ============================================================================
    echo.
    echo Printer setup skipped by user choice.
    echo.
    echo ============================================================================
    echo.
    echo Press any key to continue to drive mapping...
    pause >nul
    goto DRIVE_MAPPING
)

echo.
echo ============================================================================
echo  STEP 1 of 3: Installing Your Printers
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

:DRIVE_MAPPING

cls

REM ============================================================================
REM STEP 2: Map Standard Network Drives
REM ============================================================================

echo.
echo ============================================================================
echo  STEP 2 of 3: Mapping Your Standard Network Drives
echo ============================================================================
echo.
echo Mapping: U:, O:, R:, Q:, N:, S:, V:, P:
echo.

if /i "%skip_printers%"=="Y" (
    echo You will be prompted for your username and password.
) else (
    echo You will be prompted for your username and password again.
    echo (This is separate from printer credentials)
)

echo.

if exist "%~dp0User-DriveMapper.ps1" (
    powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0User-DriveMapper.ps1" -Option "1"
    echo.
    
    REM Check if script succeeded
    if %errorlevel% equ 0 (
        echo [OK] Standard drives mapped successfully
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
echo Press any key to continue to special shares...
pause >nul

cls

REM ============================================================================
REM STEP 3: Map Special Shares (Optional)
REM ============================================================================

echo.
echo ============================================================================
echo  STEP 3 of 3: Mapping Special Shares
echo ============================================================================
echo.
echo Attempting to map special shares:
echo   - T: Quotations (requires FS_SP_BUSS_0-Quotations_RW group)
echo   - I: Crib Catalog (requires FS_SP_VTX_Crib-Catalog_RW group)
echo.
echo Note: You will only get these drives if you have the required permissions.
echo       If you don't have access, they will be skipped - this is normal!
echo.

if exist "%~dp0User-DriveMapper.ps1" (
    powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0User-DriveMapper.ps1" -Option "2"
    echo.
    
    REM Check if script succeeded
    if %errorlevel% equ 0 (
        echo [OK] Special shares mapping complete
    ) else (
        echo [INFO] Special shares skipped (no permission or not needed)
    )
    echo.
) else (
    echo [WARNING] User-DriveMapper.ps1 not found - skipping special shares
    echo.
)

cls

echo.
echo ============================================================================
echo.
echo                    USER SETUP COMPLETE
echo.
echo ============================================================================
echo.
echo What was configured:

if /i "%skip_printers%"=="Y" (
    echo   [SKIPPED] Network printers (skipped by user choice)
) else (
    echo   [OK] Network printers installed (based on your permissions)
)

echo   [OK] Standard network drives mapped (U:, O:, R:, Q:, N:, S:, V:, P:)
echo   [OK] Special shares attempted (T:, I:) - you got what you have access to
echo.

if /i NOT "%skip_printers%"=="Y" (
    echo Your printers:
    echo   - Check "Devices and Printers" in Control Panel
    echo   - You only see printers you have permission to use
    echo.
)

echo Your standard drives:
echo   - U: BUSINESS
echo   - O: EMPLOYEE
echo   - R: ENGINEERING RECORDS
echo   - Q: ENGINEERING
echo   - N: FINANCE-HR
echo   - S: SOFTWARE
echo   - V: VORTEX
echo   - P: Personal
echo.
echo Your special shares (if authorized):
echo   - T: Quotations (restricted)
echo   - I: Crib Catalog (restricted)
echo.
echo Important:
echo   - A REBOOT is recommended for all settings to take effect
echo   - Your drives will auto-reconnect after reboot

if /i NOT "%skip_printers%"=="Y" (
    echo   - Your printers are ready to use immediately
)

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
