# AutodeskCleanUninstall.ps1

This is a PowerShell script that automates the Autodesk clean uninstall process. It follows the official Autodesk guidelines to remove applications, components, residual files, and registry entries, ensuring a clean environment for reinstallation.

Official Autodesk documentation: [Clean Uninstall](https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Clean-uninstall.html)

## Features
- Uninstalls Autodesk applications and components.
- Removes residual files and folders.
- Cleans related registry entries.
- Requires minimal manual intervention.
- Provides a foundation for clean reinstallation.

## Requirements
- Windows 10 or 11
- PowerShell 5.1 or higher
- Administrative privileges

## Usage
1. Open PowerShell as Administrator.
2. Navigate to the folder containing `AutodeskCleanUninstall.ps1`.
3. Execute the script:
   ```powershell
   .\AutodeskCleanUninstall.ps1
4. Follow any on-screen prompts if required.

## License
This script is provided "as-is" without warranty of any kind. Use at your own risk. You may use, modify, and distribute it freely.

## Disclaimer
Ensure you have backups of important data before running the script. This script removes software and registry entries and may affect your system if used incorrectly.
