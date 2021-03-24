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

. $PSScriptRoot\CyberFunctions.ps1
$runningScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "Cyber Audit Tool 2021 [$runningScriptName]"

[System.reflection.assembly]::LoadWithPartialName("System.Security")|out-null
[System.reflection.assembly]::LoadWithPartialName("System.IO")|out-null

function fAESEncrypt()
{
    Param(
        [Parameter(Mandatory=$true)][byte[]]$aBytesToBeEncrypted,
        [Parameter(Mandatory=$true)][byte[]]$aPasswordBytes,
        [Parameter(Mandatory=$true)][ref]$raEncryptedBytes,
        [Parameter(Mandatory=$false)][byte[]]$aCustomSalt
    )       
    [byte[]] $encryptedBytes = @()
    # Salt must have at least 8 Bytes!!
    # Encrypt and decrypt must use the same salt
    # Define your own Salt here
    [byte[]]$aSaltBytes = @(4,7,12,254,123,98,34,12,67,12,122,111) 
    if($aCustomSalt.Count -ge 1)
    {
        $aSaltBytes=$aCustomSalt
    }   
    [System.IO.MemoryStream] $oMemoryStream = new-object System.IO.MemoryStream
    [System.Security.Cryptography.RijndaelManaged] $oAES = new-object System.Security.Cryptography.RijndaelManaged
    $oAES.KeySize = 256;
    $oAES.BlockSize = 128;
    [System.Security.Cryptography.Rfc2898DeriveBytes] $oKey = new-object System.Security.Cryptography.Rfc2898DeriveBytes($aPasswordBytes, $aSaltBytes, 1000);
    $oAES.Key = $oKey.GetBytes($oAES.KeySize / 8);
    $oAES.IV = $oKey.GetBytes($oAES.BlockSize / 8);
    $oAES.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $oCryptoStream = new-object System.Security.Cryptography.CryptoStream($oMemoryStream, $oAES.CreateEncryptor(), [System.Security.Cryptography.CryptoStreamMode]::Write)
    try
    {
        $oCryptoStream.Write($aBytesToBeEncrypted, 0, $aBytesToBeEncrypted.Length);
        $oCryptoStream.Close();
    }
    catch [Exception]
    {
        $raEncryptedBytes.Value=[system.text.encoding]::ASCII.GetBytes("Error occured while encoding string. Salt or Password incorrect?")
        return $false
    }   
    $oEncryptedBytes = $oMemoryStream.ToArray();
    $raEncryptedBytes.Value=$oEncryptedBytes;
    return $true
}

function fAESDecrypt()
{
    Param(
        [Parameter(Mandatory=$true)][byte[]]$aBytesToDecrypt,
        [Parameter(Mandatory=$true)][byte[]]$aPasswordBytes,
        [Parameter(Mandatory=$true)][ref]$raDecryptedBytes,
        [Parameter(Mandatory=$false)][byte[]]$aCustomSalt
    )   
    [byte[]]$oDecryptedBytes = @();
    # Salt must have at least 8 Bytes!!
    # Encrypt and decrypt must use the same salt
    [byte[]]$aSaltBytes = @(4,7,12,254,123,98,34,12,67,12,122,111) 
    if($aCustomSalt.Count -ge 1)
    {
        $aSaltBytes=$aCustomSalt
    }
    [System.IO.MemoryStream] $oMemoryStream = new-object System.IO.MemoryStream
    [System.Security.Cryptography.RijndaelManaged] $oAES = new-object System.Security.Cryptography.RijndaelManaged
    $oAES.KeySize = 256;
    $oAES.BlockSize = 128;
    [System.Security.Cryptography.Rfc2898DeriveBytes] $oKey = new-object System.Security.Cryptography.Rfc2898DeriveBytes($aPasswordBytes, $aSaltBytes, 1000);
    $oAES.Key = $oKey.GetBytes($oAES.KeySize / 8);
    $oAES.IV = $oKey.GetBytes($oAES.BlockSize / 8);
    $oAES.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $oCryptoStream = new-object System.Security.Cryptography.CryptoStream($oMemoryStream, $oAES.CreateDecryptor(), [System.Security.Cryptography.CryptoStreamMode]::Write)
    try
    {
        $oCryptoStream.Write($aBytesToDecrypt, 0, $aBytesToDecrypt.Length)
        $oCryptoStream.Close()
    }
    catch [Exception]
    {
        $raDecryptedBytes.Value=[system.text.encoding]::ASCII.GetBytes("Error occured while decoding string. Salt or Password incorrect?")
        return $false
    }
    $oDecryptedBytes = $oMemoryStream.ToArray();
    $raDecryptedBytes.Value=$oDecryptedBytes
    return $true
}


$CustomSalt=@(1,2,3,4,5,6,7,9,10,11,254,253,252)

$input = Read-Host "Press [Enter] to install licenses or [C] to get help on creating the license from the original file"
if ($input -eq "C") {
    #Encrypt the license file to base64
    function encFile ($infile) {
        $Content = Get-Content -Path $infile -Encoding Byte
        $Base64 = [System.Convert]::ToBase64String($Content)
        $Base64 
        }
     Write-Host "Select the key file you want to encrypt"
     $filePath = Get-FileName
     $fileName = Split-Path $filePath -Leaf
     $fileParent = Split-Path $filePath
     $key = encFile($filePath)
     success "$filePath was encoded to base64 successfully"
     Write-Host "--------------------------------------------"
     Write-Host $key
     Write-Host "--------------------------------------------"
     $sPassword = Read-Host "Input password to password encrypt the base64 key (don't forget it)"
     Write-Host "The password is: $sPassword" -BackgroundColor Yellow -ForegroundColor Black
     $sInput = $key
     [byte[]]$aEncryptedMessage=$null
     fAESEncrypt ([system.text.encoding]::ASCII.GetBytes($sInput)) ([system.text.encoding]::ASCII.GetBytes($sPassword)) ([ref]$aEncryptedMessage) $aCustomSalt
     success "Key from $fileName is now password encrypted and can be uploaded safetly to any cloud storage"
     Set-Content -Path "$fileParent\$fileName.enc" -Value $aEncryptedMessage -Force
     $null = Start-Process -PassThru explorer $fileParent
} 
else
{
    #Decrypt and copy the azscan key file to the azscan3 application folder
    $azscanfolder = scoop prefix azscan3
    if (Test-Path -Path $azscanfolder -PathType Any)
    {
        $encryptedKey =  Get-Content -Path "$CATLicensesFolder\AZScanKey.enc"
        #Write-Host ([system.text.encoding]::ASCII.GetBytes($xxx))
        
        $sPassword = Read-Host "Input the password in order to decrypt [AZSCAN] licenses key"
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

    else {
        Write-Host "azscan folder was not found, please install it before assigning license" -ForegroundColor Green
    }
}