<#	
	.NOTES
	===========================================================================
	 Created on:   	2/24/2020 1:11 PM
	 Created by:   	Omerf
	 Organization: 	Israel Cyber Directorate
	 Filename:     	CyberMisc
	===========================================================================
	.DESCRIPTION
		Cyber Audit Tool - Misc scripts
#>

. $PSScriptRoot\CyberFunctions.ps1

function Report($msg)
    {
        Add-Content -Path "$ACQ\MiscScriptsReport-$env:USERDNSDOMAIN.txt" -Value $msg	
    }

$ACQ = ACQ("Misc")


#Check for WSUS Updates over HTTP
Write-Host "Checking if there is WSUS running over unencripted http protocol..."
$UseWUServer = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name UseWUServer -ErrorAction SilentlyContinue).UseWUServer
$WUServer = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name WUServer -ErrorAction SilentlyContinue).WUServer

if($UseWUServer -eq 1 -and $WUServer.ToLower().StartsWith("http://")) 
{
    failed "WSUS Server over HTTP detected, is is possible to send fake Updates to all hosts in this network"
    Add-Content -Path "$ACQ\MiscScriptsReport-$env:USERDNSDOMAIN.txt" -Value "Wsus server faces updates can be sent from: $UseWUServer/$WUServer"	
}
else
{
    success "WSUS server is either not installed or running over HTTPS secured protocol" 
}