<#	
	.NOTES
	===========================================================================
	 Created on:   	2/24/2020 1:11 PM
	 Created by:   	Omerf
	 Organization: 	Israel Cyber Directorate
	 Filename:     	CyberMenu
	===========================================================================
	.DESCRIPTION
		Cyber Audit Tool - Menu
#>

. $PSScriptRoot\CyberFunctions.ps1
ShowLogo
read-host “Press ENTER to continue”
cls

do {
#Create the main menu
Write-Host ""
Write-Host "*****************************************************************                  " -ForegroundColor White
Write-Host "*** Cyber Audit Tool (LiteEdition) - ISRAEL CYBER DIRECTORATE ***                  " -ForegroundColor White
Write-Host "*****************************************************************                  " -ForegroundColor White
Write-Host ""
Write-Host "     Report:                                                                        " -ForegroundColor White
Write-Host ""
Write-Host "     1. Analyze		| Analyze NTDS/SYSTEM files and export pwdump/ophcrack files    " -ForegroundColor White
Write-Host "     2. bloodhzs 	| Password cracker based on rainbow tables                      " -ForegroundColor White
Write-Host ""
Write-Host "    99. Quit                                                          " -ForegroundColor White
Write-Host ""
$input=Read-Host "Select Script Number"

switch ($input)
 {
     #Analyze the NTDS and SYSTEM hive (ntdsaudit, DSInternals)
     1 {
        $ACQ = ACQ("NTDS")
        Get-ChildItem -Path $ACQ -Recurse -File | Move-Item -Destination $ACQ
        read-host “Press ENTER to continue”
    }
   }
  CLS
 }
while ($input -ne '99')