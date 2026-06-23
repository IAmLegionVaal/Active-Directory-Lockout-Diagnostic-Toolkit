# Active Directory Lockout Diagnostic Toolkit

> **Related current workflow:** For the root-cause-focused evidence and remediation project, see [Account Lockout Root Cause Analyzer](https://github.com/IAmLegionVaal/Account-Lockout-Root-Cause-Analyzer). This repository remains available as the broader guarded account-recovery variant.

A PowerShell toolkit for Active Directory lockout diagnosis and selected guarded account recovery actions.

## Diagnostic script

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Active_Directory_Lockout_Diagnostic_Toolkit.ps1 -SamAccountName jsmith
```

## Repair script

Preview an unlock:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Active_Directory_Lockout_Repair_Toolkit.ps1 -SamAccountName jsmith -UnlockAccount -DryRun
```

Examples:

```powershell
.\Active_Directory_Lockout_Repair_Toolkit.ps1 -SamAccountName jsmith -UnlockAccount
.\Active_Directory_Lockout_Repair_Toolkit.ps1 -SamAccountName jsmith -EnableAccount
.\Active_Directory_Lockout_Repair_Toolkit.ps1 -SamAccountName jsmith -RequirePasswordChange
.\Active_Directory_Lockout_Repair_Toolkit.ps1 -SamAccountName jsmith -UnlockAccount -PurgeKerberosTickets -Yes
```

## Repair behavior

- Requires an elevated Windows PowerShell session and the RSAT Active Directory module.
- Exports the user's current state to JSON before any directory change.
- Supports explicit account unlock, enablement, password-change-at-next-logon and current-session Kerberos-ticket purge actions.
- Refuses automated changes to accounts marked as protected administrative accounts.
- Provides `-DryRun`, confirmation or `-Yes`, timestamped logs, post-change verification and distinct exit codes.

Exit codes are `0` success, `2` invalid input, `3` missing privileges or prerequisites, `4` cancelled, `5` action failure and `6` verification failure.

## Safety

Use the diagnostic report to identify the lockout source first. The repair script does not reset passwords, delete cached credentials, change lockout policy or modify protected administrative accounts.

## Author

Dewald Pretorius — L2 IT Support Engineer
