<#	
	.NOTES
	===========================================================================
	 MOdified on:   10/03/2020 1:11 PM
	 MOdified by:   Omerf
	 Organization: 	Israel Cyber Directorate
	 Filename:     	CyberCreateRunecastRole
	===========================================================================
	.DESCRIPTION
		Cyber Audit Tool - Set Runecast Roles
    
    original file : https://raw.githubusercontent.com/Runecast/public/master/PowerCLI/createRunecastRole.ps1
#>

$Host.UI.RawUI.WindowTitle = "Cyber Audit Tool 2020 - Runecast"

#User created in the vCenter
$UserName = Read-Host "Please input the user you created for this task (eg. CyberAudit)"

#Runecast role that will be created in the vCenters
Write-Host "We will create a [runecastrole] new role in the vCenters"
$runecastRoleName = Read-Host "Choose a role name (eg. CyberRole)"

#Input the names of all vCenter Servers
$vCenters = [System.Collections.ArrayList]@('vc1.company.local')
$vCenters.Remove("vc1.company.local")
$count = Read-host "input the number Vcenter Servers you have (eg. 4)"
for ($i=1; $i -le [int]$count;$i++){
    $ordinal = $i | OrdinalNumber
    $vCenterName = Read-host "FQDN of the $ordinal vcenter (eq. vCenter$i.$env:USERDNSDOMAIN) "
    $null = $vCenters.Add($vCenterName)
    }

###End of variables section

#Get Credentials
Write-Host "Assuming same credentials are valid across all $count vCenter Servers"
Write-Host "The User name in the next input should be as such: Administrator@vCenter1.$env:USERDNSDOMAIN"
$creds = Get-Credential

#####Do not edit beyond here#####
#Runecast role definition as per the user guide
$privileges = @(
    "Global.Settings"
    "Host.Config.NetService"
    "Host.Config.AdvancedConfig"
    "Host.Config.Settings"
    "Host.Config.Firmware"
    "Host.Cim.CimInteraction"
    "VirtualMachine.Config.AdvancedConfig"
    "Extension.Register"
    "Extension.Update"
)
#End of Runecast role definition

foreach ($vc in $vCenters) {
    #Connect to vCenter
    Write-Host "Connecting to vCenter $vc"
    $vcConnection = Connect-VIServer $vc -Credential $creds

    if ($vcConnection) {
        $rcRole = $null
        Write-Host "Creating new role:  $runecastRoleName"
        $rcRole = New-VIRole -Name $runecastRoleName -Privilege (Get-VIPrivilege -id $privileges) -ErrorAction SilentlyContinue
        if ($rcRole) {
            Write-Host "$runecastRoleName role created succesfully on vCenter $vc" -ForegroundColor Green
        } else {
            Write-Host "Error while creating $runecastRoleName role on vCenter $vc" -ForegroundColor Red
        }

        #Disconnect from vCenter
        Write-Host "Disconnecting from vCenter $vc"
        Disconnect-VIServer $vcConnection -Confirm:$false
    } else {
        Write-Host "Unable to connect to vCenter $vc" -ForegroundColor Red
    }  
}

#Assigning the Role to the user
foreach ($vc in $vCenters) {
    #Connect to vCenter
    Write-Host "Connecting to vCenter $vc"
    $vcConnection = Connect-VIServer $vc -Credential $creds

    if ($vcConnection) {
        $rcRole = $null
        Write-Host "Creating new role:  $runecastRoleName"
        $rootFolder = Get-Folder -NoRecursion
        $rcRole = New-VIPermission -Entity $rootFolder -Principal $vc\$UserName -Role $runecastRoleName -Propagate:$true
        if ($rcRole) {
            Write-Host "$runecastRoleName role was assigned to $vc\$UserName on vCenter $vc" -ForegroundColor Green
        } else {
            Write-Host "Error while assigning $runecastRoleName role to $vc\$UserName on vCenter $vc" -ForegroundColor Red
        }

        #Disconnect from vCenter
        Write-Host "Disconnecting from vCenter $vc"
        Disconnect-VIServer $vcConnection -Confirm:$false
    } else {
        Write-Host "Unable to connect to vCenter $vc" -ForegroundColor Red
    }  
}
