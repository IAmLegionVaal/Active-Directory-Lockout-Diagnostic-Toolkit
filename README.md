# Active Directory Lockout Diagnostic Toolkit

A read-only PowerShell toolkit for Active Directory lockout troubleshooting.

## Features

- AD module and domain context check
- User lockout state review
- Password and logon metadata
- Optional security event review on accessible systems
- CSV, JSON, and HTML reports

## How to run

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Active_Directory_Lockout_Diagnostic_Toolkit.ps1 -SamAccountName jsmith
```

## Requirements

- RSAT Active Directory module
- Appropriate domain permissions

## Safety

Diagnostic-only. It does not unlock accounts or modify Active Directory.
