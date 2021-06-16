<#	
	.NOTES
	===========================================================================
	 Created on:   	2/24/2020 1:11 PM
	 Created by:   	Omerf
	 Organization: 	Israel Cyber Directorate
	 Filename:     	CyberLicenses
	===========================================================================
	.DESCRIPTION
		Cyber Audit Tool - Licenses
#>

Import-Module $PSScriptRoot\CyberFunctions.psm1

<#
    Returns file content encripted to base64
    $infile - the file we want to convert its content
#>
function encFile ($infile) {
    $Content = Get-Content -Path $infile -Encoding Byte
    $Base64 = [System.Convert]::ToBase64String($Content)
    $Base64 
}

$runningScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "Cyber Audit Tool 2021 [$runningScriptName]"

$CATLicensesFolder = scoop prefix CATLicenses                       # Holds the path to the directory that includes the CATLicenses app

$keyFiles = Get-ChildItem -Path $CATLicensesFolder -Filter "*.enc"  # Get the encripted files which contains the licenses

if ($keyFiles.count -gt 0) {
    Write-Host "These are the key files you have:"
    for ($i=0;$i -lt $keyFiles.Count;$i++){Write-Host ($i+1) - $keyFiles[$i].basename}
    $input = Read-Host "Press [I] to install all key files or [C] to create the protected key file"
}
else {
    Write-Host "There are no key files in $CATLicensesFolder"
    $input = Read-Host "[C] to create a protected key file or [Enter] to skip installing licenses"
}

if ($input -eq "C") {
     Write-Host "Select the key file you want to encrypt"
     $filePath = Get-FileName
     $fileName = Split-Path $filePath -Leaf
     $fileNoExtension =  (Split-Path $filePath -Leaf).Split(".")[0]
     $fileParent = Split-Path $filePath
     $key = encFile($filePath)                                     # Encrypt the license file to base64
     success "$filePath was encoded to base64 successfully"
     Write-Host "--------------------------------------------"
     Write-Host $key
     Write-Host "--------------------------------------------"
     $sPassword = Read-Host "Input password which will encrypt the base64 key (don't forget it)"
     if ($sPassword -eq "")
     {
        failed "Password is empty, please try again"

     }
     Write-Host "The password is: $sPassword" -BackgroundColor Yellow -ForegroundColor Black
     $sInput = $key
     [byte[]]$aEncryptedMessage=$null
     if (fAESEncrypt ([system.text.encoding]::ASCII.GetBytes($sInput)) ([system.text.encoding]::ASCII.GetBytes($sPassword)) ([ref]$aEncryptedMessage) $aCustomSalt)
     {
        success "Key from $fileName is now password encrypted"
        Set-Content -Path "$CATLicensesFolder\$fileNoExtension.enc" -Value $aEncryptedMessage -Force
        Write-Host "We will now zip all key files,Don't forget to upload them to the download repozitory"
        $compress = @{
          Path = "$CATLicensesFolder\*.enc"
          CompressionLevel = "Fastest"
          DestinationPath = "$CATLicensesFolder\CATLicenses.zip"
        }
        $c = $compress['path']
        Write-Host "Files [$c] will be compressed now" -ForegroundColor Green
        Compress-Archive @compress -Force
        $null = Start-Process -PassThru explorer $CATLicensesFolder
        $null = Start-Process "https://github.com/contigon/Downloads/upload/master"
      }
      else 
      {
        failed "Could not encrypt the file, please figure out the problem and try again !"
      }
} 
elseif ($input -eq "I")
{
    #AZScan
    $azscanfolder = scoop prefix azscan3
    if (Test-Path -Path $azscanfolder -PathType Any)
    {
        #Decrypt and copy the AZScan key file to the AZScan application folder
        for ($i=0;$i -lt $keyFiles.Count;$i++)
        {
            if ($keyFiles[$i].basename -contains "AZScanKey")
            {
                success "AZScanKey.enc was found"
                $encryptedKey =  Get-Content -Path "$CATLicensesFolder\AZScanKey.enc"
                $sPassword = Read-Host "Input the password in order to decrypt [AZScan] licenses key"
                [byte[]]$aDecryptedMessage=$null
                if ((fAESDecrypt $encryptedKey ([system.text.encoding]::ASCII.GetBytes($sPassword)) ([ref]$aDecryptedMessage) $aCustomSalt) -like $false)
                {
                    failed ([System.Text.Encoding]::UTF8.GetString($aDecryptedMessage))
                }
                else
                {
                    $Content = [System.Convert]::FromBase64String(([System.Text.Encoding]::UTF8.GetString($aDecryptedMessage)))
                    #Write-Host $Content -ForegroundColor Yellow
                    Set-Content -Path $azscanfolder\AZScanKey.dat -Value $Content -Encoding Byte -Force
                    success "azscan license file was created successfully" -ForegroundColor Green
                    $null = start-Process -PassThru explorer $azscanfolder
                }
            }
        }
    }
    else {
        Write-Host "azscan folder was not found, please install it before assigning license" -ForegroundColor Green
    }
}
