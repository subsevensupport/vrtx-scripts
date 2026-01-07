================================================================
VORTEX SYSTEMS - Network Drive Mapper
Version 2.0
================================================================

QUICK START:
1. Copy all files to C:\scripts\
2. Right-click "Quick-Setup.bat" -> Run as administrator
3. Enter your username and password
4. Reboot when prompted
5. Done! Drives reconnect automatically.

================================================================
FILES:
================================================================

Mount-Network-Drives.ps1    - Main script
Mount-Drives.bat            - Menu launcher (4 options)
Quick-Setup.bat             - One-click setup (RECOMMENDED)
README.txt                  - This file

================================================================
WHAT IT DOES:
================================================================

Maps these drives:
  U: BUSINESS
  O: EMPLOYEE
  R: ENGINEERING RECORDS
  Q: ENGINEERING
  N: FINANCE-HR
  S: SOFTWARE
  V: VORTEX
  P: Personal folder (your EMPLOYEE$\username)

Special (if you have permission):
  T: Quotations
  I: Crib Catalog

Also:
  [OK] Fixes trust relationship
  [OK] Enables network wait at boot (no red X icons!)
  [OK] Stores credentials securely
  [OK] Auto-reconnect after reboot

================================================================
MENU OPTIONS:
================================================================

1. Map My Drives
   - Maps all accessible drives
   - Stores credentials
   - Configures persistence

2. Update Password
   - Updates stored password
   - Refreshes all drives
   - Use when password changes

3. Fix Connection Issues
   - Fixes trust relationship
   - Solves repeated password prompts
   - Requires reboot

4. Remove Everything
   - Removes all drives
   - Clears credentials
   - Complete cleanup

================================================================
NETWORK WAIT AT BOOT:
================================================================

When run as administrator, the script enables Windows to wait
for network before desktop loads. This means:

  [OK] No red X icons at startup
  [OK] Drives ready when desktop appears
  [OK] No 30-60 second delay

This is a registry setting, NOT a startup script.
No scripts run at boot - just a Windows configuration change.

================================================================
TROUBLESHOOTING:
================================================================

"Invalid credentials" error:
  -> Verify username (no domain, just username)
  -> Verify password
  -> Check VPN connection

Drives show red X at startup:
  -> Run Quick-Setup.bat as administrator
  -> Reboot

Password prompts keep appearing:
  -> Run Option 3 (Fix Connection Issues)
  -> Reboot

Special shares not mapping:
  -> Contact IT - you need AD group membership
  -> T: requires FS_SP_BUSS_0-Quotations_RW
  -> I: requires FS_SP_VTX_Crib-Catalog_RW

Drives don't reconnect after reboot:
  -> Verify you ran as administrator
  -> Reboot if you haven't
  -> Run Quick-Setup.bat again

================================================================
FOR IT STAFF:
================================================================

Deployment:
  1. Copy files to C:\scripts\ on each PC
  2. User runs Quick-Setup.bat as administrator
  3. User enters credentials
  4. System reboots
  5. Drives ready at next login

What gets configured:
  * Network drives with persistence
  * Credentials in Windows Credential Manager
  * Trust relationship (Local Intranet Zone)
  * Network wait at boot (RestoreConnection = 1)
  * Enhanced registry persistence

No startup components:
  * No scheduled tasks
  * No startup scripts
  * No services
  * Just registry settings

Server: VORTEXFS.hq.vortex-systems.com
Logs: C:\VortexLogs\

================================================================
SUPPORT:
================================================================

If problems persist:
  1. Check logs: C:\VortexLogs\DriveMapper_*.log
  2. Verify VPN/network connection
  3. Test: ping VORTEXFS.hq.vortex-systems.com
  4. Contact IT with computer name and log file

================================================================
