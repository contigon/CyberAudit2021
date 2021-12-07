Import-Module $PSScriptRoot\CyberFunctions.psm1
$GBPAppPath = Invoke-Expression "scoop prefix getbadpasswords 6>&1"
if (!(Test-PAth $GBPAppPath)){
    Write-Host "Error: Get-BadPasswords is not installed properly"
    return
}
$ACQ = ACQ("GetBadPasswords")
$dnsroot =  (Get-ADDomain).dnsroot
$DistinguishedName = (Get-ADDomain).DistinguishedName
Write-Host "Changing default Domain config settings to $dnsroot and $DistinguishedName"
Copy-Item "$GBPAppPath\Get-bADpasswords.ps1" "$GBPAppPath\Get-bADpasswords.ps1.bak"
$domainConfig = Get-Content "$GBPAppPath\Get-bADpasswords.ps1"
$newConfig = (($domainConfig -replace "YourDomainName", $dnsroot) -replace 'DC=domain,DC=com', $DistinguishedName) -replace "Send-MailMessage","#Send-MailMessage"
$newConfig | Set-Content "$GBPAppPath\Get-bADpasswords.ps1"


Push-Location $GBPAppPath
.\Get-bADpasswords.ps1
Pop-Location
Copy-Item -Path "$GBPAppPath\Accessible\CSVs\" -Destination $ACQ -Recurse -Force
Read-Host "Press ENTER to continue"