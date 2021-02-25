<#	
	.NOTES
	===========================================================================
	 Created on:   	2/24/2020 1:11 PM
	 Created by:   	Omerf
	 Organization: 	Israel Cyber Directorate
	 Filename:     	CyberOfflineNTDS
	===========================================================================
	.DESCRIPTION
		Cyber Audit Tool - Offline ntds.dit mount
#>

Write-Host "Browse and Choose the ntds.dit file to mount"
$ntdsfile = Get-FileName
$DomCont = Read-Host "Input name of Domain Controller Server"
$session = New-PSSession –ComputerName $DomCont
Write-Output "Creating folder on server $DomCont and copying the ntds.dit file"
Invoke-Command -Session $session -ScriptBlock {New-Item -ItemType Directory -Path "C:\TempNtds" -Force}
Copy-Item –Path $ntdsfile –Destination 'C:\TempNtds' –ToSession $session -Force
Write-Host "Checking the integrity of the ntds.dit database file"
Invoke-Command -Session $session -ScriptBlock {esentutl.exe /g "C:\TempNtds\ntds.dit"}
Write-Host "you can now mount the ntds.dit database file"
Invoke-Command -Session $session -ScriptBlock {dsamain.exe /dbpath C:\TempNtds\ntds.dit /ldapport 10389 /allownonadminaccess}
Invoke-Command -Session $session -ScriptBlock {dsamain.exe /dbpath C:\TempNtds\ntds.dit /ldapport 10389 /allownonadminaccess}
Get-ADRootDSE -Server $DC:10389 | Select-Object defaultNamingContext,domainFunctionality,forestFunctionality | fl
$cmd = "adexplorer"
Invoke-Expression $cmd
$session | Remove-PSSession
break

<#

#>

#Import-Module SharpHound.ps1
#Invoke-BloodHound -DomainController localhost -LdapPort 10389 -Domain mymc.local
