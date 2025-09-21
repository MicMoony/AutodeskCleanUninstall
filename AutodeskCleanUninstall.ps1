<#
-----------------------------------------------------------------------------
Script Name:  AutodeskCleanUninstall.ps1
Author:       MicMoony
Version:      1.0
Created:      2025-02-21
License:      MIT License — https://opensource.org/licenses/MIT

Description:  Automates the Autodesk clean uninstall process based on the 
              official Autodesk documentation:
              https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Clean-uninstall.html

              The script removes Autodesk applications, components, residual 
              files, and registry entries to ensure a clean environment for 
              reinstallation.

Usage:        1. Open PowerShell as Administrator.
              2. Navigate to the folder containing AutodeskCleanUninstall.ps1.
              3. Run the script:
                 .\AutodeskCleanUninstall.ps1
              4. Follow on-screen prompts for confirmations if required.
              5. After completion, review the generated log file.

Requirements: Must be run with administrative privileges.

Disclaimer:   This script is provided "as-is" without warranty of any kind. 
              Use at your own risk. Ensure you have backups of important data before running 
              this script. It removes software and registry entries and may 
              affect your system if used incorrectly.

Notes:        The script generates a log file in the following folder:
              C:\Temp\Logs\AutodeskCleanUninstall_YYYYMMDD_HHMMSS.log
-----------------------------------------------------------------------------
#>

# Function to write text wrapped to the terminal's width without breaking words
function Write-HostWrapped {
    param (
        [string]$text,
        [ConsoleColor]$ForegroundColor = "White"
    )

    # Get the current terminal width
    $width = [System.Console]::WindowWidth

    # Split the text into words
    $words = $text.Split(' ')

    # Initialize an empty line
    $line = ""

    foreach ($word in $words) {
        # If adding this word exceeds the line width, print the current line and start a new one
        if (($line.Length + $word.Length + 1) -gt $width) {
            Write-Host $line
            $line = $word
        } else {
            # Add the word to the line
            if ($line.Length -eq 0) {
                $line = $word
            } else {
                $line += " " + $word
            }
        }
    }

    # Print any remaining text in the last line
    if ($line.Length -gt 0) {
        Write-Host $line -ForegroundColor $ForegroundColor
    }
}

# Check if the log folder exists and create it if not
$logFolder = "C:\Temp\Logs"

if (-Not (Test-Path $logFolder)) {
    New-Item -ItemType Directory -Path $logFolder -Force > $null
}

# Define log file name with timestamp
$logFile = "$logFolder\AutodeskCleanUninstall_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Function to write messages to the log file and console
function Write-Log {
    param ([string]$message)
    
    # Create the timestamp
    $timestamp = $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    
    # Format the log message for the log file (with timestamp)
    $logMessage = "[$timestamp] $message"
    
    # Write to log file (with timestamp)
    $logMessage | Out-File -Append -FilePath $logFile
    
    # Write to console (without timestamp)
    Write-Host $message
}

# Detect the currently logged-in user
$loggedInUser = (Get-WmiObject Win32_ComputerSystem | Select-Object -ExpandProperty UserName) -replace "^.+\\", ""

Write-Host "Detected logged-in user: $loggedInUser"

# Define user-specific paths
$localAppDataPath = "C:\Users\$loggedInUser\AppData\Local\Autodesk"
$appDataPath = "C:\Users\$loggedInUser\AppData\Roaming\Autodesk"
$tempPath = "C:\Users\$loggedInUser\AppData\Local\Temp"
$hkcuRegistryPath = "Registry::HKEY_USERS\$((Get-WmiObject Win32_UserAccount | Where-Object { $_.Name -eq $loggedInUser }).SID)\SOFTWARE\Autodesk"

# Step 1: Look for Uninstall Tool
Write-Host "Checking for Autodesk Uninstall Tool..."

$uninstallToolPath = $null

# Search common locations
$commonPaths = @(
    "C:\Program Files\Autodesk\UninstallTool\UninstallTool.exe",
    "C:\Program Files (x86)\Autodesk\UninstallTool\UninstallTool.exe"
)

foreach ($path in $commonPaths) {
    if (Test-Path $path) {
        $uninstallToolPath = $path
        break
    }
}

# Search registry for Autodesk-related uninstall tools
if (-not $uninstallToolPath) {
    $registryPaths = @(
        "HKLM:\SOFTWARE\Autodesk",
        "HKLM:\SOFTWARE\WOW6432Node\Autodesk"
    )

    foreach ($regPath in $registryPaths) {
        if (Test-Path $regPath) {
            $uninstallToolReg = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
            if ($uninstallToolReg -and ($uninstallToolReg.PSObject.Properties.Name -contains "InstallLocation")) {
                $potentialPath = Join-Path -Path $uninstallToolReg.InstallLocation -ChildPath "UninstallTool\UninstallTool.exe"
                if (Test-Path $potentialPath) {
                    $uninstallToolPath = $potentialPath
                    break
                }
            }
        }
    }
}

Write-Host ""

# Step 2: Open Uninstall Tool and Uninstall Autodesk Software
if ($uninstallToolPath) {
    Write-Host "Autodesk Uninstall Tool found at: $uninstallToolPath"
    Write-Host "Launching Autodesk Uninstall Tool..."
    Start-Process -FilePath $uninstallToolPath -Wait
    Write-Host "Autodesk Uninstall Tool process completed." -ForegroundColor Green
} else {
    Write-HostWrapped "Skipping step 2 because this tool is only available for Autodesk software that does not use the new installation experience." -ForegroundColor Yellow
}

Write-Host ""

# Step 3: Open Control Panel and Uninstall Autodesk Software
Write-Host "Searching for Autodesk software to uninstall..."

# Exclude Autodesk software that will be handled later in the script
$excludeList = @(
    "Autodesk Access",
    "Autodesk Licensing Desktop Service",
    "Autodesk Genuine Service"
)

# Retrieve installed software from registry
$autodeskSoftware = Get-ItemProperty `
    HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*, `
    HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*, `
    HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* -ErrorAction SilentlyContinue |
    Where-Object {
        $_.DisplayName -and
        ((-not $_.PSObject.Properties.Match('SystemComponent')) -or ($_.SystemComponent -ne 1)) -and
        ($_.Publisher -like '*Autodesk*')
    } |
    Select-Object DisplayName, DisplayVersion, Publisher |
    Sort-Object DisplayName |
    Where-Object { $excludeList -notcontains $_.DisplayName }

# Flag to track uninstall failures
$uninstallFailed = $false  

if ($autodeskSoftware) {
    Write-Host "`nThe following Autodesk software was found:`n"
    $autodeskSoftware | ForEach-Object { Write-Host "- $($_.DisplayName)" }

    # Prompt user before proceeding
    $confirmation = Read-Host "`nPress 'Y' to continue with uninstallation or any other key to cancel"
    if ($confirmation -ne "Y" -and $confirmation -ne "y") {
        Write-Host "Uninstallation canceled by user.`n" -ForegroundColor Yellow
        exit
    }

    $autodeskSoftware | ForEach-Object {
        Write-Host "Uninstalling $($_.DisplayName)..."
        if ($_.PSChildName -and (Test-Path $_.PSPath)) {
            try {
                $uninstallString = ($_ | Get-ItemProperty).UninstallString
                if ($uninstallString) {
                    Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$uninstallString /quiet /norestart`"" -Wait
                    Write-Host "Successfully uninstalled $($_.DisplayName)." -ForegroundColor Green
                } else {
                    Write-Host "Failed to uninstall. No uninstall string found for $($_.DisplayName)." -ForegroundColor Red
                    $uninstallFailed = $true
                }
            } catch {
                Write-Host "Error uninstalling $($_.DisplayName): $_" -ForegroundColor Red
                $uninstallFailed = $true
            }
        }
    }
} else {
    Write-Host "No Autodesk software found.`n" -ForegroundColor Yellow
    exit
}

Write-Host ""

# Step 4: Run RemoveODIS.exe to Uninstall Autodesk Access
$odisPath = "C:\Program Files\Autodesk\AdODIS\V1\RemoveODIS.exe"
if (Test-Path $odisPath) {
    Write-Host "Running RemoveODIS.exe..."
    Start-Process -FilePath $odisPath -ArgumentList "--mode unattended" -Wait
    Write-Host "Successfully uninstalled Autodesk Access." -ForegroundColor Green
} else {
    Write-Host "RemoveODIS.exe not found, skipping..." -ForegroundColor Yellow
}

Write-Host ""

# Step 5: Run Uninstall.exe to Uninstall Autodesk Licensing Desktop Service
$licensingPath = "C:\Program Files (x86)\Common Files\Autodesk Shared\AdskLicensing\uninstall.exe"
if (Test-Path $licensingPath) {
    Write-Host "Running uninstall.exe..."
    Start-Process -FilePath $licensingPath -Wait
    Write-Host "Successfully uninstalled Autodesk Licensing Desktop Service." -ForegroundColor Green
} else {
    Write-Host "Uninstall.exe not found, skipping..." -ForegroundColor Yellow
}

Write-Host ""

# Step 6: Use Microsoft Troubleshooter (Manual Step Required)
Write-HostWrapped "Please download and run the Microsoft Program Install and Uninstall Troubleshooter to remove any residual Autodesk software: https://aka.ms/Program_Install_and_Uninstall"

# Stop execution if at least one uninstall failed
if ($uninstallFailed) {
    Write-Host "Skipping further cleanup due to previous uninstall failures." -ForegroundColor Yellow
    exit
}

Write-Host ""

# Step 7: Clear Temp Folder
Write-Host "Clearing Temp Folder..."
Get-ChildItem -Path $tempPath -Recurse -Force | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
Write-Host "Temp folder cleared." -ForegroundColor Green

Write-Host ""

# Step 8: Remove FLEXnet Files
$flexnetPath = "C:\ProgramData\FLEXnet"
if (Test-Path $flexnetPath) {
    Write-Host "Checking for FLEXnet files..."
    $filesToRemove = Get-ChildItem -Path $flexnetPath -Filter "adsk*" -Force

    if ($filesToRemove) {
        Write-Host "Removing FLEXnet files..."
        $filesToRemove | Remove-Item -Force -ErrorAction SilentlyContinue
        Write-Host "FLEXnet files removed." -ForegroundColor Green
    } else {
        Write-Host "No matching FLEXnet files found." -ForegroundColor Yellow
    }
} else {
    Write-Host "FLEXnet folder not found." -ForegroundColor Yellow
}

Write-Host ""

# Step 9: Remove Autodesk Folders
$foldersToDelete = @(
    "C:\Program Files\Autodesk",
    "C:\Program Files\Common Files\Autodesk Shared",
    "C:\Program Files (x86)\Autodesk",
    "C:\Program Files (x86)\Common Files\Autodesk Shared",
    "C:\ProgramData\Autodesk",
    $localAppDataPath,
    $appDataPath
)
foreach ($folder in $foldersToDelete) {
    if (Test-Path $folder) {
        Write-Host "Deleting folder: $folder"
        Remove-Item -Path $folder -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Autodesk folders removed." -ForegroundColor Green
    } else {
        Write-Host "Folder not found: $folder" -ForegroundColor Yellow
    }
}

Write-Host ""

# Step 10: Remove Registry Keys
$regKeys = @(
    "HKLM:\SOFTWARE\Autodesk",
    $hkcuRegistryPath
)
foreach ($key in $regKeys) {
    if (Test-Path $key) {
        Write-Host "Removing registry key: $key"
        Remove-Item -Path $key -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Registry keys removed" -ForegroundColor Green
    } else {
        Write-Host "Registry key not found: $key" -ForegroundColor Yellow
    }
}

Write-Host ""

# Step 11: Uninstall Autodesk Genuine Service
$genuineService = Get-ItemProperty `
    HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*, `
    HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*, `
    HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* -ErrorAction SilentlyContinue |
    Where-Object {
        $_.DisplayName -and ($_.DisplayName -match "Autodesk Genuine Service")
    }

if ($genuineService) {
    Write-Host "Uninstalling Autodesk Genuine Service..."
    $uninstallFailed = $false

    $genuineService | ForEach-Object {
        try {
            $uninstallString = ($_ | Get-ItemProperty).UninstallString
            if ($uninstallString) {
                Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$uninstallString /quiet /norestart`"" -Wait
                Write-Host "Successfully uninstalled Autodesk Genuine Service." -ForegroundColor Green
            } else {
                Write-Host "Failed to uninstall. No uninstall string found for Autodesk Genuine Service." -ForegroundColor Red
                $uninstallFailed = $true
            }
        } catch {
            Write-Host "Error uninstalling Autodesk Genuine Service: $_" -ForegroundColor Red
            $uninstallFailed = $true
        }
    }
} else {
    Write-Host "Autodesk Genuine Service not found." -ForegroundColor Yellow
}

Write-Host ""

Write-HostWrapped "Autodesk Clean Uninstall completed. Please review any remaining files or registry keys manually."
Write-Host "For a full report, check the log file: $logFile"

Write-Host ""
