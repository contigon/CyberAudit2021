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
$Host.UI.RawUI.WindowTitle = "Cyber Audit Tool 2020 - Licenses"


$input = Read-Host "Press [Enter] to install licenses or [C] to get help on creating the license from file"
if ($input -eq "C") {
    #Encrypt the license file to base64
    function encFile ($infile) {
        $Content = Get-Content -Path $infile -Encoding Byte
        $Base64 = [System.Convert]::ToBase64String($Content)
        $Base64 
        }
     Write-Host "Select the file you want to encrypt"
     Write-Host "You need to edit the $PSScriptRoot\CyberLicenses.ps1 file and use the yellow encryption text as key value"
     Write-Host "the key is also in your clipboard so you can paste it (Ctrl+V) into the script"
     Write-Host "----------------------------------------------------------------------------------------"
     $filePath = Get-FileName
     $key = encFile($filePath)
     write-host $key -ForegroundColor Yellow
     Set-Clipboard -Value $key
     Write-Host "----------------------------------------------------------------------------------------"
} 
else
{
    #create the azscan key file in the azscan3 folder
    $azscanfolder = scoop prefix azscan3
    if (Test-Path -Path $azscanfolder -PathType Any)
    {
        $AZScanKey = "aFpMS0NoVGVDM29oM0w4QjBIOENkazVMOG40WjBDVThrY1hWXTJjZ29SNGJzSTReWllQM0Y2T3U4TzVkWkU4aDlPSDZmWGw0XTFKNGhCbVkNCmtfUDddNko+SjE0d0paMjk7STNoMWsxZnA0SFBvWUI5XnBxOF40X
        FYzMl5PMEkzbjN1OU4wXFgyaDFdYEFjMl9VTTVnMWw2WjFcMnVvM2xZDQpqXDBvQ0tHNVRcMEY3YksxcjJUcmFcc3EwbVBRMWEyXlkyZTVnNmcxYTFqOW85ZDBre31XVzZmNVFARlY5TDdoXmczRjRiZTNKNEQyRG
        0yQQ0KZVpjN140VElQNE1Lc0Y1cTJgNUs1dDBcajJVMkR1MFQ3QW9qNmFFbTc4SzZOM0k0dTFIclwwQjlxMnVnM0pQRUBzSWtTNGFwbFo4YDBoMlENCnNgMFMyMDA1NlcwbXI4T2M0al1eOEwxXVJjYTJpYmZDTmE
        4XEhIQWI2XzdqZ01aRDNqMVM0dTFuMHEzSjZmOF1icVU5c1c5TTlINFYybjFTDQpkXDZuaVlXUlRQNTU1PTU1JS0lOWw5YjZSN2ZxNF83YjJwMGM4YVExVz01LSAxOm8gJD02Y0s0cTlKNFowUWdsOXNtbVlUQ0E/
        QnIxX2w0TA0KZVprN1dsME9UM2E0WGM2bGtKMlw2SjhkMWk0RzZWe30hJDZla1BON2I4U3M5QThPZ2QyXXMwYVJOOGIxUUYzQjJOMUlzMlg3ZzVfbWc4clENCm5iMUY3QTZkRlwxbzRwWWVPbTBPV1dXV0c1bjdzW
        jZxY0tmN0o2YjdhOHFxOF40XFYzUzZvOEM1aEI5RzVlUTFiNmxgOGZrZ3BnOWs2YHJBDQpmWlM1dDdtZzZoMmw1YzVpOEoxczk1NTU9NTUlLSU3SmcyYGA5ZXU3RjlcMUJkN1Q3aXAwUTVDY1hYRVY3XTBIQ0UwRD
        FRUmQySThJXjNwVQ0KS19VXEdxSmtCY05mRmdRZkVgQmtMbUtmUlxCaVhfT21HblBmSXBXcFNjVmZRclBoUV5OckJvUlxCbEtsSV5JYVVfWWBJcEheSG9ZXVpqRXINCg=="
        $Content = [System.Convert]::FromBase64String($AZScanKey)
        Set-Content -Path $azscanfolder\AZScanKey.dat -Value $Content -Encoding Byte
        Write-Host "azscan license file was created successfully" -ForegroundColor Green
    }

    else {
        Write-Host "azscan folder was not found, please install it before assigning license" -ForegroundColor Green
    }
}