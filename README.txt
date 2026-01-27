================================================================
VORTEX SYSTEMS - User Setup Package
Network Drives + Printers
================================================================

One liner:

irm https://raw.githubusercontent.com/subsevensupport/vrtx-scripts/main/install.ps1 | iex

This will:
  1. Download all files to C:\scripts\
  2. Automatically run 2-User-Setup.bat
  3. Prompt you for credentials
  4. Configure everything



QUICK START:
1. Run "2-User-Setup.bat" (as regular user, NOT administrator)
2. Enter your username and password when prompted
3. Follow the prompts
4. Reboot when asked
5. Done! Your printers and drives are ready.

================================================================
WHAT THIS PACKAGE DOES:
================================================================

PART 1: Installs Your Printers
  - SHOP-PRNT (if authorized)
  - SHOP-CLR-PRNT (if authorized)
  - MGNT-PRNT (if authorized)
  - LOBBY-PRNT (if authorized)
  - Canon-TM-305 Plotter (if authorized)

PART 2: Maps Your Network Drives
  - U: BUSINESS
  - O: EMPLOYEE
  - R: ENGINEERING RECORDS
  - Q: ENGINEERING
  - N: FINANCE-HR
  - S: SOFTWARE
  - V: VORTEX
  - P: Personal folder (your EMPLOYEE$\username)
  - T: Quotations (if authorized)
  - I: Crib Catalog (if authorized)

Also:
  [OK] Stores your credentials securely
  [OK] Configures auto-reconnect for drives
  [OK] Prompts for reboot

================================================================
FILES INCLUDED:
================================================================

2-User-Setup.bat
  - Main launcher (double-click this!)
  - Runs as regular user
  - Guides you through setup

User-DriveMapper.ps1
  - Drive mapping script
  - Called automatically by 2-User-Setup.bat

Deploy-Printers-Users.ps1
  - Printer deployment script
  - Called automatically by 2-User-Setup.bat

README.txt
  - This file

install.ps1
  - GitHub installer (if downloading from GitHub)

================================================================
IMPORTANT NOTES:
================================================================

Run as REGULAR USER:
  - Do NOT run as administrator
  - Just double-click 2-User-Setup.bat
  - You'll be prompted for credentials

Credentials Required:
  - You'll enter username and password TWICE
  - Once for printers
  - Once for drives
  - Same credentials both times (your domain account)
  - Format: Just "username" (no VORTEX-SYSTEMS\ prefix)

Prerequisites:
  - IT must have run admin setup on this PC first
  - PC must be on network or VPN
  - You need valid domain credentials

Reboot Required:
  - Printers work immediately
  - Drives work after reboot
  - Drives will auto-reconnect at every login

================================================================
WHAT HAPPENS DURING SETUP:
================================================================

Step 1: Printer Installation
  1. Prompts for username
  2. Prompts for password
  3. Stores credentials securely
  4. Attempts to install all printers
  5. You get only printers you're authorized for
  6. Press any key to continue

Step 2: Drive Mapping
  1. Prompts for username again
  2. Prompts for password again
  3. Tests your credentials
  4. Maps accessible drives
  5. Configures auto-reconnect
  6. Asks if you want to reboot

Step 3: Reboot
  1. Choose to reboot now or later
  2. After reboot, drives reconnect automatically
  3. Done!

Takes 2-3 minutes total.

================================================================
TROUBLESHOOTING:
================================================================

"Invalid credentials" error:
  -> Enter username WITHOUT domain prefix
  -> Just "username", not "VORTEX-SYSTEMS\username"
  -> Check password is correct
  -> Verify account is not locked

"Cannot reach server" error:
  -> Check VPN connection
  -> Verify you're on corporate network
  -> Test: ping VORTEXFS.hq.vortex-systems.com

"Some printers skipped" message:
  -> This is NORMAL
  -> You only get printers you're authorized for
  -> Contact IT to request access to additional printers

"Some drives skipped" message:
  -> This is NORMAL
  -> You only get drives you're authorized for
  -> Most users get U:, O:, R:, Q:, N:, S:, V:, P:
  -> Special drives T: and I: require additional authorization

"Script won't run" error:
  -> Make sure you're NOT running as administrator
  -> Run as regular user
  -> Right-click should show "Run as administrator" option
  -> Just double-click normally instead

Drives don't reconnect after reboot:
  -> Verify IT ran admin setup first
  -> Check that you rebooted after setup
  -> Re-run 2-User-Setup.bat if needed

Need to update password:
  -> Just run 2-User-Setup.bat again
  -> Enter new password when prompted
  -> It will update stored credentials

================================================================
PRINTER PERMISSIONS:
================================================================

Your printers are determined by AD group membership:

Shop Printers:
  - PRNT_SP_SHOP-PRNT_PO -> SHOP-PRNT
  - PRNT_SP_SHOP-CLR-PRNT_PO -> SHOP-CLR-PRNT

Office Printers:
  - PRNT_SP_MGNT-PRNT_PO -> MGNT-PRNT
  - PRNT_SP_LOBBY-PRNT_PO -> LOBBY-PRNT

Engineering:
  - PRNT_PLOTTER_PO -> Canon-TM-305

IT Admin:
  - PRNT_ALL-PRNT_FC -> All printers

Contact IT to request access to additional printers.

================================================================
DRIVE PERMISSIONS:
================================================================

Standard Drives (Everyone):
  U:, O:, R:, Q:, N:, S:, V:, P:

Special Drives (Require Authorization):
  T: Quotations
     Requires: FS_SP_BUSS_0-Quotations_RW
     
  I: Crib Catalog
     Requires: FS_SP_VTX_Crib-Catalog_RW

Contact IT to request access to special drives.

================================================================
MULTI-USER PC:
================================================================

If multiple people use this PC:
  - Each user runs 2-User-Setup.bat separately
  - Each user enters their own credentials
  - Each user gets their own printers and drives
  - Users don't interfere with each other

Example:
  User 1 logs in -> Runs setup -> Gets their printers/drives
  User 2 logs in -> Runs setup -> Gets their printers/drives
  Both configurations work independently!

================================================================
RUNNING FROM GITHUB:
================================================================

If downloading from GitHub, use this one-liner:

irm https://raw.githubusercontent.com/USERNAME/REPO/main/install.ps1 | iex

This will:
  1. Download all files to C:\scripts\
  2. Automatically run 2-User-Setup.bat
  3. Prompt you for credentials
  4. Configure everything

Replace USERNAME and REPO with actual GitHub details.

================================================================
LOGS AND VERIFICATION:
================================================================

After Setup:
  - Check printers: Control Panel -> Devices and Printers
  - Check drives: File Explorer -> This PC
  - Check logs: C:\VortexLogs\DriveMapper_*.log

Verify Printers:
  - Open "Devices and Printers"
  - Look for: SHOP-PRNT, MGNT-PRNT, etc.
  - You only see printers you have access to

Verify Drives:
  - Open File Explorer
  - Look in "This PC" or "Computer"
  - Should see: U:, O:, R:, Q:, N:, S:, V:, P:
  - May also see: T:, I: (if authorized)

Verify Auto-Reconnect:
  - Reboot your PC
  - After login, check File Explorer
  - Drives should be there (no red X)
  - If drives aren't there, check logs

================================================================
UPDATING LATER:
================================================================

Password Changed:
  - Run 2-User-Setup.bat again
  - Enter new password
  - It will update stored credentials

Lost Access to Printer/Drive:
  - Run 2-User-Setup.bat again
  - It will remove unauthorized items

Gained Access to New Printer/Drive:
  - Log out and log back in (to refresh groups)
  - Run 2-User-Setup.bat again
  - New items will be added

PC Reimaged:
  - Run 2-User-Setup.bat again
  - Enter credentials
  - Everything will be reconfigured

================================================================
SUPPORT:
================================================================

For Access Requests:
  - Contact IT to request printer/drive access
  - Provide: Your username, what you need access to

For Technical Issues:
  - Check this README first
  - Check logs: C:\VortexLogs\DriveMapper_*.log
  - Contact IT with:
    * Your username
    * Computer name
    * Error message
    * Log file

IT Contact:
  martin@vortex-systems.com

================================================================
SECURITY:
================================================================

Your credentials are stored securely:
  - Windows Credential Manager (encrypted)
  - Per-user (other users can't access)
  - Same security as Windows password storage

What's stored:
  - Your username
  - Your password (encrypted)

What's NOT stored:
  - No credentials in plain text
  - No credentials in scripts
  - No shared credentials between users

Your data is protected by:
  - Windows DPAPI encryption
  - Per-user credential isolation
  - Server-side permission enforcement

================================================================
VERSION:
================================================================

Package: User Setup (Printers + Drives)
Version: 2.0
Updated: December 2024

For the latest version, check with IT or download from GitHub.

================================================================
END OF README
================================================================
