#requires -Version 5.1
<#
.SYNOPSIS
    Active Directory User State Diagnostic Toolkit.
.DESCRIPTION
    Read-only Active Directory user state reporter for support review.
#>
[CmdletBinding()]
param([Parameter(Mandatory)][string]$SamAccountName,[string]$OutputPath)
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
if([string]::IsNullOrWhiteSpace($OutputPath)){$OutputPath=Join-Path ([Environment]::GetFolderPath('Desktop')) 'AD_User_State_Reports'}
New-Item -Path $OutputPath -ItemType Directory -Force|Out-Null
try{Import-Module ActiveDirectory -ErrorAction Stop}catch{Write-Error 'ActiveDirectory module not found. Install RSAT AD tools.';return}
try{$user=Get-ADUser -Identity $SamAccountName -Properties Enabled,LockedOut,LastLogonDate,PasswordLastSet,AccountExpirationDate,DistinguishedName -ErrorAction Stop}catch{Write-Error $_.Exception.Message;return}
$report=[PSCustomObject]@{SamAccountName=$user.SamAccountName;Name=$user.Name;Enabled=$user.Enabled;LockedOut=$user.LockedOut;LastLogonDate=$user.LastLogonDate;PasswordLastSet=$user.PasswordLastSet;AccountExpirationDate=$user.AccountExpirationDate;DistinguishedName=$user.DistinguishedName;Generated=Get-Date}
$report|Export-Csv (Join-Path $OutputPath "user_state_$stamp.csv") -NoTypeInformation -Encoding UTF8
$report|ConvertTo-Json -Depth 5|Set-Content (Join-Path $OutputPath "user_state_$stamp.json") -Encoding UTF8
$dcs=Get-ADDomainController -Filter * -ErrorAction SilentlyContinue|Select-Object HostName,Site,IPv4Address,IsGlobalCatalog
$dcs|Export-Csv (Join-Path $OutputPath "domain_controllers_$stamp.csv") -NoTypeInformation -Encoding UTF8
$html="<h1>AD User State - $($user.SamAccountName)</h1><p>Generated $(Get-Date)</p><h2>User Context</h2>$(@($report)|ConvertTo-Html -Fragment)<h2>Domain Controllers</h2>$($dcs|ConvertTo-Html -Fragment)"
$html|ConvertTo-Html -Title 'AD User State Diagnostic'|Set-Content (Join-Path $OutputPath "ad_user_state_$stamp.html") -Encoding UTF8
$report|Format-List
Write-Host "Reports saved to: $OutputPath" -ForegroundColor Green
