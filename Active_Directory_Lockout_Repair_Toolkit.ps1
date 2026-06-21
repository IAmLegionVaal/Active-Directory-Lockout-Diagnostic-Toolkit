[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$SamAccountName,
    [switch]$UnlockAccount,
    [switch]$EnableAccount,
    [switch]$RequirePasswordChange,
    [switch]$PurgeKerberosTickets,
    [switch]$DryRun,
    [switch]$Yes,
    [string]$LogDirectory = "$env:ProgramData\IAmLegionVaal\ADLockoutRepair"
)

$ErrorActionPreference = 'Stop'
$ExitInvalidInput=2; $ExitPrerequisite=3; $ExitCancelled=4; $ExitActionFailure=5; $ExitVerificationFailure=6

function Test-Admin {
    $p = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
function Write-Log([string]$Message) {
    $line = "{0:u} {1}" -f (Get-Date),$Message
    Write-Host $line
    Add-Content -LiteralPath $script:LogPath -Value $line
}
function Invoke-Step([string]$Description,[scriptblock]$Action) {
    if ($DryRun) { Write-Log "[DRY-RUN] $Description"; return }
    Write-Log "[ACTION] $Description"
    & $Action
}

if (-not ($UnlockAccount -or $EnableAccount -or $RequirePasswordChange -or $PurgeKerberosTickets)) {
    Write-Error 'Select at least one repair action.'; exit $ExitInvalidInput
}
if (-not (Test-Admin)) { Write-Error 'Run from an elevated PowerShell session.'; exit $ExitPrerequisite }

New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
$script:LogPath=Join-Path $LogDirectory "ADLockoutRepair_$stamp.log"
$backupPath=Join-Path $LogDirectory "ADLockoutUser_$stamp.json"

try { Import-Module ActiveDirectory -ErrorAction Stop }
catch { Write-Error "ActiveDirectory module unavailable: $($_.Exception.Message)"; exit $ExitPrerequisite }

try {
    $user=Get-ADUser -Identity $SamAccountName -Properties Enabled,LockedOut,AdminCount,PasswordNeverExpires,PasswordLastSet,DistinguishedName
} catch { Write-Error "User lookup failed: $($_.Exception.Message)"; exit $ExitInvalidInput }
if ($user.AdminCount -eq 1) { Write-Error 'Protected administrative accounts are excluded from automated repair.'; exit $ExitInvalidInput }

$user | Select-Object SamAccountName,Enabled,LockedOut,AdminCount,PasswordNeverExpires,PasswordLastSet,DistinguishedName |
    ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $backupPath -Encoding UTF8
Write-Log "Saved pre-change user evidence to $backupPath"

$summary=@()
if($UnlockAccount){$summary+='unlock account'}
if($EnableAccount){$summary+='enable account'}
if($RequirePasswordChange){$summary+='require password change at next logon'}
if($PurgeKerberosTickets){$summary+='purge current-session Kerberos tickets'}
if(-not $DryRun -and -not $Yes){
    $answer=Read-Host ("Proceed for {0}: {1}? [y/N]" -f $SamAccountName,($summary -join '; '))
    if($answer -notmatch '^(?i)y(es)?$'){Write-Log '[CANCELLED] No changes were made.'; exit $ExitCancelled}
}

try {
    if($UnlockAccount){Invoke-Step "Unlock $SamAccountName" { Unlock-ADAccount -Identity $user.DistinguishedName }}
    if($EnableAccount){Invoke-Step "Enable $SamAccountName" { Enable-ADAccount -Identity $user.DistinguishedName }}
    if($RequirePasswordChange){Invoke-Step "Require password change for $SamAccountName" { Set-ADUser -Identity $user.DistinguishedName -ChangePasswordAtLogon $true }}
    if($PurgeKerberosTickets){Invoke-Step 'Purge current-session Kerberos tickets' {
        & klist.exe purge | ForEach-Object { Write-Log "[KLIST] $_" }
        if($LASTEXITCODE -ne 0){throw "klist exited with code $LASTEXITCODE"}
    }}
} catch { Write-Log "[FAILED] $($_.Exception.Message)"; exit $ExitActionFailure }

if($DryRun){Write-Log '[COMPLETE] Dry-run completed.'; exit 0}
$verifyFailed=$false
try {
    $after=Get-ADUser -Identity $user.DistinguishedName -Properties Enabled,LockedOut
    Write-Log ("[VERIFY] Enabled={0}; LockedOut={1}" -f $after.Enabled,$after.LockedOut)
    if($UnlockAccount -and $after.LockedOut){$verifyFailed=$true}
    if($EnableAccount -and -not $after.Enabled){$verifyFailed=$true}
} catch {Write-Log "[VERIFY-FAILED] $($_.Exception.Message)"; $verifyFailed=$true}
if($verifyFailed){exit $ExitVerificationFailure}
Write-Log '[COMPLETE] Repair and verification completed.'
exit 0
