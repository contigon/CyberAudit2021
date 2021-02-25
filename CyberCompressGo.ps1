<#	
	.NOTES
	===========================================================================
	 Created on:   	2/24/2020 1:11 PM
	 Created by:   	Omerf
	 Organization: 	Israel Cyber Directorate
	 Filename:     	CyberCompress
	===========================================================================
	.DESCRIPTION
		Cyber Audit Tool - Compress installation/update files and upload as .pdf to github and web 
#>

<#

Add local project to github:
1. cd <Projec>
2. git init .
3. Create New Git Folder in github
4. git remote add origin https://github.com/contigon/CyberAuditPS2020.git

#>

$Host.UI.RawUI.WindowTitle = "Cyber Audit Tool 2020 - compress Go"

Import-Module Posh-SSH

Copy-Item -Path "$PSScriptRoot\go.ps1" -Destination "$PSScriptRoot\Downloads\go.ps1" -Force
Remove-Item "$PSScriptRoot\Downloads\go.zip" -ErrorAction SilentlyContinue
Remove-Item "$PSScriptRoot\Downloads\go.pdf" -ErrorAction SilentlyContinue
Remove-Item "$PSScriptRoot\Downloads\goUpdate.zip" -ErrorAction SilentlyContinue
Remove-Item "$PSScriptRoot\Downloads\goUpdate.pdf" -ErrorAction SilentlyContinue

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
  DestinationPath = "$PSScriptRoot\Downloads\go.zip"
}

$compressUpdates = @{
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
          "$PSScriptRoot\CyberMisc.ps1",
          "$PSScriptRoot\CyberReport.ps1",
          "$PSScriptRoot\CyberOfflineNTDS.ps1",
          "$PSScriptRoot\CyberGPLinkReport.ps1",
          "$PSScriptRoot\CyberRamTrimmer.ps1",
          "$PSScriptRoot\Scuba2CSV.py",
          "$PSScriptRoot\CyberRiskCompute.xlsx",
          "$PSScriptRoot\CyberAuditPrep.xlsx",
          "$PSScriptRoot\CyberAuditDevelopersHelp.txt",
          "$PSScriptRoot\CyberBginfo.bgi"
  CompressionLevel = "Fastest"
  DestinationPath = "$PSScriptRoot\Downloads\goUpdate.zip"
}

git pull
foreach ($f in $compressUpdates.Path){git add $f}
git commit -m "commited by $env:USERNAME from $env:COMPUTERNAME"
git push

$c = $compress['path']
Write-Host "Files ($c) will be compressed now" -ForegroundColor Green
Write-Host ""
Compress-Archive @compress -Force
Rename-Item -Path "$PSScriptRoot\Downloads\go.zip" -NewName "go.pdf"

$d = $compressUpdates['path']
Write-Host "Files ($d) will be compressed now" -ForegroundColor Green
Write-Host ""
Compress-Archive @compressUpdates -Force
Rename-Item -Path "$PSScriptRoot\Downloads\goUpdate.zip" -NewName "goUpdate.pdf"

if ((Test-Path "$PSScriptRoot\Downloads\go.pdf") -and (Test-Path "$PSScriptRoot\Downloads\goUpdate.pdf") -and (Test-Path "$PSScriptRoot\Downloads\go.ps1")) {
    Write-Host "go.pdf and goUpdate.pdf files were created successfully" -ForegroundColor Green
    Push-Location "$PSScriptRoot\Downloads"
    Get-ChildItem -Filter "nessus*.msi" | foreach {Remove-Item -Path $_}
    git pull
    Write-Host "Uploading <go.pdf\goUpdates.pdf\go.ps1> to github contigon\Downloads repo" -ForegroundColor Green
    git add .
    git commit -m "commiting from $env:USERNAME from $env:COMPUTERNAME"
    git push
    Pop-Location

    Write-Host ""
    Write-Host "Uploading <go.pdf,goUpdates.pdf,go.ps1> to the server at cyberaudittool.c1.biz port 221" -ForegroundColor Green
    Write-Host "You will need to provide password for the specified user" -ForegroundColor Yellow
    Write-Host "Password hint: simba..." -ForegroundColor blue
    Write-Host ""
    try {
        Get-SFTPSession | ForEach {Remove-SFTPSession $_.SessionId}
        $password = "blackcat2020" | ConvertTo-SecureString -AsPlainText -Force
        $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "3347985_cyber",$password
        $SftpSess = New-SFTPSession -ComputerName cyberaudittool.c1.biz -Port 221 -Credential $credential -Verbose
        Set-SFTPFile -SessionId $SftpSess.SessionId -LocalFile "$PSScriptRoot\Downloads\go.ps1" -RemotePath "/cyberaudittool.c1.biz/" -Overwrite
        Set-SFTPFile -SessionId $SftpSess.SessionId -LocalFile "$PSScriptRoot\Downloads\go.pdf" -RemotePath "/cyberaudittool.c1.biz/" -Overwrite
        Set-SFTPFile -SessionId $SftpSess.SessionId -LocalFile "$PSScriptRoot\Downloads\goUpdate.pdf" -RemotePath "/cyberaudittool.c1.biz/" -Overwrite
    }
    catch {
       Write-Host "[Failed] Problem with connection or password is not correct, please try again" -ForegroundColor Red
       break
   }
   Write-Host "[Success] Files were uploaded to server cyberaudittool.c1.biz" -ForegroundColor Green
}

