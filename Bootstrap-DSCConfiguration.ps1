<#
.SYNOPSIS
    Bootstrap script to download and execute DSC time zone configuration from GitHub.

.DESCRIPTION
    This script downloads the DSC configuration script from a GitHub repository
    and executes it to configure the Windows 11 time zone to Central Standard Time.
    Can be run directly from a web browser or command line.

.NOTES
    File Name      : Bootstrap-DSCConfiguration.ps1
    Author         : IT Administration Team
    Prerequisite   : PowerShell 5.1 or higher, Internet access, Administrator privileges
    Version        : 1.0
    
.PARAMETER GitHubUrl
    The raw GitHub URL where the DSC configuration script is stored.
    
.EXAMPLE
    # Run from PowerShell command line
    .\Bootstrap-DSCConfiguration.ps1 -GitHubUrl "https://raw.githubusercontent.com/mlamia-usa/win11-dsc-config/main/Set-TimeZoneDSC.ps1"
    
.EXAMPLE
    # One-liner for command prompt or browser (Run dialog)
    powershell -ExecutionPolicy Bypass -Command "irm 'https://raw.githubusercontent.com/mlamia-usa/win11-dsc-config/main/Bootstrap-DSCConfiguration.ps1' | iex"
#>

#Requires -RunAsAdministrator
#Requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$GitHubUrl = "https://raw.githubusercontent.com/mlamia-usa/win11-dsc-config/main/Set-TimeZoneDSC.ps1"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Display banner
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  DSC Configuration Bootstrap Script" -ForegroundColor Cyan
Write-Host "  Time Zone Configuration for Windows 11" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as administrator
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Please right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "[INFO] Administrator privileges confirmed" -ForegroundColor Green
Write-Host ""

try {
    # Test internet connectivity
    Write-Host "[INFO] Testing internet connectivity..." -ForegroundColor Cyan
    $TestConnection = Test-Connection -ComputerName "github.com" -Count 1 -Quiet -ErrorAction SilentlyContinue
    
    if (-not $TestConnection) {
        throw "Unable to reach GitHub. Please check your internet connection."
    }
    
    Write-Host "[SUCCESS] Internet connectivity verified" -ForegroundColor Green
    Write-Host ""
    
    # Set TLS 1.2 for secure downloads
    Write-Host "[INFO] Configuring secure connection (TLS 1.2)..." -ForegroundColor Cyan
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Write-Host "[SUCCESS] Secure connection configured" -ForegroundColor Green
    Write-Host ""
    
    # Download the DSC configuration script
    Write-Host "[INFO] Downloading DSC configuration script..." -ForegroundColor Cyan
    Write-Host "[INFO] Source: $GitHubUrl" -ForegroundColor Cyan
    
    $ScriptContent = Invoke-RestMethod -Uri $GitHubUrl -UseBasicParsing -ErrorAction Stop
    
    if ([string]::IsNullOrWhiteSpace($ScriptContent)) {
        throw "Downloaded script is empty or invalid"
    }
    
    Write-Host "[SUCCESS] Script downloaded successfully" -ForegroundColor Green
    Write-Host ""
    
    # Save script to temporary location
    $TempScriptPath = "$env:TEMP\Set-TimeZoneDSC_$(Get-Date -Format 'yyyyMMddHHmmss').ps1"
    Write-Host "[INFO] Saving script to: $TempScriptPath" -ForegroundColor Cyan
    
    $ScriptContent | Out-File -FilePath $TempScriptPath -Encoding UTF8 -Force
    Write-Host "[SUCCESS] Script saved successfully" -ForegroundColor Green
    Write-Host ""
    
    # Verify the script file
    if (-not (Test-Path -Path $TempScriptPath)) {
        throw "Failed to save script to temporary location"
    }
    
    # Execute the DSC configuration script
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "  Executing DSC Configuration Script" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    
    & $TempScriptPath
    
    # Check execution result
    if ($LASTEXITCODE -ne 0 -and $null -ne $LASTEXITCODE) {
        throw "DSC configuration script returned error code: $LASTEXITCODE"
    }
    
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "  Bootstrap completed successfully!" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "The time zone has been configured." -ForegroundColor Green
    Write-Host "No reboot is required for this change." -ForegroundColor Green
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Red
    Write-Host "  ERROR: Bootstrap Failed" -ForegroundColor Red
    Write-Host "============================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error Message: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting steps:" -ForegroundColor Yellow
    Write-Host "1. Verify internet connectivity" -ForegroundColor Yellow
    Write-Host "2. Check that the GitHub URL is correct and accessible" -ForegroundColor Yellow
    Write-Host "3. Ensure you're running PowerShell as Administrator" -ForegroundColor Yellow
    Write-Host "4. Check Windows Event Logs for additional details" -ForegroundColor Yellow
    Write-Host ""
    
    exit 1
} finally {
    # Cleanup temporary script file
    if (Test-Path -Path $TempScriptPath -ErrorAction SilentlyContinue) {
        Write-Host "[INFO] Cleaning up temporary files..." -ForegroundColor Cyan
        Remove-Item -Path $TempScriptPath -Force -ErrorAction SilentlyContinue
        Write-Host "[SUCCESS] Cleanup completed" -ForegroundColor Green
        Write-Host ""
    }
}

Write-Host "Press Enter to exit..." -ForegroundColor Cyan
Read-Host