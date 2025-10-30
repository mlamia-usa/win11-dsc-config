<#
.SYNOPSIS
    PowerShell DSC Configuration to set Windows 11 time zone to Central Standard Time.

.DESCRIPTION
    This script uses PowerShell Desired State Configuration (DSC) to configure
    the system time zone to Central Standard Time (America/Chicago).
    It follows DSC best practices with proper error handling, logging, and validation.

.NOTES
    File Name      : Set-TimeZoneDSC.ps1
    Author         : IT Administration Team
    Prerequisite   : PowerShell 5.1 or higher, Administrator privileges
    Version        : 1.0
    
.EXAMPLE
    .\Set-TimeZoneDSC.ps1
#>

#Requires -RunAsAdministrator
#Requires -Version 5.1

[CmdletBinding()]
param()

# Set strict mode for better error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Configure logging
$LogPath = "$env:ProgramData\DSCConfiguration\Logs"
$LogFile = "$LogPath\TimeZoneConfig_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Create log directory if it doesn't exist
if (-not (Test-Path -Path $LogPath)) {
    New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
}

# Logging function
function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )
    
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $LogMessage = "[$Timestamp] [$Level] $Message"
    
    # Write to log file
    Add-Content -Path $LogFile -Value $LogMessage
    
    # Write to console with color coding
    switch ($Level) {
        'Info'    { Write-Host $LogMessage -ForegroundColor Cyan }
        'Warning' { Write-Host $LogMessage -ForegroundColor Yellow }
        'Error'   { Write-Host $LogMessage -ForegroundColor Red }
        'Success' { Write-Host $LogMessage -ForegroundColor Green }
    }
}

# Start configuration process
Write-Log -Message "========================================" -Level Info
Write-Log -Message "Starting DSC Time Zone Configuration" -Level Info
Write-Log -Message "========================================" -Level Info
Write-Log -Message "Log file location: $LogFile" -Level Info

try {
    # Check current time zone
    $CurrentTimeZone = Get-TimeZone
    Write-Log -Message "Current Time Zone: $($CurrentTimeZone.Id) - $($CurrentTimeZone.DisplayName)" -Level Info
    
    # Define the target time zone
    $TargetTimeZone = 'Central Standard Time'
    Write-Log -Message "Target Time Zone: $TargetTimeZone" -Level Info
    
    # Validate that the target time zone exists on the system
    Write-Log -Message "Validating target time zone availability..." -Level Info
    $AvailableTimeZones = Get-TimeZone -ListAvailable
    if ($AvailableTimeZones.Id -notcontains $TargetTimeZone) {
        throw "Time zone '$TargetTimeZone' is not available on this system."
    }
    Write-Log -Message "Target time zone validated successfully" -Level Success
    
    # DSC Configuration Block
    Write-Log -Message "Defining DSC Configuration..." -Level Info
    
    Configuration TimeZoneConfiguration {
        param(
            [string]$NodeName = 'localhost',
            [string]$TimeZoneId = 'Central Standard Time'
        )
        
        Import-DscResource -ModuleName PSDesiredStateConfiguration
        
        Node $NodeName {
            # Configure Time Zone
            Script SetTimeZone {
                GetScript = {
                    $currentTZ = Get-TimeZone
                    return @{
                        Result = $currentTZ.Id
                    }
                }
                
                TestScript = {
                    $currentTZ = Get-TimeZone
                    $targetTZ = $using:TimeZoneId
                    
                    if ($currentTZ.Id -eq $targetTZ) {
                        Write-Verbose "Time zone is already set to $targetTZ"
                        return $true
                    } else {
                        Write-Verbose "Time zone needs to be changed from $($currentTZ.Id) to $targetTZ"
                        return $false
                    }
                }
                
                SetScript = {
                    $targetTZ = $using:TimeZoneId
                    try {
                        Set-TimeZone -Id $targetTZ -ErrorAction Stop
                        Write-Verbose "Successfully set time zone to $targetTZ"
                    } catch {
                        throw "Failed to set time zone: $_"
                    }
                }
            }
        }
    }
    
    Write-Log -Message "DSC Configuration defined successfully" -Level Success
    
    # Generate MOF file
    Write-Log -Message "Generating MOF configuration file..." -Level Info
    $OutputPath = "$env:ProgramData\DSCConfiguration\MOF"
    
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }
    
    $ConfigData = @{
        AllNodes = @(
            @{
                NodeName = 'localhost'
                PSDscAllowPlainTextPassword = $true
            }
        )
    }
    
    TimeZoneConfiguration -NodeName localhost -TimeZoneId $TargetTimeZone -OutputPath $OutputPath
    Write-Log -Message "MOF file generated at: $OutputPath" -Level Success
    
    # Apply DSC Configuration
    Write-Log -Message "Applying DSC Configuration..." -Level Info
    Write-Log -Message "This may take a few moments..." -Level Info
    
    Start-DscConfiguration -Path $OutputPath -Wait -Verbose -Force
    
    Write-Log -Message "DSC Configuration applied successfully" -Level Success
    
    # Verify the configuration
    Write-Log -Message "Verifying time zone configuration..." -Level Info
    $NewTimeZone = Get-TimeZone
    
    if ($NewTimeZone.Id -eq $TargetTimeZone) {
        Write-Log -Message "VERIFICATION SUCCESSFUL: Time zone is now set to $($NewTimeZone.Id)" -Level Success
        Write-Log -Message "Display Name: $($NewTimeZone.DisplayName)" -Level Success
        Write-Log -Message "UTC Offset: $($NewTimeZone.BaseUtcOffset)" -Level Success
    } else {
        Write-Log -Message "VERIFICATION FAILED: Time zone is $($NewTimeZone.Id), expected $TargetTimeZone" -Level Error
        throw "Time zone verification failed"
    }
    
    # Test DSC Configuration
    Write-Log -Message "Testing DSC Configuration compliance..." -Level Info
    $TestResult = Test-DscConfiguration -Path $OutputPath -Verbose
    
    if ($TestResult.InDesiredState) {
        Write-Log -Message "DSC Configuration is compliant" -Level Success
    } else {
        Write-Log -Message "DSC Configuration compliance check returned issues" -Level Warning
    }
    
    Write-Log -Message "========================================" -Level Info
    Write-Log -Message "Configuration completed successfully!" -Level Success
    Write-Log -Message "========================================" -Level Info
    
} catch {
    Write-Log -Message "ERROR: $($_.Exception.Message)" -Level Error
    Write-Log -Message "Stack Trace: $($_.ScriptStackTrace)" -Level Error
    Write-Log -Message "Configuration failed. Please review the log file." -Level Error
    throw
} finally {
    Write-Log -Message "Script execution completed" -Level Info
    Write-Log -Message "Full log available at: $LogFile" -Level Info
}