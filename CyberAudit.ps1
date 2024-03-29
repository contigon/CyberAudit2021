﻿<#	
	.NOTES
	===========================================================================
	 Created on:   	2/24/2020 1:11 PM
	 Created by:   	Omerf
	 Organization: 	Israel Cyber Directorate
	 Filename:     	CyberMenu
	===========================================================================
	.DESCRIPTION
		Cyber Audit Tool - Audit
#>
#requires -RunAsAdministrator
#Requires -Version 5.1
#------------------- Executing a script which checks the filtering quuality of the configured DNS -------------------#
function DNSTests {
    Clear-Host
    .\CyberMaliciousDNSTest.ps1
}
#--------------------------------------------------------------------------------------------------------------------#
#region Masscan

#-------------------                    Masscan related functions                    --------------------------------#

function AskBanners {
    $ans = Read-Host "would you like to add banners check? [y/n]"
    if ($ans -eq 'y') {
        return $true
    }
    return $false
}

function planCustomScan {
    # The next process of asking the user for inputs for the tool
    # Those inpuuts will be concatenated into masscan apply command
    $targets = Read-Host "Type target IPs or subnets to scan:"
    $ports = Read-Host "Please type ports or range of ports you wish to scan:"
    $rate = Read-Host "Specify the desired packet sending rate (packets/second):"
    $isExcludeFile = Read-Host "Do you want to use an excluding file? [y/n]:"
    $optionalArgs = Read-Host "If you wish to insert more arguments for masscan command, do it now.`nTo `
    finish constructing and execute the inserted, hit [Enter] button: "
    $excludeFile = $null
    if ($isExcludeFile -eq 'y') {
        $excludeFile = Read-Host "Insert the file path or hit [enter] to use the default file: "
        if ($excludeFile.Length -gt 2) {
            $excludeFile = "--excludefile " + $excludeFile
        } else {
            $excludeFile = "--excludefile exclude.txt"
        }
    } else {
        $excludeFile = ''
    }
    $confFileName = $null
    $isWishSave = Read-Host "would you like to save your constructed scanning plan? [y/n]"
    if ($isWishSave -eq "y") {
        $confFileName = Read-Host "Give your config file a name (without the extension type): "
    }
    $massCommand = "masscan.exe " + $targets + " -p" + $ports + " --rate " + $rate + " " + $excludeFile
    if ($optionalArgs.Length -gt 2) {
        $massCommand = $massCommand + " " + $optionalArgs
    }
    $isBanners = AskBanners
    $sourceIP = $null
    if ($isBanners) {
        $sourceIP = Read-Host "Enter local subnet ubused IP address: "
        $massCommand = $massCommand + "--banners --source-ip $sourceIP"
    }
    # saving the scan configuration for future run
    if ($confFileName) {
        $concatConfName = "$confFileName" + "Conf.txt"
        Write-Host "Saving configuration to $PSScriptRoot/$confFileName"
        $massCommand = $massCommand + " --echo > $concatConfName"
        Invoke-Expression $massCommand
        
    }
    # running scan by gathered arguments
    Write-Host "Running the scan..."
    $massCommand = $massCommand + " > results.txt"
    return $massCommand
}

function scanWebServers {
    # transmission rate - packets per second
    $rate = "1000000" 
    # holds the nets to scan
    $nets = Read-Host "Enter the subnets or IP addresses to scan [x.y.z.w/s] with spaces between them: "
    $query = "masscan.exe $nets -p80,443,8080 --rate $rate"
    $isBanners = AskBanners
    $sourceIP = $null
    if ($isBanners) {
        $sourceIP = Read-Host "Enter local subnet ubused IP address: "
        $query = $query + "--banners --source-ip $sourceIP"
    }
    return $query
}

function scanTopN {
    $N = Read-Host "Specify the N for top N number of the most common ports to scan"
    # transmission rate - packets per second
    $rate = "1000000" 
    # holds the nets to scan
    $nets = Read-Host "Enter the subnets or IP addresses to scan [x.y.z.w/s] with spaces between them: "
    $query = "masscan.exe $nets --top-ports $N --rate $rate"
    $isBanners = AskBanners
    $sourceIP = $null
    if ($isBanners) {
        $sourceIP = Read-Host "Enter local subnet ubused IP address: "
        $query = $query + "--banners --source-ip $sourceIP"
    }
    return $query
}

function scanAllPorts {
    # transmission rate - packets per second
    $rate = "1000000" 
    # holds the nets to scan
    $nets = Read-Host "Enter the subnets or IP addresses to scan [x.y.z.w/s] with spaces between them: "
    $query = "masscan.exe $nets -p0-65535 --rate $rate"
    $isBanners = AskBanners
    $sourceIP = $null
    if ($isBanners) {
        $sourceIP = Read-Host "Enter local subnet ubused IP address: "
        $query = $query + "--banners --source-ip $sourceIP"
    }
    return $query
}

function scanBroadcast {
    # transmission rate - packets per second
    $rate = "1000000"
    # holds the nets to scan
    $nets = "0.0.0.0/0"
    $exludedFile = Read-Host "Type here a file contains nets to exclude your scan to avoid risky results:`nIf `
    your'e not sure what you're doing, please hit ctrl^C to exit and avoiding scan unwanted IPs over the INTERNET!!"
    $ports = Read-Host "Type the port(s) you would like to scan in the wide internet"
    $query = "masscan.exe $nets -p$ports --rate $rate --excludefile $exludedFile"
    $isBanners = AskBanners
    $sourceIP = $null
    if ($isBanners) {
        $sourceIP = Read-Host "Enter local subnet ubused IP address: "
        $query = $query + "--banners --source-ip $sourceIP"
    }
    return $query
}

function preconfigUserPlan {
    Write-Host "The following are the saved configuration files we found:"
    $confFiles = Get-ChildItem -Path $PSScriptRoot -Filter "*Conf.txt"  # Get the text files which contains preset configurations
    for ($i = 0; $i -lt $confFiles.Count; $i++) { Write-Host ($i + 1) - $confFiles[$i].basename }
    $selectedConFile = Read-Host "Choose a file number: "
    $selIndex = $selectedConFile - 1
    $conFileName = $confFiles[$selIndex].FullName
    $query = "masscan.exe -c $conFileName"
    return $query
}

function ScanPresetsMenu {
    $help = @"
Choose a preset plan from the following:
----------------------------------------
1. Scan a network for Web Ports.
2. Scan a network for the Top 10 ports.
3. Scan a network for All Ports.
4. Scan everywhere (internet broadcast) for a specific port(s) - `nBe carefull and avoid scanning unwanted hosts by specifying excluded file!
5. Choose a preconfigured plan of yours.
"@
    Write-Host $help
    $selection = Read-Host "Type a number from the options above: "
    switch ($selection) {
        1 { return scanWebServers }
        2 { return scanTopN }
        3 { return scanAllPorts }
        4 { return scanBroadcast }
        5 { return preconfigUserPlan }
        Default { write-host "You typed invalid character. exit..." }
    }
}

function createExcludedHostFile {
    # IP addresses to ignore received by the user
    $IPsStr = Read-Host "Please enter the addresses you don't want to scan: "
    $IPArray = $IPsStr.Split(" ")
    # read file name
    $excludeFileName = Read-Host "Name the new file (without type extension): "
    $excFileNameToSave = $excludeFileName + "Exc.txt"
    foreach ($ip in $IPArray) {
        $ip | Out-File -Append -FilePath $excFileNameToSave
    }
    Write-Host "The new excluding file is saved as $excFileNameToSave"
}

function Masscan {
    Clear-Host
    $help = @"
MASSCAN: Mass IP port scanner
-----------------------------
This is an Internet-scale port scanner.
Its usage (parameters, output) is similar to nmap, the most famous port scanner.
Internally, it uses asynchronous transmission.
Its flexible and allowing arbitrary port and address ranges.

The following questions is about to guide you in the process of constructing the scanning plan:
"@
    Write-Host $help
    $masscanPath = Invoke-Expression ("scoop prefix masscan")
    $currentPWDObj = Get-Location
    $currPWDString = $currentPWDObj.path 
    $cdcmd = "cd $masscanPath"
    Invoke-Expression $cdcmd

    $mainMenu = @"
Set your scanning plan:
-----------------------
1. Run pre-configured scanning plan.
2. Construct a new scan.
3. Create excluded host file.
"@
    Write-Host $mainMenu
    $selection = Read-Host "Select your chosen plan from the above numbers: "
    # holds the constructed command to execute
    $queryCmd = $null
    switch ($selection) {
        # Let the user choosing between run from a saved config file or a popular well known configuration
        1 { $queryCmd = ScanPresetsMenu }
        # Constructs a plan to scan from arguments received by the user
        2 { $queryCmd = planCustomScan }
        # creates a file with list of IP addresses the user would like to ignore during the scan
        3 { $queryCmd = createExcludedHostFile }
        Default { write-host "You typed invalid character. exit..." }
    }
    if ($queryCmd) {
        Write-Host "Executing the command: $queryCmd"
        Invoke-Expression $queryCmd
    }
    #restore location before the application run
    $cmd = "cd " + $currPWDString
    Invoke-Expression $cmd
    Write-Host "The results are now saved in 'results.txt'"
}
#-------------------------------------------------------------------------------------------------------------------------------#
#endregion Masscan

function Domain {
    Clear-Host
    $help = @"

Join/Disconnect machine to/from a Domain
----------------------------------------

In order for the audit tools to collect all information required,
you need that the machine to the Domain of your network.
 
This script will help you Join/Disconnect the machine to/from a Domain.

In order for this script to succeed you need to have domain administrative permissions.
        
"@
    Write-Host $help
    Write-Host "Checking if there are any network connections open, and deleting them"
    net use * /delete
    $CurrentDomain = (Get-WmiObject -Namespace root\cimv2 -Class Win32_ComputerSystem).Domain
    if (CheckMachineRole) {
        Write-Host "Your machine is part of $CurrentDomain"
        if (Test-ComputerSecureChannel -Server $DC) {
            Write-Host "[Success] Connected to domain server $DC using secure channel" -ForegroundColor Green
        } else {
            Write-Host "[Failure] Domain could not be contacted" -ForegroundColor Red
            $choose = Read-Host "Press [D] to disconnect from $CurrentDomain domain"
            if ($choose -eq "D") {
                $NeedRestart = (Remove-Computer -PassThru -Verbose -LocalCredential $cred).HasSucceeded
            }
        }
    } else {
        # TODO: Add feature to get the domain from the creds provided
        $domainFromCreds = split-path $cred.UserName
        $domain = Read-Host -Prompt "Enter Domain name to join the machine to (eg. cyber.gov.il)
If you want to use domain $domainFromCreds leave empty"
        if ([string]::IsNullOrWhiteSpace($domain)) { 
            $domain = $domainFromCreds
        }
        $NeedRestart = (Add-Computer -DomainName $domain -Credential $cred -PassThru).HasSucceeded
    }
    if ($NeedRestart) {        
        $restart = read-host "Press [R] to restart machine for settings to take effect (Enter to continue)"
        if ($restart -eq "R") {
            shutdown /r /f /c "Rebooting computer after Domain joining or disconnecting"
        }
    }
}

function TestDomain {
    Clear-Host
    $help = @"

    Test Domain Connections and Configuration
    -----------------------------------------

    In order for the audit tools to collect all information required,
    you need to be able to connect to the domain controllers and be able
    to execute remote commands on remote computers.
     
    This script will help you test connections and enable powershell remoting.

    In order for this script to succeed you need to have domain administrative permissions.

    If the script failes conncting to remote machines you will be able to enable remote 
    connections using a special tool called SolarWinds Remote Execution Enabler.
            
"@
    Write-Host $help
    write-host local Computer Name:  $env:COMPUTERNAME
    Write-Host User domain is: $env:USERDOMAIN
    Write-Host Dns domain is: $env:USERDNSDOMAIN
    Write-Host This Domain Controller name is: $DC
    Write-Host DNS root is: (Get-ADDomain).DNSRoot
    Test-ComputerSecureChannel -v
    Enable-PSRemoting -SkipNetworkProfileCheck -Force; Get-Item WSMan:\localhost\Client\TrustedHosts
    Test-WsMan $DC
    Invoke-Command -ComputerName $DC -ScriptBlock { Get-WmiObject -Class Win32_ComputerSystem } -credential $cred
    $inpYesNo = Read-Host "Press [Enter] if test was successfull or [N] to try a different way"
    Switch ($inpYesNo) {
        "N" {
            Write-Host "Trying to start remote winrm using psexec"
            psexec -accepteula $env:LOGONSERVER -s winrm.cmd quickconfig -q
            write-host "another way is to run SolarWinds Remote Execution Enabler for PowerShell tool"
            RemoteExecutionEnablerforPowerShell
        }
    }
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
        # remove-item $env:LOGONSERVER\c$\ntdsdump -Recurse -ErrorAction SilentlyContinue
        winrs -r:$DC ntdsutil "ac i ntds" "ifm" "create sysvol full c:\ntdsdump\$currentTime" q q
        Copy-Item -Path $env:LOGONSERVER\c$\ntdsdump\$currentTime -Destination $ACQ\$currentTime -Recurse -Force
        Add-ACLForRemoteFolder -Path "$env:LOGONSERVER\c$\ntdsdump\$currentTime"
        remove-item $env:LOGONSERVER\c$\ntdsdump\$currentTime -Recurse -ErrorAction SilentlyContinue
    }
    $userInput = read-host "Press ENTER to continue, or type any latter to open aquisition folder"
    if ($userInput -match '\w') {
        $null = start-Process -PassThru explorer $ACQ\$currentTime
    }
    
}

function CollectNetworkConfig {
    Clear-Host
    $help = @"

    Collect configuration and routing tables from network devices
    -------------------------------------------------------------
    
    1. In order to map the network devices we will launch Lantopolog tool
       which will automatically do the discovery based on SNMP protocol.

       Specify the ranges of the IP addresses for switch discovery:
       - 192.168.0.*   
       - 192.168.0.100-200 
       - 172.16.200-255.*

       In case of SNMPv3:
       Cisco switches are not typically configured for reading of all the Bridge-MIB information on a
       per-VLAN basis when using SNMPv3, you need to configure an SNMPv3 context as described here:
       http://www.switchportmapper.com/support-mapping-a-cisco-switch-using-snmpv3.htm

    2. Powershell script that collects configuration and routing tables from network devices.

        Devices supported: 
        - CISCO (IOS/ASA)
        - HP
        - H3C
        - Juniper
        - Enterasys
        - Fortigate

    3. You will need to fill an excell or json file with all the required details:
        - Device IP Address
        - SSH Port
        - User Name
        - Password
        - Vendor
 
    In order for this script to succeed you need to have a user with at SSH permissions
    on the network devices to collect configuration and routing tables.
            
"@
    Write-Host $help
    $ACQ = ACQ("Network")
    lantopolog
    $ScriptToRun = $PSScriptRoot + "\CyberCollectNetworkConfigV2.ps1"
    &$ScriptToRun
}

function PingCastle {
    Clear-Host
    $help = @"

    PIngCastle
    ----------
    
    Active Directory Security Maturity Self-Assessment, based on CMMI 
    (Carnegie Mellon university 5 maturity steps) where each step has 
    been adapted to the specificity of Active Directory. 

    In order for this script to succeed you need to have a user with 
    Domain Admin permissions.
            
"@
    Write-Host $help
    $ACQ = ACQ("PingCastle")
    $ScriptToRun = $PSScriptRoot + "\CyberPingCastle.ps1"
    &$ScriptToRun   
}

function Testimo {
    Clear-Host
    $help = @"

    Testimo
    -------
    
    PowerShell module for running health checks for Active Directory 
    (and later on any other server type) against a bunch of different tests.

    Tests are based on:
    - Active Directory CheckList
    - AD Health & Checkup
    - Best Practices

    In order for this script to succeed you need to have a user with 
    Domain Admin permissions.
            
"@
    Write-Host $help
    $ACQ = ACQ("Testimo")
    if (checkRsat) {
        import-module activedirectory ; Get-ADDomainController -Filter * | Select-Object Name, ipv4Address, OperatingSystem, site | Sort-Object -Property Name
        Invoke-Testimo  -ExcludeSources DCDiagnostics -ReportPath $ACQ\Testimo.html 
        $null = start-Process -PassThru explorer $ACQ
    }    
}

function Goddi {
    Clear-Host
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
    $cmd = "scoop prefix goddi"
    $goddiPath = Invoke-Expression $cmd
    $ACQ = ACQ("goddi")
    Write-Host "You are running as user: $env:USERDNSDOMAIN\$env:USERNAME"
    $Password = $cred.GetNetworkCredential().Password
    goddi-windows-amd64.exe -username="$env:USERNAME" -password="$Password" -domain="$env:USERDNSDOMAIN" -dc="$DC" -unsafe
    Move-Item -Path $goddiPath\csv\* -Destination $ACQ -Force
}
function BackupGPO {
    Clear-Host
    $help = @"

GPO
---

1- Backs up all the GPOs in a domain 
2- Back's up th SYSVOL folder
3- Run the CyberGPLinkReport.ps1 script to create csv with linked gpo's
4- This script will also collect the gpresult all computers and servers
   in order to know th active gpo's when using policyanalyzer

requirements:
In order for this script to succeed you need to have a user with 
Domain Admin permissions
        
"@
    Write-Host $help
    $ACQ = ACQ("GPO")
    $null = New-Item -Path "$ACQ\GPO" -ItemType Directory -Force
    $null = New-Item -Path "$ACQ\gpresult" -ItemType Directory -Force
    Backup-GPO -All -Path "$ACQ\GPO"
    $ScriptToRun = $PSScriptRoot + "\CyberGPLinkReport.ps1"
    &$ScriptToRun | Export-Csv -Path $ACQ\GPLinkReport.csv -NoTypeInformation
    $ADcomputers = Get-ADComputer -Filter * | Select-Object name
    $userInput = Read-Host "Press G to get all gpresults from all computers in the domain"
    if ($userInput -eq "G") {
        foreach ($comp in $ADcomputers) {
            if (Test-Connection -ComputerName $comp.name -Count 1 -TimeToLive 20 -ErrorAction Continue) {
                $compname = $comp.name
                $cmd = "gpresult /S $compname /R /V > $ACQ\gpresult\gpresult-$compname.txt"
                Invoke-Expression $cmd
            }
        }
    }
    $cmd = "robocopy $env:LOGONSERVER\sysvol\ $ACQ\sysvol\ /copyall /mir"
    Invoke-Expression $cmd    
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
    
}
function HostEnum {
    Clear-Host
    $help = @"

HostEnum
-------

A collection of Red Team focused powershell script to collect data during assesment.

Enumerated Information:

- OS Details, Hostname, Uptime, Installdate
- Installed Applications and Patches
- Network Adapter Configuration, Network Shares, Connections, Routing Table, DNS Cache
- Running Processes and Installed Services
- Interesting Registry Entries
- Local Users, Groups, Administrators
- Personal Security Product Status
- Interesting file locations and keyword searches via file indexing
- Interesting Windows Logs (User logins)
- Basic Domain enumeration (users, groups, trusts, domain controllers, account policy, SPNs)

In order for this script to succeed you need to have a user with 
Domain Admin permissions.
        
"@
    Write-Host $help
    $ACQ = ACQ("HostEnum")
    $enumPath = scoop prefix red-team-scripts
    Push-Location $enumPath
    Import-Module .\HostEnum.ps1
    Invoke-HostEnum -ALL -HTMLReport -Verbose
    Move-Item -Path *.html -Destination $ACQ
    Pop-Location
}

function Scuba {
    Clear-Host
    $ACQ = ACQ("Scuba")
    $help = @"

Scuba Database Vulnerability Scanner
------------------------------------
- Scan enterprise databases for vulnerabilities and misconfigurations
- Know the risks to your databases
- Get recommendations on how to mitigate identified issues

Note: Fix timezone issues when auditing mysql server,
      run these 2 commands from DOS terminal on the DB server:
      set @@global.time_zone=+00:00
      set @@session.time_zone='+00:00

"@
    write-host $help 
    $cmd = "Scuba"
    Invoke-Expression $cmd
    read-host "Wait untill auditing finished and Press [Enter] to save report"
    $ScubaDir = scoop prefix scuba-windows
    if (Get-Item -Path "$ScubaDir\Scuba App\production\AssessmentResults.js" -ErrorAction SilentlyContinue) {
        $serverAddress = Select-String -Path "$ScubaDir\Scuba App\production\AssessmentResults.js"  -pattern "serverAddress"
        $database = Select-String -Path "$ScubaDir\Scuba App\production\AssessmentResults.js"  -pattern "database"
        $a = $serverAddress -split "'"
        $b = $database -split "'"
        $fname = ($a[3] -split ":")[0] + "(" + $b[3] + ")"
        Compress-Archive -Path "$appsDir\scuba-windows\current\Scuba App\" -DestinationPath "$ACQ\$fname.zip" -Force
        success "exporting AssessmentResults.js to .csv" 
        SetPythonVersion "2"
        python .\Scuba2CSV.py "$ScubaDir\Scuba App\production\AssessmentResults.js"
        Rename-Item -Path "$ACQ\ScubaCSV.csv" -NewName "$ACQ\ScubaCSV-$fname.csv"
        $null = start-Process -PassThru explorer $ACQ
    } else {
        Write-Host "Could not find any Report, please check why and try again"
    }
    KillApp("javaw", "Scuba")
}

function Azscan {
    $ACQ = ACQ("azscan")
    $help = @"

azscan supprts auditing of Oracle Databases versions: 7,8,9,10gR1,10gR2,11g,12c
The steps includes running the [AZOracle.sql] script on the Oracle DB which outputs
a result file [OScan.fil] which needs to be imported back to the azscan tool which 
will run the tests and prepare a report with the results of the audit

"@
    Write-Host $help
    $userInput = Read-Host "Input [O] in order to audit ORACLE database (Or Enter to continue with other Platforms)"
    if ($userInput -eq "O") {
        $CopyToPath = Read-Host "Choose Path to Copy AZOracle.sql script to (eg. \\$DC\c$\Temp)"  
        if (Test-Path -Path $CopyToPath -PathType Any) {
            Copy-Item -Path $appsDir\azscan3\current\AZOracle.sql -Destination $CopyToPath
            $null = start-Process -PassThru explorer $CopyToPath
            Read-Host "Press [Enter] to copy OScan.fil from $CopyToPath to $ACQ"            
            Copy-Item -Path $CopyToPath\OScan.fil -Destination $ACQ
            $null = start-Process -PassThru explorer $ACQ
        } else {
            Write-Host "Could not connect to path $CopyToPath, Please check and try again" -ForegroundColor Red
        }
    }
    $cmd = "azscan3"
    Invoke-Expression $cmd
}

function Grouper2 {
    Clear-Host
    $help = @"

    Grouper2
    -------
    
    Help find security-related misconfigurations in Active Directory Group Policy.

    In order for this script to succeed you need to have a user with 
    Domain Admin permissions.
            
"@
    Write-Host $help
    $ACQ = ACQ("grouper2")
    $cmd = "grouper2.exe -g"
    Invoke-Expression $cmd
    $cmd = " grouper2.exe -f $ACQ\Report.html"
    Invoke-Expression $cmd
}

function Dumpert {
    Clear-Host
    $help = @"

Dumpert
-------

Outflank Dumpert is an LSASS memory dumper using direct system calls and API unhooking.

offline Decrypt the users NTLM hashes from Memdump using mimikatz.

https://outflank.nl/blog/2019/06/19/red-team-tactics-combining-direct-system-calls-and-srdi-to-bypass-av-edr/

Please use with care and do not execute on critical servers or Virtual machines !!!
        
"@
    Write-Host $help
    $ACQ = ACQ("Dumpert")
    $target = Read-Host "Input the Name or IP address of the windows machine you want to run this tool"
    $cmd = "Outflank-Dumpert.exe"
    Copy-Item -Path $appsDir\Outflank-Dumpert\current\Outflank-Dumpert.exe -Destination \\$target\c$\Windows\temp -Recurse -Force
    winrs -r:$target c:\Windows\temp\$cmd
    Copy-Item -Path $target\c$\WINDOWS\Temp\dumpert.dmp -Destination $ACQ -Recurse -Force
}
function Runecast {
    Clear-Host
    $ACQ = ACQ("Runecast")
    $help = @"

runecast Analyzer 
-----------------

Automates checks of infrastructure against Knowledge Base articles, Best Practices, HCL, and security standards.

Supported platforms:
- VMware vSphere/vSAN/NSX/Horizon
- Amazon Web Services IAM/EC2/VPC/S3

linux login: rcadmin/admin

web login:   rcuser/Runecast!

licence: You need to assign the runecast licence after connecting to the vsphere servers

Creating User in the vCenter and assigning the [Runecast] role:
---------------------------------------------------------------
1 - Automatically or Manually run the powershell script (https://github.com/Runecast/public/blob/master/PowerCLI/createRunecastRole.ps1)
2 - Log to the vCenter web interface (with user such as administrator@$env:USERDNSDOMAIN)"
3 - Single Sign On --> Users and Groups --> Add User --> (Create New user for Runecast Analyzer)
4 - Access Control --> Global Permissions --> Add Permission
5 - search for the user created in step 2 and assign the [Runecast] role 

[Optional] Syslog analysis !!! Be carefull as this can affect the server performance !!!
-------------------------------------------------------------------------------------
1 - ESXi Log Forwarding by clicking the help ring icon located to the right-hand side of the Host syslog settings section
in the Log Analysis tab, expand the section and click to download the PowerCLI script and Execute the script using PowerCLI
2 - VM Log Forwarding to Syslog Click the help ring icon located on the right side-hand of the
VM log settings section of the Log Analysis tab, expand the Scripted section and download 
the PowerCLI script and Execute the script using PowerCLI
3 - Perform either a vMotion or Power Cycle for each VM

"@
    Write-Host $help
    $userInput = Read-Host "Press [R] to run the Create Role Powershell script (or Enter to contine)"
    if ($userInput -eq "R") {
        $ScriptToRun = $PSScriptRoot + "\CyberCreateRunecastRole.ps1"
        &$ScriptToRun
    }
}
function Misc {
    Clear-Host
    $help = @"

Misc
----

Script that checks all sorts of misconfigurations and vulnerabilities.

Checks:

1. WSUS Updates over HTTP
2. 
3.
4.        
"@
    Write-Host $help
    $ACQ = ACQ("Misc")
    $ScriptToRun = $PSScriptRoot + "\CyberMisc.ps1"
    &$ScriptToRun
}
function SkyboxWin {
    Clear-Host
    $help = @"

skybox interface and routing collector
--------------------------------------

On some assets (usually firewalls), the access rules and routing rules are
controlled by different software. On Check Point firewalls, for example, firewall
software manages the access rules but the operating system controls interfaces
and routing.

This Script Collects interface and routing configuration
from every windows computer found in the domain.

Result:
Creates a folder for each machine found with 2 files
(ipconfig.txt and netstat.txt)

skybox task:
We recommend that you use an Import - Directory task to import the
configuration data; the files for each device must be in a separate subdirectory of
the specified directory (even if you are importing a single device)
                
"@
    Write-Host $help
    $ACQ = ACQ("IpconfigNetstat")
    $ADcomputers = Get-ADComputer -Filter * | Select-Object name
    foreach ($comp in $ADcomputers) {
        if ( (Test-WinRM -ComputerName $comp.name).status) {
            $compname = $comp.name
            success "Collecting interface and routing from: $compname"
            $null = New-Item -ItemType Directory -Path "$ACQ\$compname" -Force                
            $res = Invoke-command -COMPUTER $compname -ScriptBlock { ipconfig } -ErrorAction SilentlyContinue -ErrorVariable ResolutionError
            Out-File -InputObject ($res) -FilePath "$ACQ\$compname\ipconfig.txt" -Encoding ascii
            $res = Invoke-command -COMPUTER $compname -ScriptBlock { netstat -r } -ErrorAction SilentlyContinue -ErrorVariable ResolutionError
            Out-File -InputObject ($res) -FilePath "$ACQ\$compname\netstat.txt" -Encoding ascii
        }
    }  
}
function Nessus {
    Clear-Host
    $nessusPath = GetAppInstallPath("nessus")
    Push-Location $nessusPath
    $help = @"

Misc
----

Nessus Professional automates point-in-time assessments 
to help quickly identify and fix vulnerabilities and misconfigurations
including:
- software flaws
- OS missing patches
- malware
- Databases
- Network equipement
- Virtualization
- Cloud infrastructures
- Web Application

If you have problems scanning with nessus please try any of these solutions:
- If using windows Firewall please follow these instructions
  https://docs.tenable.com/nessus/Content/CredentialedChecksOnWindows.htm
- If using other Antimalware solutions such as Mcafee,TrendMicro,ESET,SYMANTEC
  Disable host IPS/IDS all workstations/servers or any other blocking techniques
- A Script that sets three registry keys and restarts a service to allow nessus 
  to scan, Open Powershell as Admin and run these commands:
    
  $NPF = scoop prefix NessusPreFlight
  cd $NPF
  . .\NPF.ps1
  Invoke-NPF -remote -target "MAchine Name or IP Address"
  when fininshed scanning run:
  Invoke-NPF -remoteclean -target "MAchine Name or IP address"
  
 In order to backup/restore audits,
 please run these commands from elevated powershell:

 net stop "Tenable Nessus"
 copy C:\ProgramData\Tenable\Nessus\nessus\backups\global-<yyyy-mm-dd>.db
 replace with 
 C:\ProgramData\Tenable\Nessus\nessus\global.db 

 More tips:
 https://astrix.co.uk/news/2019/11/26/nessus-professional-tips-and-tricks

 Note: If you recieve activation error please reactivate with the same serial

"@
    Write-Host $help
    $ACQ = ACQ("Nessus")
    <# $reg = Read-Host "Press [S] to register online or [O] for offline challenge (or Enter to continue)"
if ($reg -eq "S") 
{
    Start-Process .\nessuscli -ArgumentList "fetch --register XXXX-XXXX-XXXX-XXXX" -wait -NoNewWindow -PassThru
}
elseif ($reg -eq "O")
{
    Start-Process .\nessuscli -ArgumentList "fetch --challenge" -wait -NoNewWindow -PassThru
}
#>
    $null = Start-Process .\nessuscli -ArgumentList "fetch --code-in-use" -wait -NoNewWindow -PassThru
    Write-Host "Nessus users:"
    $null = Start-Process .\nessuscli -ArgumentList "lsuser" -wait -NoNewWindow -PassThru
    $null = Start-Process .\nessuscli -ArgumentList "update --all" -wait -NoNewWindow -PassThru
    Pop-Location
    Write-Host "Starting Internet Explorer in background..."
    $ie = New-Object -com InternetExplorer.Application
    $ie.visible = $true
    $uri = 'https://localhost:8834'
    $ie.navigate("$uri")
    while ($ie.ReadyState -ne 4) { start-sleep -m 100 }
    if ($ie.document.url -Match "invalidcert") {
        Write-Host "Trying to Bypass SSL Certificate error page..."
        $sslbypass = $ie.Document.getElementsByTagName("a") | where-object { $_.id -eq "overridelink" }
        $sslbypass.click()
    }
}
function Printers {
    Clear-Host
    $PretPath = scoop prefix PRET
    $help = @"

    Printers
    --------
    
    Searching for printers and print servers misconfigurations and vulnerabilities.

    Audit Steps
    -----------
    1. After searching for printers in the network, connect to the WEB interface
       and log in with default password for the printer (search in google for the password)
    2. Take screenshots of configuration of printer
    3. Use PRET (Printer Exploitation Toolkit) to check for 
       https://github.com/RUB-NDS/PRET
    
    Help Using PRET
    ---------------
    1. Open Powershell Command Line
    2. cd to folder $PretPath
    3. run the command will show help # python .\pret.py -h
    4. examples:
       # python .\pret.py -help status (this will show help on status command)
       # python <ip of printer> pjl (connect to printer using pjl mode, options are:ps,pjl,pcl)
    5. last command will open console to printer
       # display <message> - Set printers display message
       # info id - Provides the printer model number
       # restart - will restart the printer 
    6. printers such as hp lasejet uses PostScript we can capture and show all printed documents
       # python .\pret.py ps
       # start capture
       # capture list
    
    
    SHODAN Search for printers
    ------------------------------
    515 (LPR), 631 (IPP), and 9100 (JetDirect)

    port:9100 @pjl (wearch fo pjl printers)
    port:9100 laserjet 4250 (search fo ps printer)


    Links and Tutorials
    -------------------
    https://forums.hak5.org/topic/42138-packetsquirrel-printer-exploitation-toolkit/
    https://serverfault.com/questions/154650/find-printers-with-nmap
    https://seclists.org/fulldisclosure/2017/Jan/89
    http://download.support.xerox.com/pub/docs/4600/userdocs/any-os/en_GB/Phaser4600.4620_PDL_Guide.pdf
    https://courses.csail.mit.edu/6.857/2018/project/kritkorn-cattalyy-korrawat-suchanv-Printer.pdf
    https://www.bard-security.com/index.php/2019/01/18/if-you-pwn-a-printer-is-it-prwnting/#more-85
    https://www.nds.ruhr-uni-bochum.de/media/ei/arbeiten/2017/01/30/exploiting-printers.pdf
    https://www.bard-security.com/index.php/2019/01/25/the-problem-with-protecting-against-pret/
            
"@
    Write-Host $help
    $ACQ = ACQ("Printers")
    Write-Host "Getting list of print servers from domain server"
    $printservers = (Get-ADObject -LDAPFilter "(&(uncName=*)(objectCategory=printQueue))" -properties * | Sort-Object -Unique -Property servername).servername
    if ($printservers) {
        $printservers | Export-Csv $ACQ\PrintServers.csv
    }

    Write-Host "Getting list of installed printers from all registered domain computers"
    $computers = (Get-ADComputer -Filter *).name
    # Get printer information
    ForEach ($Printserver in $computers) { 
        $Printers = Get-WmiObject Win32_Printer -ComputerName $Printserver
        ForEach ($Printer in $Printers) {
            $Ports = Get-WmiObject Win32_TcpIpPrinterPort -Filter "name = '$($Printer.Portname)'" -ComputerName $Printserver
            if (($Printer.Name -notmatch "Microsoft") -and ($Printer.Name -notmatch "Adobe") -and ($Printer.Name -notlike "Fax*") -and ($Printer.Name -notmatch "FOXIT") -and ($Printer.Name -notmatch "OneNote")) {

                Write-Host  "Server: $Printserver | IP: $Ports | Printer:" $Printer.Name | Export-Csv $ACQ\DomainPrinters.csv -NoTypeInformation -Append
            }
        }
    }

    $NetworkSegments = (Get-NetNeighbor -State "Reachable").ipaddress | ForEach-Object { [IPAddress] (([IPAddress] $_).Address -band ([IPAddress] "255.255.255.0").Address) | Select-Object IPAddressToString } | Get-Unique
    $segmentIp = $NetworkSegments.IPAddressToString
    Write-Host "Network segements found: $segmentIp"
    $userInput = Read-Host "Input a network subnet (without IP mask) or [Enter] to scan $segmentIp/24 segment for printers"
    if ($userInput -eq "") {
        $userInput = "$segmentIp/24"
    }
    Write-Host "TCP Scanning for Printers... "
    nmap -p 515, 631, 9100 $userInput -oG $ACQ\PrintersTCPscan.txt
    $null = start-Process -PassThru explorer $ACQ

    Write-Host "UDP Scanning for Printers... "
    nmap -sU -p 161 $userInput -oG $ACQ\PrintersUDPscan.txt

    #snmpget -v 1 -O v -c public $ipaddress system.sysDescr.0

    SetPythonVersion "2"
    Push-Location $PretPath
    Write-Host "SMNP scanning for printers..."
    python .\pret.py
    $loop = {
        $userInput = Read-Host "Input ip address of a printer to try and hack or [Enter] to skip" 
        if ($userInput -ne "") {
            python .\pret.py $userInput pjl
            Start-Process powershell -ArgumentList ls
            $userInput = Read-Host "Press [T] to test More printers or [Enter] to finish"
            if ($userInput -eq "T") {
                &$loop
            }
        }
    }
    &$loop
    Pop-Location
}
function Sensitive {
    Clear-Host
    $help = @"

Sensitive
---------

Searching for sensitive documents and files in fileservers and shared folders.
This scripts uses the voidtools everything search fast search engine.

Checks:

1. Password protected files that might hold sensitve information
2. Documets that hold user names and passwords for different systems and accounts
3. Database backups of files with sensitive information (medical, finance, employees data and more)

"@
    Write-Host $help
    $ACQ = ACQ("Sensitive")
    $iniPath = scoop prefix everything
    $userInput = Read-Host "Input network share to scan for files (eg. \\FileServer\c$\Users)"
    $null = (Get-Content $iniPath\Everything.ini -Raw) -replace "\bfolders=(.*)", "folders=$userInput" | Set-Content -Path $iniPath\Everything.ini -Force
    $null = (Get-Content $iniPath\Everything.ini -Raw) -replace "\bntfs_volume_includes=1", "ntfs_volume_includes=0" | Set-Content -Path $iniPath\Everything.ini -Force
    $heb = "רשימה|סיסמה|סודי|סיסמאות|לקוחות|מסווג|רשימת|זהות|מטופלים|לקוחות|משכורות|חשבונות|כתובות|הנהלה"
    $eng = "secret|password|customer|patient|accounting|confidential"
    $ext = ".xls|.pdf|.doc|.zip|.7z|.rar|.txt"
    $cmd = "everything -first-instance -admin -reindex -s '$heb|$eng|$ext' "
    Invoke-Expression $cmd
}
function NetworkScan {
    Clear-Host
    $help = @"

PortScanner
----------

find open ports on network computers and retrieve versions of programs running on the detected ports

Netscanner
----------

multi-threaded ICMP, Port, IP, NetBIOS, ActiveDirectory and SNMP scanner 

- Scan features:
- ActiveDirectory
- Network neighbourhood
- Ping (ICMP)
- IP Address
- MAC Address (even across routers)
- MAC Vendor
- Device name
- Device domain/workgroup
- Logged user
- Operating system
- BIOS, Model and CPU
- System time and Up time
- Device description
- Type flags (SQL server, Domain controller etc)
- Remote device date and time
- TCP and UDP port scanning
- SNMP services
- Installed services on device
- Shared resources
- Sessions
- Open Files
- Running processes
- Terminal sessions
- Event Log
- Installed software
- SAM accounts
- WMI Queries
- Powerful WhoIs client

"@
    Write-Host $help
    $ACQ = ACQ("Netscanner")
    $cmd = "AdvancedPortScanner"
    Invoke-Expression $cmd
    $cmd = "netscanner64"
    Invoke-Expression $cmd
}

function skyboxWMIScanner {
    Clear-Host
    $help = @"

Skybox WMI collect and parse
----------------------------

Collect information from domain controlled windows machines such as:
- OS 
- installed Software
- hotfixes

After getting all machines listed in the domain ou=computers, the script connects to
each machine and collects the relevant information using wmi protocol.

Needs user with domain administration permissions on all machines.

The script can be downloaded from:
https://drive.google.com/open?id=1E-1ibwElj_JK2oRc6QbS5bwl5Aj0cs1F

wmi_collector.exe -s URI -b BASEDN -u USERNAME -p PASSWORD -o
-s URI >>> example : ldap://dc01.myorg.dom
-b BASEDN >>> example : dc=myorg,dc=dom
-u USERNAME >>> example : myuser@myorg.com
-p PASSWORD
-o >>> Output folder

"@
    Write-Host $help
    $ldapServer = (Get-ADDomain).pdcemulator
    $basedn = (Get-ADDomain).distinguishedname
    $domain = (Get-ADDomain).dnsroot
    $ACQ = ACQ("Skybox-WMI")
    $userName = Read-Host "Input user name with domain admin permissions"
    $userPassword = Read-Host "Input password for this user"
    $cmd = "wmi_collector -s 'ldap://$ldapServer' -b '$basedn' -u $username@$domain -p $userPassword -o $ACQ"
    success "Starting the collection phase"
    Invoke-Expression $cmd
    $null = New-Item -Path $ACQ -Name "parsedFiles" -ItemType Directory -Force
    $cmd = "wmi_parser -i $ACQ -o $ACQ\parsedFiles"
    success "Starting the parsing phase"
    Invoke-Expression $cmd
}
function SkyboxWsusCollection {
    Clear-Host
    $help = @"

    Skybox WSUS collection
    ----------------------

    Creates an XML file with a list of computers, patches, vulnerabilities and groups structure.

    Needs user with domain administration permissions on WSUS.

    Version depends on the DotNet version installed on the runnig machine:
      SkyboxWsusCollection4  | .Net 4
      SkyboxWsusCollection35 | .Net35
      SkyboxWsusCollection2  | .Net 2

   USAGE : SkyboxWsusCollection4.exe -t [local|remote] -h servername -s [true|false] -p portnumber -m [full|HostsOnly|MSxml]
    
    -t [local|remote]: run the collection from remote client or on the server localy
    -h servername:  in the case of remote collection the wsus server hostname or ip
    -s [true|false]: in the case of remote collection if to use SSL connection to the wsus server
    -l [full path file name] : filter by names
    -f [computername]: for debug only filter by computer name
    -r [true|false] : true - name full fqdn false hostname only
    -p port: in the case of remote collection if to use port number
    -o dir: output dir
    -q capacity: number of maximum hosts to collect
    -m [all|HostsOnly|MSxml|Debug] : output type all - computers,patch,vunrabilities and group in skybox IXML format.
    -n treeRootname: an option in the case of renaming the default wsus tree name - All computers
    
   Example:
    Remote collection: SkyboxWsusCollection.exe -t remote -h wsus.skybox.com -s false  -p 80 -q 30 -m all
    Local collection on the wsus server: SkyboxWsusCollection.exe -t local -m all -o c:\temp

"@
    Write-Host $help
    $WsusServer = Read-Host "Input the name of the WSUS Server"
    $ACQ = ACQ("Skybox-WSUS")
    $cmd = "SkyboxWsusCollection4 -t remote -h $WsusServer -s true -m all -o $ACQ"
    success "Starting the collection phase over SSL protocol"
    Invoke-Expression $cmd
}

function SkyboxCheckpintCollector {
    Clear-Host
    $help = @"

Skybox CheckPoint collector
----------------------------

Retrieval of Check Point R80.10 and lower management configuration data and convert it to Skybox import format.

Steps that will be executed:
1.Updating the collection_settings.xml file with relevant details:
user - User name for collection
pwd  - Password in clear text
url  - Management IP, e.g. 172.10.100.21

Optional field:
    output_file_prefix: A prefix can be added to the configuration filename
                        In the current example, the output filename will be offline_config_172.20.100.21.json
                        If left empty, the Tool creates 172.20.100.21.json.
2.running the Collect.bat script

"@
    Write-Host $help
    $ACQ = ACQ("Skybox-CheckPointcollector")
    $path = scoop prefix skyboxcheckpointcollector
    $path = $path + "\SkyboxCheckPointCollector"
    $userName = Read-Host "Input user name with firewall admin permissions"
    $userPassword = Read-Host "Input password for this user"
    $FwURL = Read-Host "Input the firewall Management IP address (e.g. 172.10.100.21)"
    $xmlFile = "$path\$FwURL" + "collection_settings.xml"
    Push-Location $path
    Write-Host "Updating the collection_settings.xml file"
    (Get-Content "$path\collection_settings.xml") | ForEach-Object { $_ -replace "user"">", "user"">$username" -replace "pwd"">", "pwd"">$userPassword" -replace "url"">", "url"">$FwURL" } | Set-Content $xmlFile
    success "Starting the collection phase"
    CheckPointOfflineCollector $xmlFile
    Pop-Location
    Copy-Item -Path "$FwURL\offline_config_$FwURL.json" -Destination $ACQ
}
function HamsterBuildDeploy {
    Clear-Host
    $help = @"

Hamster build and deploy
------------------------

This will run the HamsterBuilder application in order to configure an create the deployment pack,
and later on execute the deployment phase.

Steps that will be executed:
1.Choose the path to Hamsterbuilder.exe file
2.Create a shared directory on the file server with permission to copy files from all computers on the network
3.Run the HamsterBuilder application, Configure and Create a deployment pack for the organization
4.Deploy the executable created using PDQDeply application
5.Wait until running is finished and all .zip files for each computer is created
6.Copy all zip files to the audit directory
7.Dont forget to Upload the files to the Hamster server when you go back to the office

"@
    Write-Host $help
    $ACQ = ACQ("Hamster")
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.filter = "HamsterBuilder.exe | HamsterBuilder.exe"
    $OpenFileDialog.Title = "Locate and choose the HamsterBuilder.exe file to run !!!"
    $OpenFileDialog.ShowDialog() | Out-Null
    $HamsterBuilderPath = $OpenFileDialog.filename
    if ($HamsterBuilderPath -notlike "") {
        & $HamsterBuilderPath
        PDQDeployConsole
        $sharedPath = Read-Host "Input the shared path where all data is collected to"
        $numOfcomputers = Read-Host "Input the nuber of computer that you have collected data from"
        $numOfZip = (Get-ChildItem $sharedPath\*.zip).count
        if ($numOfZip -lt $numOfcomputers) {
            failed "Found only $numOfZip zip files, this is less than $numOfcomputers!!!"
        } else {
            success "Found $numOfZip zip files"
        }
        $userInput = Read-Host "Input [C] to copy all zip files to audit folder or [Enter] to continet"
        if ($userInput -eq "C") {
            Copy-Item -Path $sharedPath\*.zip -Destination $ACQ -Force
        }
    } else {
        failed "Hamster.exe was not located so script will not execute, Please try again"
    }
}

function CalculateSubnetPrefix {
    param (
        $subnetMask
    )
    [String]$formatted = [COnvert]::ToString(([ipaddress]$subnetMask).Address, 2)
    $counter = 0
    foreach ($var in $formatted.ToCharArray()) {
        if ($var -eq '1') {
            $counter++
        }   
    }
    return $counter    
}

function GetIPObject {
    #TODO: figure out how to choose the right network adapter
    $adapterConf = (Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -Filter "index=1" )
    $ipaddress = $adapterConf.IPAddress[0]
    $subnetmask = $adapterConf.IPSubnet[0]

    $subnetIP = ([IPAddress] (([IPAddress] $ipaddress).Address -band ([IPAddress] $subnetmask).Address)).IPAddressToString    

    $IPObject = [PSCustomObject]@{
        IP           = $ipaddress
        SubnetIP     = $subnetIP
        SubnetMask   = $subnetmask
        SubnetPrefix = CalculateSubnetPrefix -subnetMask $subnetmask
    }
    return $IPObject
       
}

function Lynis {
    Clear-Host
    . $PSScriptRoot\CyberLynis.ps1
    $ACQ = ACQ("Lynis")
    Start-Lynis -ACQ $ACQ -Lynis "$psscriptroot\Tools\Lynis\lynis-remote.tgz"
}

function zBang {
    $help = @"

zBang risk assessment tool
------------------------
Organizations and red teamers can utilize zBang to identify potential attack vectors and improve the security posture of the network.
The results can be analyzed with the graphic interface or by reviewing the raw output files.

The tool is built from five different scanning modules:

    ACLight scan - discovers the most privileged accounts that must be protected, including suspicious Shadow Admins.
    Skeleton Key scan - discovers Domain Controllers that might be infected by Skeleton Key malware.
    SID History scan - discovers hidden privileges in domain accounts with secondary SID (SID History attribute).
    RiskySPNs scan - discovers risky configuration of SPNs that might lead to credential theft of Domain Admins
    Mystique scan - discovers risky Kerberos delegation configuration in the network.

"@
    Write-Host $help
    $zBangPath = Invoke-Expression "scoop prefix zBang"
    $zBangPath = Join-Path -Path $zBangPath -ChildPath "zBang.exe"
    $ACQ = ACQ("zBang")
    Start-Process -FilePath $zBangPath -WorkingDirectory $ACQ
    Write-Host ""
    Write-Host "A separated window will open with zBang's GUI"
    Write-Host "On the GUI, choose the scans you want and then `"Launch`""
    Write-Host "Please note that pressing `"Reload`" will generate a demo data that has nothing to do with the actual network."
    Write-Host ""
    Write-Host "All reports will be saved at the designated acquisition folder"
}
<#
.SYNOPSIS
    Scan AD's password hashes and compare them to leaked passwords list
    The script runs in background because of the time it can take
#>
function Get-BadPasswords {
    Clear-Host
    Import-Module "$PSScriptRoot\Cyber7zFunctions.psm1"
    $help = @"

Get-bADpasswords
----------------------
This module is able to compare password hashes of enabled Active Directory users against bad/weak/non-compliant passwords (e.g. hackers first guess in brute-force attacks).

* Performs comparison against one or multiple wordlist(s).
* Performs additional comparison against publicly leaked passwords.
* Performs password comparison against 'null' in the Active Directory (i.e. finds empty/null passwords).
* Performs password comparison between users in the Active Directory (i.e. finds shared passwords).

The script will run in background so you would continue to work simultaneously


"@
    Write-Host $help
    $GBPFolder = Invoke-Expression "scoop prefix getbadpasswords"
    if (!(Test-Path $GBPFolder)) {
        Write-Host "Error, Get-bADPasswords not installed"
        return
    }
    <#
    # No need becacuse a bug, that the embedded version works with cleartext passwords, while the outer version works with hashed passwords <facepalm>
    # If the bug will fixed, the code below will be useful instead of installing PSIRepacker indepentently
# Check if the copy already done before
if (!(Test-Path -Path "$GBPFolder\PSI\PsiRepacker_x64.exe.old")){
    # Insert PSIRepacker instead of the old one, that from non reason is not working
    $source = "$(scoop prefix "PsiRepacker")\PsiRepacker\*"
    $passwordListPath = "$GBPFolder\PSI\"
    Copy-Item -Path $source -Destination $passwordListPath -Force
    Rename-Item -Path "$passwordListPath\PsiRepacker_x64.exe" -NewName "PsiRepacker_x64.exe.old" -Force
    Rename-Item -Path "$passwordListPath\PsiRepacker.exe" -NewName "PsiRepacker_x64.exe" -Force
}
#>

    $userInput = Read-Host "If you have downloaded the DB manually, press [M] to locate it and we will move it to the right place.
Press [ENTER] if the file is already in the right place"
    if ($userInput -eq "M") {
        [System.IO.FileInfo]$source = Get-FileName
        [System.Collections.ArrayList]$extractedFiles = [System.Collections.ArrayList]::new()
        $passwordListPath = Join-Path -Path $GBPFolder -ChildPath "Accessible\PasswordLists"
        
        #region Handling file if it is a 7z or txt
        if ($source.Extension -match "7z|txt") {
            
            #region Handling the file in case it's a 7z file - extract the files
            if ($source.Extension -match "7z") {
                $7z = Get-7z
                if (!(Test-DriveStorage $source.FullName $7z -DestinationToCheck $passwordListPath)) {
                    Read-Host "Press ENTER to continue"
                    return
                }
                $userInput = Read-Host "To extract the from in its current place, press [ENTER], or press [C] to move it"
                if ($userInput -eq "c") {
                    Write-Host "Moving file"
                    $7zFilePath = (Move-Item -Path $source.FullName -Destination $passwordListPath -Force -Verbose -PassThru).FullName
                } else {
                    $7zFilePath = $source.FullName
                }
                
                Write-Host "Extracting 7z"
                # Extract all files to one directory without preserve files tree
                # But log the files to stdout
                # In a conflict, rename extracting file
                $cmd = "$7z e -bb -aou -o`"$passwordListPath`" `"$7zFilePath`""
                $output = Invoke-Expression $cmd 
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "Files extracted successfully, do you want to delete the 7z file?"
                    $userInput = Read-Host "Type [Y] to delete, or [ENTER] to continue"
                    if ($userInput -eq "y") {
                        Remove-Item $7zFilePath
                    }
                }
                # Adding the files to a file list, based on the output of the extraction process
                $output | Select-String -Pattern '^- ' | ForEach-Object {
                    $extractedFiles.add([System.IO.FileInfo] "$passwordListPath\$($_ -replace '- ')") | Out-Null
                } 
            }
            #endregion Handling the file in case it a 7z file
            # In case of txt file:
            else {
                # The operation can be changed to moving the file, but it may be more convenient to leave it where it is
                #$extractedFiles.Add($(Move-Item -Path $source.FullName -Destination $passwordListPath -Force -Verbose -PassThru))
                $extractedFiles.Add($source) | Out-Null
            }
            #region Handling the file after extraction if needed
            # Now the $extractedFiles contain txt or bin
            
            if ($extractedFiles.extension.Contains(".txt")) {
                Write-Host ""
                Write-Host "Warning! One of the files is a txt file and not a bin file" -ForegroundColor Yellow
                Write-Host "If you want to save time, it is recommended to repack the file now so Get-bADPasswords will read it slightly" -ForegroundColor Yellow
                Write-Host "Notice that Get-bADPasswords will do this action anyway" -ForegroundColor Yellow
                Write-Host "If you want to do it later press [L], otherwise [ENTER] to do it now automatically" -ForegroundColor Yellow
                $userInput = Read-Host

                if ($userInput -ne "L") {
                    Write-Host "Repacking files..."
                    Write-Host "Make sure your RAM memory is big enough to contain each file"
                    Write-Host ""
                    
                    foreach ($file in $extractedFiles) {
                        $repacked = "$passwordListPath\$($file.BaseName).bin"
                        $repackerPath = "$(scoop prefix PsiRepacker)\PsiRepacker\PsiRepacker.exe"
                        Start-Process -NoNewWindow -FilePath "$repackerPath" -ArgumentList @("`"$($file.FullName)`"", "`"$repacked`"") -Wait
                        Write-Host ''
                        Write-Host 'Calculating file hash...'
                        (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash > "$passwordListPath\$($file.BaseName).chk"
                        Write-Host "Hash saved in: $passwordListPath\$($file.BaseName).chk"
                    }
                }
            }
            #endregion Handling the file after extraction if needed
        }
        #endregion Handling file if it is a 7z or txt
        elseif ($source.Extension -match "bin") {
            Move-Item -Path $source.FullName -Destination $passwordListPath -Force -Verbose -PassThru
        } else {
            Write-Host "Warning: Your file is neither a txt file nor a bin file, and won't be helpful for get-bAD-Password" -ForegroundColor Yellow
            Write-Host "Continuing without this file..." -ForegroundColor Yellow
        }
    }

    $adminGroups = Get-Content  -Path "$GBPFolder\Accessible\AccountGroups\1 - Administrative.txt"
    Write-Host ""
    Write-Host "The administrative groups which their members will be checked are:" -ForegroundColor Yellow
    $adminGroups.foreach({ Write-Host "- $_"  -ForegroundColor Yellow }) 
    Write-Host ""
    Write-Host "Do you want to add groups to this list?" -ForegroundColor Yellow
    Write-Host "You can delete groups manually in the txt file in `"$GBPFolder\Accessible\AccountGroups`"" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press [A] to add, otherwise press [ENTER] to continue" -ForegroundColor Yellow
    $userInput = Read-Host 
    Write-Host ""
    if ( $userInput -eq "a") {
        $userInput = Read-Host "Enter groups names seperated by a comma"
        $groups = $userInput -split '\s*,\s*' | Where-Object { $_ -notmatch '^\s*$' }

        Write-Host "The groups are: $groups" -Separator "`n- "
        Add-Content -Path "$GBPFolder\Accessible\AccountGroups\1 - Administrative.txt" -Value $groups
    }
    # Moving big txt files to another folder so the scpript wont scan them again as it runs
    $passwordTxtsDir = (New-Item -Name "PasswordTxts"  -Path "$GBPFolder\Accessible\" -ItemType Directory -Force).FullName
    $filesInPasswordsFolder = Get-ChildItem -Path "$passwordListPath"
    foreach ($file in $filesInPasswordsFolder) {
        if (($file.Extension -match "txt") -and ($(($file.Length)/1MB) -gt 20) ) {
            if ($filesInPasswordsFolder.Name.Contains("$($file.BaseName).bin")){
                Move-Item $file.FullName -Destination $passwordTxtsDir -Force
            }
        }
    }
    Write-Host ""
    Write-Host "A window will be open with Get-bADpasswords run"
    Start-Process -FilePath "powershell" -Verb RunAs -ArgumentList "-file `"$PSScriptRoot\CyberGetBadPasswords.ps1`""
}
function HandleMenuChoises {
    param (
        [Parameter(Mandatory = $true)]
        $userInput
    )
    switch ($userInput) { 
        #Domain
        1 { Domain }

        #Test Domain Connections and Configurations for audit
        2 { TestDomain }
        
        #goddi
        3 { Goddi }

        #NTDS and SYSTEM hive remote aquisition
        4 { NTDSAquire }
        
        #PingCastle
        5 { PingCastle }

        #GPO
        6 { BackupGPO }
        
        #Testimo
        7 { Testimo }
                
        #Sharphound
        8 { Sharphound }
        
        #Grouper2
        9 { Grouper2 }
        
        #HostEnum
        10 { HostEnum }
                
        #Scuba
        11 { Scuba }
        
        #azscan
        12 { Azscan }

        #runecast
        13 { Runecast }

        #Nessus
        14 { Nessus }
        
        #Misc
        15 { Misc }
        
        #Printers
        16 { Printers }
        
        #Sensitive
        17 { Sensitive }
        
        #Network and Port Scanners
        18 { NetworkScan }

        #Network
        19 { CollectNetworkConfig }

        #Skybox-WMI scanner and parser
        20 { skyboxWMIScanner }

        #Skybox-WSUS collection
        21 { SkyboxWsusCollection }
 
        #Skybox-CP CheckPoint collector
        22 { SkyboxCheckpintCollector }
 
        #skybox-win
        23 { SkyboxWin }
        
        #Hamster
        24 { HamsterBuildDeploy }

        #Dumpert
        25 { Dumpert }
        
        #DNS tests
        26 { DNSTests }

        #Speed port scanning
        27 { Masscan }
        
        # Check linux server
        28 { Lynis }

        # detects potential privileged account threats
        29 { zBang }

        # Get insights into the actual strength and quality of passwords in Active Directory
        30 { Get-BadPasswords }
        
        #Menu End
    }
}

function ShowAuditMenu {
    #Create the main menu
    Write-Host ""
    Write-Host "************************************************************************           " -ForegroundColor White
    Write-Host "*** Cyber Audit Tool (Powershell Edition) - ISRAEL CYBER DIRECTORATE ***           " -ForegroundColor White
    Write-Host "************************************************************************           " -ForegroundColor White
    Write-Host ""
    Write-Host "     Audit Data Collection:                                                        " -ForegroundColor White
    Write-Host ""
    Write-Host "     Domain Controller: $DC                                                        " -ForegroundColor $menuColor
    Write-Host "     Aquisition folder: $BaseFolder                                             " -ForegroundColor yellow
    Write-Host ""
    Write-Host "     1. Domain		| Join/Disconnect machine to/from a Domain                     " -ForegroundColor White
    Write-Host "     2. Test		| Test Domain Connections and Configurations for audit         " -ForegroundColor White
    Write-Host "     3. goddi		| dumps Active Directory domain information                    " -ForegroundColor White
    Write-Host "     4. NTDS		| Remote aquire ntds/SYSTEM from ActiveDirectory               " -ForegroundColor White
    Write-Host "     5. PingCastle 	| Active Directory Security Scoring                            " -ForegroundColor White
    Write-Host "     6. GPO      	| Backup Domain GPO to compare using Microsoft PolicyAnalyzer  " -ForegroundColor White
    Write-Host "     7. Testimo 	| Running audit checks of Active Directory                     " -ForegroundColor White
    Write-Host "     8. SharpHound	| BloodHound Ingestor for collecting data from AD              " -ForegroundColor White
    Write-Host "     9. Grouper2 	| Find ActiveDirectory GPO security-related misconfigurations  " -ForegroundColor White
    Write-Host "    10. HostEnum	| Red-Team-Script Collecting info from remote host and Domain  " -ForegroundColor White
    Write-Host "    11. SCUBA		| Vulnerability scanning Oracle,MS-SQL,SAP-Sybase,IBM-DB2,MySQ " -ForegroundColor White
    Write-Host "    12. azscan		| Oracle,Unix-Linux,iSeries,AS400-OS400,HP-Alpha,Vax,DECVax,VMS" -ForegroundColor White
    Write-Host "    13. Runecast	| Security Hardening checks of VMWARE vSphere/NSX/cloud        " -ForegroundColor White
    Write-Host "    14. Nessus    	| Vulnerability misconfigurations scanning of OS,Net,Apps,DB..." -ForegroundColor White
    Write-Host "    15. Misc    	| collection of scripts that checks miscofigurations or vulns  " -ForegroundColor White
    Write-Host "    16. Printers  	| Searching for printers and print servers vulnerabilities     " -ForegroundColor White
    Write-Host "    17. Sensitive  	| Searching for Sensitive documents and files on fileservers   " -ForegroundColor White
    Write-Host "    18. Scanners	| ICMP, Port, IP, NetBIOS, ActiveDirectory and SNMP scanners   " -ForegroundColor White
    Write-Host "    19. Network 	| Collect config files and routing from network devices (V2)   " -ForegroundColor White
    Write-Host "    20. Skybox-WMI	| WMI collector of installed programs from all windows machine " -ForegroundColor White
    Write-Host "    21. Skybox-WSUS	| Collect information from WSUS server                         " -ForegroundColor White
    Write-Host "    22. Skybox-CP	| Collect information from Checkpoint R80.10 and lower version " -ForegroundColor White
    Write-Host "    23. Skybox-Win	| All windows machines interface and routing config collector  " -ForegroundColor White
    Write-Host "    24. Hamster    	| Collect information from windows desktops and servers        " -ForegroundColor White
    Write-Host "    25. Dumpert	 	| LSASS memory dumper for offline extraction of credentials    " -ForegroundColor White
    Write-Host "    26. DNSTests	| Compare current DNS filtering results against other public DNS servers" -ForegroundColor White
    Write-Host "    27. masscan	 	| Speed Port Scanning                                          " -ForegroundColor White
    Write-Host "    28. Lynis	 	| Check security of a linux server via ssh                     " -ForegroundColor White
    Write-Host "    29. zBang	 	| Detects potential privileged account threats in network      " -ForegroundColor White
    Write-Host "    30. bADpasswords 	| Get insights into the actual strength and quality of passwords in AD" -ForegroundColor White
    Write-Host ""
    Write-Host "    99. Quit                                                                       " -ForegroundColor White
    Write-Host ""
}

Clear-Host
Import-Module $PSScriptRoot\CyberFunctions.psm1 -Force

$runningScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "Cyber Audit Tool 2021 [$runningScriptName]"
ShowIncd
CyberBginfo

$menuColor = "White"
$IPJob = Start-Job -ScriptBlock {Import-Module $input -Function Get-IPInformation; Get-IPInformation} -InputObject "$PSScriptRoot\CyberFunctions.psm1"
$BaseFolder = AcqBaseFolder
$ACQ = ACQ("Creds")
$cred = set-creds
Test-DomainAdmin $cred | Out-Null

start-Transcript -path $PSScriptRoot\CyberAuditPhase.Log -Force -append
Receive-Job -Job $IPJob



#SET Domain controller name
$i = 0
$DC = ($env:LOGONSERVER).TrimStart("\\")
Write-Host "Please wait, searching for a domain controller..."
try {
    if ($DClist = Get-ADDomainController -filter * -Credential $cred | Select-Object hostname, operatingsystem) {
        foreach ($dcontroller in $DClist) { $i++; $a = $dcontroller.hostname; $os = $dcontroller.operatingsystem ; if (($OS -match "2003") -or $OS -match "2008") { Write-Host "Domain Controller $i => $a ($OS)" -ForegroundColor red } else { Write-Host "Domain Controller $i => $a ($OS)" -ForegroundColor green } }
        if ($i -gt 1) {
            Write-Host "You are currently logged on to domain controller $DC"
            Write-Host "Some scripts can not execute automatically on Windows 2003/2008 Domain Controllers"
            $dcName = Read-Host "Input a different Domain Controller name to connect to (or Enter to continue using $DC)"
            if ($dcName -ne "") {
                $c = nltest /Server:$env:COMPUTERNAME /SC_RESET:$env:USERDNSDOMAIN\$dcName
                if ($c.Contains("The command completed successfully")) {
                    $DC = $dcName
                    success "Domain controller was changed to $DC"
                    $menuColor = "green"
                }
            }
        }
    } else {
        failed "No domain server was found, please connect this machine to a domain"
        $DC = "YOU ARE CURRENTLY NOT CONNECTED TO ANY DOMAIN !!!"
        $menuColor = "red"
    }
} catch {
    failed "No domain server was found, please connect this machine to a domain"
    $DC = "YOU ARE CURRENTLY NOT CONNECTED TO ANY DOMAIN !!!"
    $menuColor = "red"
}


Read-Host "Press Enter to start the audit collection phase (or Ctrl+C to quit)"

Clear-Host


do {
    ShowAuditMenu   
    Write-Host "Select Script Number"
    Write-Host "You can choose multiple actions by writing them sequently, separated by a comma"
    $userInput = Read-Host 
    $actions = $userInput -split '\s*,\s*' 
    $actions.foreach({
            HandleMenuChoises -userInput $_
        })
    read-host "Press ENTER to continue"
    Clear-Host
} while ($userInput -ne '99')

stop-Transcript | out-null
$cmd = "everything -exit"
Invoke-Expression $cmd