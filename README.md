# Windows 11 DSC Time Zone Configuration

Automated PowerShell DSC configuration to set Windows 11 devices to Central Standard Time (Chicago).

## 📋 Prerequisites

- Windows 11 (fully installed)
- Internet access
- Administrator privileges
- PowerShell 5.1 or higher (included in Windows 11)

## 🚀 Quick Start Methods

### Method 1: One-Line Command (Recommended)

**From PowerShell (Run as Administrator):**

```powershell
irm 'https://raw.githubusercontent.com/yourusername/yourrepo/main/Bootstrap-DSCConfiguration.ps1' | iex
```

**From Command Prompt (Run as Administrator):**

```cmd
powershell -ExecutionPolicy Bypass -Command "irm 'https://raw.githubusercontent.com/yourusername/yourrepo/main/Bootstrap-DSCConfiguration.ps1' | iex"
```

**From Windows Run Dialog (Win + R):**

```
powershell -ExecutionPolicy Bypass -Command "irm 'https://raw.githubusercontent.com/yourusername/yourrepo/main/Bootstrap-DSCConfiguration.ps1' | iex"
```

### Method 2: Download and Execute

1. Open PowerShell as Administrator
2. Download the bootstrap script:
   ```powershell
   Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/yourusername/yourrepo/main/Bootstrap-DSCConfiguration.ps1' -OutFile "$env:TEMP\Bootstrap-DSCConfiguration.ps1"
   ```
3. Execute the script:
   ```powershell
   & "$env:TEMP\Bootstrap-DSCConfiguration.ps1"
   ```

### Method 3: Manual Download

1. Download both scripts from GitHub
2. Right-click PowerShell and select "Run as Administrator"
3. Navigate to the download location
4. Execute: `.\Bootstrap-DSCConfiguration.ps1`

## 📁 Repository Structure

```
yourrepo/
├── Set-TimeZoneDSC.ps1           # Main DSC configuration script
├── Bootstrap-DSCConfiguration.ps1 # Bootstrap/launcher script
└── README.md                      # This file
```

## 🔧 How It Works

1. **Bootstrap Script** (`Bootstrap-DSCConfiguration.ps1`):
   - Verifies administrator privileges
   - Tests internet connectivity
   - Downloads the DSC configuration script from GitHub
   - Executes the DSC configuration
   - Cleans up temporary files

2. **DSC Configuration Script** (`Set-TimeZoneDSC.ps1`):
   - Checks current time zone
   - Defines DSC configuration for Central Standard Time
   - Generates MOF (Managed Object Format) file
   - Applies the DSC configuration
   - Verifies the configuration was successful
   - Tests DSC compliance

## 📊 What Gets Configured

- **Time Zone**: Central Standard Time (America/Chicago)
- **UTC Offset**: -06:00 (CST) / -05:00 (CDT)
- **Daylight Saving**: Automatically handled by Windows

## 📝 Logging

All operations are logged to:
```
C:\ProgramData\DSCConfiguration\Logs\TimeZoneConfig_YYYYMMDD_HHMMSS.log
```

Logs include:
- Timestamp for each operation
- Current and target time zone information
- DSC configuration steps
- Verification results
- Any errors or warnings

## ✅ Verification

After execution, verify the configuration:

```powershell
# Check current time zone
Get-TimeZone

# Test DSC configuration
Test-DscConfiguration -Path "C:\ProgramData\DSCConfiguration\MOF"

# View logs
Get-Content "C:\ProgramData\DSCConfiguration\Logs\*.log" -Tail 50
```

## 🛠️ Customization

To change to a different time zone:

1. Edit `Set-TimeZoneDSC.ps1`
2. Modify the `$TargetTimeZone` variable (line ~72)
3. Use one of the valid Windows time zone IDs

**Common Time Zones:**
- `Eastern Standard Time` - ET (UTC-5/-4)
- `Central Standard Time` - CT (UTC-6/-5)
- `Mountain Standard Time` - MT (UTC-7/-6)
- `Pacific Standard Time` - PT (UTC-8/-7)

**List all available time zones:**
```powershell
Get-TimeZone -ListAvailable | Select-Object Id, DisplayName, BaseUtcOffset
```

## 🔒 Security Considerations

- Scripts require administrator privileges
- Use `-ExecutionPolicy Bypass` only for trusted scripts
- Review scripts before execution in production
- Consider code signing for enterprise deployment
- TLS 1.2 is enforced for secure downloads

## 🚨 Troubleshooting

### Script won't run - Execution Policy
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Not running as Administrator
- Right-click PowerShell → "Run as Administrator"
- Check for UAC prompts

### Internet connectivity issues
- Verify GitHub is accessible: `Test-Connection github.com`
- Check proxy settings
- Verify firewall allows PowerShell internet access

### DSC Configuration fails
- Check Event Viewer: Applications and Services Logs → Microsoft → Windows → DSC
- Review log files in `C:\ProgramData\DSCConfiguration\Logs\`
- Ensure no other DSC configurations are actively running

## 📦 Enterprise Deployment Options

### Group Policy
Deploy via GPO using a Startup Script:
1. Computer Configuration → Policies → Windows Settings → Scripts → Startup
2. Add: `powershell.exe -ExecutionPolicy Bypass -File "\\server\share\Bootstrap-DSCConfiguration.ps1"`

### MDM/Intune
Create a PowerShell script policy:
1. Devices → Scripts → Add → Windows 10 and later
2. Upload `Bootstrap-DSCConfiguration.ps1`
3. Run as: System
4. Enforce script signature check: No

### SCCM/Configuration Manager
1. Create a Package with the scripts
2. Create a Program to execute the bootstrap script
3. Deploy to device collections

## 📄 License

Include your organization's license information here.

## 👥 Support

For issues or questions:
- Check logs: `C:\ProgramData\DSCConfiguration\Logs\`
- Review GitHub Issues
- Contact IT Support

## 🔄 Version History

- **v1.0** - Initial release
  - Central Standard Time configuration
  - Comprehensive logging
  - Error handling and validation