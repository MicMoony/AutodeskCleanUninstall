# AutodeskCleanUninstall.ps1

Don’t you sometimes dream of a real fresh start?

This PowerShell script automates the Autodesk clean uninstall process. It follows the official Autodesk guidelines to remove applications, components, residual files, and registry entries, ensuring a clean environment for reinstallation.

You can find the official Autodesk documentation [here](https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Clean-uninstall.html).

## Features
- Uninstalls Autodesk applications and components.
- Built-in safeguard to prevent unintended removals.
- Removes residual files and folders.
- Cleans related registry entries.
- Generates a detailed log file of the uninstall process.
- Provides a foundation for clean reinstallation.

## Requirements
- Windows 10 or 11
- PowerShell 5.1 or higher
- Administrative privileges

## Usage
1. Open PowerShell as Administrator.
> [!IMPORTANT]
> In most environments, script execution is not permitted by default. Therefore, run this command first:
> ```powershell
> Set-ExecutionPolicy Bypass -Scope Process -Force
3. Navigate to the folder containing `AutodeskCleanUninstall.ps1`, e.g. your Downloads folder.
   ```powershell
   cd C:\Users\<userprofile>\Downloads
5. Execute the script:
   ```powershell
   .\AutodeskCleanUninstall.ps1
6. If Autodesk software is found, it will be displayed in a structured list. Press 'Y' to continue with the uninstallation.
7. After completion, a detailed record of all actions can be found in the log file.

## Notes
- Log files are generated in `C:\Temp\Logs` and follow the naming convention: `AutodeskCleanUninstall_YYYYMMDD_HHMMSS.log`.
- Most folders and registry keys are automatically removed by the script. If some items remain because of insufficient permissions or custom installation paths, refer to the [Manual Steps](#manual-steps) section.

## Manual Steps
Some steps cannot be fully automated and may require user intervention:

- Run the Microsoft Program Install and Uninstall Troubleshooter to remove any residual Autodesk software: https://aka.ms/Program_Install_and_Uninstall

## Disclaimer
This script is provided "as-is" without warranty of any kind. Use at your own risk.
Ensure you have backups of important data before running the script. It removes software and registry entries and may affect your system if used incorrectly.
