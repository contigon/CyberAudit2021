<#	
	.NOTES
	===========================================================================
	 Created on:   	2/24/2020 1:11 PM
	 Created by:   	Omerf
	 Organization: 	Israel Cyber Directorate
	 Filename:     	CyberReport
	===========================================================================
	.DESCRIPTION
		Cyber Audit Tool - Report information about organization 
#>

# . $PSScriptRoot\CyberFunctions.ps1
#ShowIncd
#DisableFirewall
#DisableAntimalware
#CyberBginfo
$Host.UI.RawUI.WindowTitle = "Cyber Audit Tool 2020 - Report"

CLS

if ((Test-NetConnection -ComputerName google.com).Pingsucceeded)
{
    $externalIP = (Invoke-WebRequest -uri "http://ifconfig.me/ip").Content
}
else
{
    $externalIP = "No Internet Access from this machine"
}

$DomainMode = Get-ADDomain | Select-Object -ExpandProperty domainmode
$sysinfo = systeminfo
$mem = ($sysinfo | Select-String 'Total Physical Memory:').ToString().Split(':')[1].Trim()
$os = ($sysinfo | Select-String 'OS Name:').ToString().Split(':')[1].Trim()
$arch = ($sysinfo | Select-String 'System Type:').ToString().Split(':')[1].Trim()
$tz = ($sysinfo | Select-String 'Time Zone:').ToString().Split(':')[1].Trim()
$os = ($sysinfo | Select-String 'OS Name:').ToString().Split(':')[1].Trim()
$os = ($sysinfo | Select-String 'OS Name:').ToString().Split(':')[1].Trim()

$report = @"
----------------------------------------------------------
Organization External IP  | $externalIP
Domain Mode               | $DomainMode
HosT OS                   | $os
Physical Memory           | $mem
Architecture              | $arch
Domain                    | $env:USERDNSDOMAIN
Total Domain Controllers  | $dccount
"@
Write-Host $report -ForegroundColor Green
$dcs = Get-ADDomainController -Filter *
$i = 0
foreach ($dc in $dcs) 
{
    Write-Host "Domain Controller  [$i]    |" $dc.Name $dc.IPv4Address $dc.OperatingSystem -ForegroundColor Green
    $i++
}

Write-Host "----------------------------------------------------------"
Write-Host "Default Domain Policy:" -ForegroundColor Green
$dp = Get-ADDefaultDomainPasswordPolicy
Write-Host "ComplexityEnabled           | " $dp.ComplexityEnabled -ForegroundColor Green
Write-Host "LockoutDuration             | " $dp.LockoutDuration -ForegroundColor Green
Write-Host "LockoutObservationWindow    | " $dp.LockoutObservationWindow -ForegroundColor Green
Write-Host "MaxPasswordAge              | " $dp.MaxPasswordAge -ForegroundColor Green
Write-Host "MinPasswordAge              | " $dp.MinPasswordAge -ForegroundColor Green
Write-Host "MinPasswordLength           | " $dp.MinPasswordLength -ForegroundColor Green
Write-Host "PasswordHistoryCount        | " $dp.PasswordHistoryCount -ForegroundColor Green
Write-Host "ReversibleEncryptionEnabled | " $dp.ReversibleEncryptionEnabled -ForegroundColor Green
