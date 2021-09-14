start-Transcript -path $PSScriptRoot\CyberAuditFDPhase.Log -Force -append

Import-Module $PSScriptRoot\CyberFunctions.psm1

function Goddi {
    # Clear-Host
    $help = @"

goddi
-----

goddi (go dump domain info) dumps Active Directory domain information.

Functionality:
- Extract Domain users
- Users in priveleged user groups (DA, EA, FA)
- Users with passwords not set to expire
- User accounts that have been locked or disabled
- Machine accounts with passwords older than 45 days
- Domain Computers
- Domain Controllers
- Sites and Subnets
- SPNs and includes csv flag if domain admin
- Trusted domain relationships
- Domain Groups
- Domain OUs
- Domain Account Policy
- Domain deligation users
- Domain GPOs
- Domain FSMO roles
- LAPS passwords
- GPP passwords. On Windows

In order for this script to succeed you need to have a user with 
Domain Admin permissions.
        
"@
    Write-Host $help
    $goddiPath = Get-Folder -Description "Choose the folder that contains goddi's files" -DisableNewFolder -ReturnCancelIfCanceled
    while (($goddiPath -ne "Cancel") -and (-not (Test-Path "$goddiPath\goddi-windows-amd64.exe"))) {
        Write-Host "Cannot find the file `"goddi-windows-amd64.exe`"" -ForegroundColor Red 
        $goddiPath = Get-Folder -Description "Choose the folder that contains goddi's files" -DisableNewFolder -ReturnCancelIfCanceled
    }
    if ($goddiPath -eq "Cancel") { 
        # TODO: Implement what to do if user canceling
        # Maybe interrupt the script
    }
    $ACQ = ACQ("goddi")
    Write-Host "You are running as user: $env:USERDNSDOMAIN\$env:USERNAME"
    $securePwd = Read-Host "Input a Domain Admin password" -AsSecureString
    $Password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePwd))
    while ([string]::IsNullOrEmpty($Password)) {
        Write-Host "Cannot continue without a password" -ForegroundColor Red
        $Password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePwd))
    }
    if ([string]::IsNullOrEmpty($env:USERDNSDOMAIN)) { 
        $xDNSDOMAIN = Read-Host "Enter the name of the domain full name (etc: domain.local)"
    } else { $xDNSDOMAIN = $env:USERDNSDOMAIN }
    $DC = ($env:LOGONSERVER).TrimStart("\\")
    $cmd = "goddi-windows-amd64.exe -username=`"$env:USERNAME`" -password=`"$Password`" -domain=`"$xDNSDOMAIN`" -dc=`"$DC`" -unsafe"
    Invoke-Expression $cmd
    Move-Item -Path $goddiPath\csv\* -Destination $ACQ -Force
    read-host "Press ENTER to continue"
    $null = start-Process -PassThru explorer $ACQ
    #>
    
}


function Sharphound {
    Clear-Host
    $help = @"

    Sharphound
    ----------
    
    Data Collector for the BloodHound Project

    Sharphound must be run from the context of a domain user, either directly 
    through a logon or through another method such as RUNAS.

    CollectionMethod :
    - Default - group membership, domain trust, local group, session, ACL, object property and SPN target collection
    - Group - group membership collection
    - LocalAdmin - local admin collection
    - RDP - Remote Desktop Users collection
    - DCOM - Distributed COM Users collection
    - PSRemote - Remote Management Users collection
    - GPOLocalGroup - local admin collection using Group Policy Objects
    - Session - session collection
    - ComputerOnly - local admin, RDP, DCOM and session collection
    - LoggedOn - privileged session collection (requires admin rights on target systems)
    - Trusts - domain trust enumeration
    - ACL - collection of ACLs
    - Container - collection of Containers

    In order for this script to succeed you need to have a user with 
    Domain Admin permissions.
            
"@
    Write-Host $help
    $ACQ = ACQ("Sharphound")
    Import-Module $appsDir\sharphound\current\SharpHound.ps1
    Invoke-BloodHound -CollectionMethod All, GPOLocalGroup, LoggedOn -OutputDirectory $ACQ
    $MaXLoop = read-host "Choose Maximum loop time for session collecting task (eg. 30m)"
    Invoke-BloodHound -CollectionMethod SessionLoop -MaxLoopTime $MaXLoop -OutputDirectory $ACQ
    Invoke-BloodHound -SearchForeset -CollectionMethod All, GPOLocalGroup, LoggedOn -OutputDirectory $ACQ
    read-host "Press ENTER to continue"
    $null = start-Process -PassThru explorer $ACQ    
}


function NTDSAquire {
    Clear-Host
    $help = @"

NTDS and SYSTEM hive remote aquisition
--------------------------------------

This script will try to connect to $DC Domain controller and create a remote backup of the
ntds.dit database, SYSTEM hive and SYSVOL, and then copies the files to the aquisition folder.

In order for this script to succeed you need to have domain administrative permissions.

Note: This script supports AD running on Windows Servers 2012 and up,
      on windows 2003/2008 we will show the manual instructions. 
        
"@
    Write-Host $help
    $ACQ = ACQ("NTDS")
    $winVer = Invoke-Command -ComputerName $DC -ScriptBlock { (Get-WmiObject -class Win32_OperatingSystem).Caption } -credential $cred
    if ($winVer.contains("2003") -or $winVer.contains("2008")) {
        Write-Host "The domain server is " $winVer -ForegroundColor Red
        $block = @"

Below window 2012 we cant backup the files remotely, 
you will need to do it locally on the Domain Controller
run these steps from elevated CMD:
--------------------------
1. ntdsutil
2. activate instance ntds
3. ifm
4. create sysvol full C:\ntdsdump
5. quit
6. quit
--------------------------
when finished please copy the c:\ntdsdump directory to the Aquisition folder (NTDS)

"@
        Write-Host $block -ForegroundColor Red
    } else {
        $cmd = 'Get-Date -Format "yyyyMMdd-HHmm"'
        $currentTime = Invoke-Expression $cmd
        Write-Host "Please wait untill the backup process is completed" -ForegroundColor Green
        remove-item $env:LOGONSERVER\c$\ntdsdump -Recurse -ErrorAction SilentlyContinue
        winrs -r:$DC ntdsutil "ac i ntds" "ifm" "create sysvol full c:\ntdsdump\$currentTime" q q
        Copy-Item -Path $env:LOGONSERVER\c$\ntdsdump\$currentTime -Destination $ACQ\$currentTime -Recurse -Force
    }
    $userInput = read-host "Press ENTER to continue, or type any latter to open aquisition folder"
    if ($userInput -match '\w') {
        $null = start-Process -PassThru explorer $ACQ\$currentTime
    }
    
}

function NTDSAuditTool {
    Clear-Host
    $help = @"
    
    hash dumping
    ------------

    Process NTDS/SYSTEM files and export pwdump/ophcrack files using NtdsAudit and
    DSINternals tools.

    NtdsAudit is an application to assist in auditing Active Directory databases,        
    and provides some useful statistics relating to accounts and passwords.

    DSinternals is a Directory Services Internals PowerShell Module and Framework.
    we will use the Get-ADDBAccount function retrieve accounts from an Active Directory database file
    and dump the users password hashes to Ophcrack, HashcatNT, HashcatLM, JohnNT and JohnLM formats.

    Both tools requires the ntds.dit Active Directory database, and optionally the 
    SYSTEM registry hive if dumping password hashes

"@
    write-host $help
    $ACQ = ACQA("NTDS")
    Get-ChildItem -Path $ACQ -Recurse -File | Move-Item -Destination $ACQ
    #NtdsAudit $ACQ\ntds.dit -s $ACQ\SYSTEM  -p  $ACQ\pwdump-with-history.txt -u  $ACQ\user-dump.csv --debug --history-hashes
    NtdsAudit $ACQ\ntds.dit -s $ACQ\SYSTEM  -p  $ACQ\pwdump.txt -u  $ACQ\user-dump.csv --debug
    Import-Module DSInternals
    $bk = Get-BootKey -SystemHivePath $ACQ\SYSTEM
    #$fileFormat = @("Ophcrack","HashcatNT","HashcatLM","JohnNT","JohnLM")
    $fileFormat = @("Ophcrack")
    foreach ($f in $fileFormat) {
        Write-Host "[Success] Exporting hashes to $f format" -ForegroundColor Green
        Get-ADDBAccount -All -DBPath $ACQ\ntds.dit -BootKey $bk | Format-Custom -View $f | Out-File $ACQ\hashes-$f.txt -Encoding ASCII
    }
    
    Success "Creating the DomainStatistics.txt report from CyberAnalyzersPhase.Log"
    Select-String "Account stats for:" $ACQLog\CyberAnalyzersPhase.Log -Context 0, 20 | ForEach-Object { 
        $_.context.PreContext + $_.line + $_.Context.PostContext
    } | Out-File $ACQ\DomainStatistics.txt


    Write-Host "Searching for installed Microsoft Excel"
    $excelVer = Get-WmiObject win32_product | Where-Object { $_.Name -match "Excel" } | Select-Object Name, Version
    if ($excelVer) {
        success $excelVer[0].name "is already installed"
        if (Test-Path -Path "$ACQ\user-dump.csv") {
            Success "Generating the statistics excel file"
            $ScriptToRun = $PSScriptRoot + "\CyberUserDumpStatistics.ps1"
            &$ScriptToRun
        } else {
            Failed "Check that user-dump.csv is located in the $ACQ folder and try again"
            Start-Process iexplore $ACQ
        }
    } else {
        Write-Host "[Failure] Please install Microsoft Excel before continuing running this analysis" -ForegroundColor Red
        read-host "�Press [Enter] if you installed Excel (or Ctrl + c to quit)"�
    }
    
    read-host "�Press ENTER to continue"�
    $null = start-Process -PassThru explorer $ACQ
}
Function ACQA {
    Param ($dir)
    $ACQdir = ("$AcqABaseFolder\$dir").Replace("//", "/")
    if (Test-Path -Path $ACQdir) {
        Write-Host "[Note] $ACQdir folder already exsits, this will not affect the process" -ForegroundColor Gray
    } else {
        $ACQdir = New-Item -Path $AcqABaseFolder -Name $dir -ItemType "directory" -Force
        write-host "$ACQdir was created successfuly" -ForegroundColor Green
    }
    Return $ACQdir
}

stop-Transcript | out-null
