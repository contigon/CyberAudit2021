<#	
	.NOTES
	===========================================================================
	 Created on:   	17/03/2021 1:11 PM
	 Created by:   	Omerf
	 Organization: 	Israel Cyber Directorate
	 Filename:     	CyberCompress
	===========================================================================
	.DESCRIPTION
		Cyber Audit Tool - Compress installation files and upload as .pdf to github and web 
#>

<#

Add local project to github:
1. cd <Projec>
2. git init .
3. Create New Git Folder in github
4. git remote add origin https://github.com/contigon/CyberAuditPS2021.git

#>

$runningScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "Cyber Audit Tool 2021 [$runningScriptName]"

$CatInstallRepository = "CATInstall"
mkdir "c:\$CatInstallRepository" -Force
Copy-Item -Path "$PSScriptRoot\go.ps1" -Destination "c:\$CatInstallRepository\go.ps1" -Force

$compress = @{
  Path = "$PSScriptRoot\cyberAnalyzers.ps1",
          "$PSScriptRoot\cyberAudit.ps1",
          "$PSScriptRoot\cyberAuditRemote.ps1",
          "$PSScriptRoot\cyberBuild.ps1",
          "$PSScriptRoot\cyberAttack.ps1",
          "$PSScriptRoot\CyberCollectNetworkConfig.ps1",
          "$PSScriptRoot\CyberCollectNetworkConfigV2.ps1",
          "$PSScriptRoot\CyberCompressGo.ps1",
          "$PSScriptRoot\CyberCreateRunecastRole.ps1",
          "$PSScriptRoot\CyberFunctions.ps1",
          "$PSScriptRoot\CyberLicenses.ps1",
          "$PSScriptRoot\CyberPasswordStatistics.ps1",
          "$PSScriptRoot\CyberUserDumpStatistics.ps1",
          "$PSScriptRoot\CyberPingCastle.ps1",
          "$PSScriptRoot\go.ps1",
          "$PSScriptRoot\CyberMisc.ps1",
          "$PSScriptRoot\CyberReport.ps1",
          "$PSScriptRoot\CyberOfflineNTDS.ps1",
          "$PSScriptRoot\CyberGPLinkReport.ps1",
          "$PSScriptRoot\CyberInstall-RSATv1809v1903v1909v2004v20H2.ps1",
          "$PSScriptRoot\CyberRamTrimmer.ps1",
          "$PSScriptRoot\Scuba2CSV.py",
          "$PSScriptRoot\CyberRiskCompute.xlsx",
          "$PSScriptRoot\CyberAuditPrep.xlsx",
          "$PSScriptRoot\CyberAuditDevelopersHelp.txt",
          "$PSScriptRoot\CyberBginfo.bgi",
          "$PSScriptRoot\Bginfo64.exe",
          "$PSScriptRoot\CyberRedIcon.ico",
          "$PSScriptRoot\CyberBlackIcon.ico",
          "$PSScriptRoot\CyberGreenIcon.ico",
          "$PSScriptRoot\CyberYellowIcon.ico"
  CompressionLevel = "Fastest"
  DestinationPath = "c:\$CatInstallRepository\go.zip"
}

$c = $compress['path']
Write-Host "Files ($c) will be compressed now" -ForegroundColor Green
Write-Host ""
Compress-Archive @compress -Force
del "c:\$CatInstallRepository\go.pdf"
Rename-Item -Path "c:\$CatInstallRepository\go.zip" -NewName "go.pdf" -Force

if ((Test-Path "c:\$CatInstallRepository\go.pdf") -and (Test-Path "c:\$CatInstallRepository\go.ps1")) {
    Write-Host "go.pdf created successfully" -ForegroundColor Green
    Push-Location "c:\$CatInstallRepository"
    git pull
    Write-Host "Uploading <go.pdf\go.ps1> to github contigon\$CatInstallRepository repo" -ForegroundColor Green
    git add .
    git commit -m "commiting from $env:USERNAME from $env:COMPUTERNAME"
    git push
    Pop-Location
}

