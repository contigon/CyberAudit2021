<#	
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

CLS

. $PSScriptRoot\CyberFunctions.ps1
ShowIncd
CyberBginfo
$Host.UI.RawUI.WindowTitle = "Cyber Audit Tool 2020 - Audit"

$menuColor = "White"

$ACQ = ACQ("")

#Set the credentials for this Audit (it will be stored in a file) and retrieve if exists
$credPath = "$ACQ\${env:USERNAME}_${env:COMPUTERNAME}.xml"

if ( Test-Path $credPath ) 
{
    $cred = Import-Clixml -Path $credPath
    $credUserName = $cred.username
    success "You have credentials stored for:  $credUserName"
}
else
{
    $parent = split-path $credpath -parent
    if ( -not ( test-Path $parent ) )
    {
        New-Item -ItemType Directory -Force -Path $parent
    }
    Get-Credential $env:userdomain\$env:USERNAME | Export-Clixml -Path $credPath
}

start-Transcript -path $AcqBaseFolder\CyberAuditPhase.Log -Force -append

#get external ip information includin ISP
$externalIP = (Invoke-WebRequest -uri "http://ifconfig.me/ip").Content 
$externalIP > $ACQ\externalIP.txt

#SET Domain controller name
$i=0
$DC = ($env:LOGONSERVER).TrimStart("\\")
Write-Host "Please wait, searching for a domain controller..."
try
{
    if ($DClist = Get-ADDomainController -filter * | select hostname, operatingsystem)
    {
        foreach ($dcontroller in $DClist) {$i++;$a = $dcontroller.hostname;$os = $dcontroller.operatingsystem ;if (($OS -match "2003") -or $OS -match "2008") {Write-Host "Domain Controller $i => $a ($OS)" -ForegroundColor red} else {Write-Host "Domain Controller $i => $a ($OS)" -ForegroundColor green}}
        if ($i -gt 1) 
        {
            Write-Host "You are currently logged on to domain controller $DC"
            Write-Host "Some scripts can not execute automatically on Windows 2003/2008 Doman Controllers"
            $dcName = Read-Host "Input a different Domain Controller name to connect to (or Enter to continue using $DC)"
            if ($dcName -ne "") 
            {
                $c = nltest /Server:$env:COMPUTERNAME /SC_RESET:$env:USERDNSDOMAIN\$dcName
                if ($c.Contains("The command completed successfully"))
                {
                    $DC = $dcName
                    success "Domain controller was changed to $DC"
                    $menuColor = "green"
                 }
            }
        }
    }
    else 
    {
        failed "No domain server was found, please connect this machine to a domain"
        $DC = "YOU ARE CURRENTLY NOT CONNECTED TO ANY DOMAIN !!!"
        $menuColor = "red"
    }
}
catch 
{
    failed "No domain server was found, please connect this machine to a domain"
    $DC = "YOU ARE CURRENTLY NOT CONNECTED TO ANY DOMAIN !!!"
    $menuColor = "red"
}

Read-Host "Press Enter to start the audit collection phase (or Ctrl+C to quit)"

cls

do {
#Create the main menu
Write-Host ""
Write-Host "************************************************************************           " -ForegroundColor White
Write-Host "*** Cyber Audit Tool (Powershell Edition) - ISRAEL CYBER DIRECTORATE ***           " -ForegroundColor White
Write-Host "************************************************************************           " -ForegroundColor White
Write-Host ""
Write-Host "     Audit Data Collection:                                                        " -ForegroundColor White
Write-Host ""
Write-Host "     Domain Controller: $DC                                                        " -ForegroundColor $menuColor
Write-Host "     Aquisition folder: $AcqBaseFolder                                             " -ForegroundColor yellow
Write-Host ""
Write-Host "     1. Domain		| Join/Disconnect machine to/from a Domain                     " -ForegroundColor White
Write-Host "     2. Test		| Test Domain Connections and Configurations for audit         " -ForegroundColor White
Write-Host "     3. NTDS		| Remote aquire ntds/SYSTEM                                    " -ForegroundColor White
Write-Host "     4. Network 	| Collect config files and routing from network devices (V2)   " -ForegroundColor White
Write-Host "     5. PingCastle 	| Active Directory Security Scoring                            " -ForegroundColor White
Write-Host "     6. Testimo 	| Running audit checks of Active Directory                     " -ForegroundColor White
Write-Host "     7. goddi		| dumps Active Directory domain information                    " -ForegroundColor White
Write-Host "     8. GPO      	| Backup Domain GPO to compare using Microsoft PolicyAnalyzer  " -ForegroundColor White
Write-Host "     9. SharpHound	| BloodHound Ingestor for collecting data from AD              " -ForegroundColor White
Write-Host "    10. HostEnum	| Red-Team-Script Collecting info from remote host and Domain  " -ForegroundColor White
Write-Host "    11. SCUBA		| Vulnerability scanning Oracle,MS-SQL,SAP-Sybase,IBM-DB2,MySQ " -ForegroundColor White
Write-Host "    12. azscan		| Oracle,Unix-Linux,iSeries,AS400-OS400,HP-Alpha,Vax,DECVax,VMS" -ForegroundColor White
Write-Host "    13. Grouper2 	| Find ActiveDirectory GPO security-related misconfigurations  " -ForegroundColor White
Write-Host "    14. Dumpert	 	| LSASS memory dumper for offline extraction of credentials    " -ForegroundColor White
Write-Host "    15. Runecast	| Security Hardening checks of VMWARE vSphere/NSX/cloud        " -ForegroundColor White
Write-Host "    16. Misc    	| collection of scripts that checks miscofigurations or vulns  " -ForegroundColor White
Write-Host "    17. Skybox-Win	| All windows machines interface and routing config collector  " -ForegroundColor White
Write-Host "    18. Nessus    	| Vulnerability misconfigurations scanning of OS,Net,Apps,DB..." -ForegroundColor White
Write-Host "    19. Printers  	| Searching for printers and print servers vulnerabilities     " -ForegroundColor White
Write-Host "    20. Sensitive  	| Searching for Sensitive documents and files on fileservers   " -ForegroundColor White
Write-Host "    21. Scanners	| ICMP, Port, IP, NetBIOS, ActiveDirectory and SNMP scanners   " -ForegroundColor White
Write-Host "    22. Skybox-WMI	| WMI collector of installed programs from all windows machine " -ForegroundColor White
Write-Host ""
Write-Host "    99. Quit                                                                       " -ForegroundColor White
Write-Host ""
$input=Read-Host "Select Script Number"

switch ($input) 
     { 
     1 {
        Cls
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
        if (CheckMachineRole)
        {
             Write-Host "Your machine is part of $env:USERDNSDOMAIN"
             if (Test-ComputerSecureChannel -Server $DC)
             {
                Write-Host "[Success] Connected to domain server $DC using secure channel" -ForegroundColor Green
             }
             else
             {
                Write-Host "[Failure] Domain could not be contacted" -ForegroundColor Red
               $choose = Write-Host "Press [D] to disconnect from $env:USERDNSDOMAIN domain"
               if ($choose -eq "D")
               {
                Remove-Computer -PassThru -Verbose
                }
             }
        }
        else
        {
            $domain = Read-Host -Prompt "Enter Domain name to join the machine to (eg. cyber.gov.il)"
            $username = read-host -Prompt "Enter an admin user name which have enough permissions"
            $password = Read-Host -Prompt "Enter password for $user" -AsSecureString
            $username = $domain+"\"+$username
            $credential = New-Object System.Management.Automation.PSCredential($username,$password)
            Add-Computer -DomainName $domain -Credential $credential
        }

        $restart = read-host "Press [R] to restart machine in order for settings to take effect (Enter to continue)"
        if ($restart -eq "R")
        {
            shutdown /r /f /c "Rebooting computer afer Domain joining or disconnecting"
        }
    }

     #Test Domain Connections and Configurations for audit
     2 {
        Cls
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
        Enable-PSRemoting -Force;Get-Item WSMan:\localhost\Client\TrustedHosts
        Test-WsMan $DC
        Invoke-Command -ComputerName $DC -ScriptBlock {Get-WmiObject -Class Win32_ComputerSystem } -credential $cred
        $inpYesNo = Read-Host "Press [Enter] if test was successfull or [N] to try a different way"
        Switch ($inpYesNo) {
            "N" {
                Write-Host "Trying to start remote winrm using psexec"
                psexec -accepteula $env:LOGONSERVER -s winrm.cmd quickconfig -q
                write-host "another way is to run SolarWinds Remote Execution Enabler for PowerShell tool"
                RemoteExecutionEnablerforPowerShell
            }
        }
        read-host "Press ENTER to continue"
     }

     #NTDS and SYSTEM hive remote aquisition
     3 {
        cls
        $help = @"

        NTDS and SYSTEM hive remote aquisition
        --------------------------------------
        
        This script will try to connect to $DC Domain controller and create a remote backup of the
        ntds.dit database and SYSTEM hive, and then copies the files to the aquisition folder.

        In order for this script to succeed you need to have domain administrative permissions.

        Note: This script supports AD running on Windows Servers 2012 and up,
              on windows 2003/2008 we will show manual instructions. 
                
"@
        Write-Host $help
        $ACQ = ACQ("NTDS")
        $winVer = Invoke-Command -ComputerName $DC -ScriptBlock {(Get-WmiObject -class Win32_OperatingSystem).Caption} -credential $cred
        if($winVer.contains("2003") -or $winVer.contains("2008")) 
        {
            Write-Host "The domain server is " $winVer -ForegroundColor Red
            $block = @"

        Below window 2012 we cant backup the files remotely, 
        you will need to do it locally on the Domain Controller
        run these steps from elevated CMD:
        --------------------------
        1. ntdsutil
        2. activate instance ntds
        3. ifm
        4. create full C:\ntdsdump
        5. quit
        6. quit
        --------------------------
        when finished please copy the c:\ntdsdump directory to the Aquisition folder (NTDS)

"@
Write-Host $block -ForegroundColor Red
        }
        else
        {
            Write-Host "Please wait untill the backup process is completed" -ForegroundColor Green
            remove-item $env:LOGONSERVER\c$\ntdsdump -Recurse -ErrorAction SilentlyContinue
            winrs -r:$DC ntdsutil "ac i ntds" "ifm" "create full c:\ntdsdump" q q
            Copy-Item -Path $env:LOGONSERVER\c$\ntdsdump\* -Destination $ACQ -Recurse -Force
        }
     read-host "Press ENTER to continue"
     $null = start-Process -PassThru explorer $ACQ
     }

     #Network
     4 {
        Cls
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
        $ScriptToRun = $PSScriptRoot+"\CyberCollectNetworkConfigV2.ps1"
        &$ScriptToRun
        read-host "Press ENTER to continue"
        $null = start-Process -PassThru explorer $ACQ
        }

     #PingCastle
     5 {
        Cls
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
        $ScriptToRun = $PSScriptRoot+"\CyberPingCastle.ps1"
        &$ScriptToRun
        read-host "Press ENTER to continue"
        $null = start-Process -PassThru explorer $ACQ
        }

    #Testimo
    6 {
        Cls
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
        if (checkRsat) 
        {
            import-module activedirectory ; Get-ADDomainController -Filter * | Select Name, ipv4Address, OperatingSystem, site | Sort-Object -Property Name
            Invoke-Testimo  -ExcludeSources DCDiagnostics -ReportPath $ACQ\Testimo.html
            $null = start-Process -PassThru explorer $ACQ
        }
        read-host "Press ENTER to continue"
     }

    #goddi
    7 {
        Cls
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
        $ACQ = ACQ("goddi")        
        Write-Host "You are running as user: $env:USERDNSDOMAIN\$env:USERNAME"
        $securePwd = Read-Host "Input a Domain Admin password" -AsSecureString
        $Pwd =[Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePwd))
        goddi-windows-amd64.exe -username="$env:USERNAME" -password="$Pwd" -domain="$env:USERDNSDOMAIN" -dc="$DC" -unsafe
        Move-Item -Path $appsDir\goddi\current\csv\* -Destination $ACQ -Force
        read-host "Press ENTER to continue"
        $null = start-Process -PassThru explorer $ACQ
     }

     #GPO
     8 {
        cls
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
        $ScriptToRun = $PSScriptRoot+"\CyberGPLinkReport.ps1"
        &$ScriptToRun | Export-Csv -Path $ACQ\GPLinkReport.csv -NoTypeInformation
        $ADcomputers = Get-ADComputer -Filter * | Select-Object name
        $input = Read-Host "Press G to get all gpresults from all computers in the domain"
        if ($input -eq "G")
        {
            foreach ($comp in $ADcomputers)
            {
                if (Test-Connection -ComputerName $comp.name -Count 1 -TimeToLive 20 -ErrorAction Continue)
                {
                    $compname = $comp.name
                    $cmd = "gpresult /S $compname /R /V > $ACQ\gpresult\gpresult-$compname.txt"
                    Invoke-Expression $cmd
                }
            }
        }
        $cmd = "robocopy $env:LOGONSERVER\sysvol\ $ACQ\sysvol\ /copyall /mir"
        Invoke-Expression $cmd
        read-host "Press ENTER to continue"
        $null = start-Process -PassThru explorer $ACQ
     }

     #Sharphound
     9 {
        cls
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
        Invoke-BloodHound -CollectionMethod All,GPOLocalGroup,LoggedOn -OutputDirectory $ACQ
        $MaXLoop = read-host "Choose Maximum loop time for session collecting task (eg. 30m)"
        Invoke-BloodHound -CollectionMethod SessionLoop -MaxLoopTime $MaXLoop -OutputDirectory $ACQ
        Invoke-BloodHound -SearchForeset -CollectionMethod All,GPOLocalGroup,LoggedOn -OutputDirectory $ACQ
        read-host "Press ENTER to continue"
        $null = start-Process -PassThru explorer $ACQ
     }

     #HostEnum
     10 {
        cls
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
        read-host "Press ENTER to continue"
        $null = start-Process -PassThru explorer $ACQ
     }

     #Scuba
     11 {
        cls
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
        $input = read-host "Wait untill auditing finished and Press [Enter] to save report"
        $ScubaDir = scoop prefix scuba-windows
        if (Get-Item -Path "$ScubaDir\Scuba App\production\AssessmentResults.js" -ErrorAction SilentlyContinue)
            {
                $serverAddress = Select-String -Path "$ScubaDir\Scuba App\production\AssessmentResults.js"  -pattern "serverAddress"
                $database = Select-String -Path "$ScubaDir\Scuba App\production\AssessmentResults.js"  -pattern "database"
                $a = $serverAddress -split "'"
                $b = $database -split "'"
                $fname = ($a[3] -split ":")[0] + "(" +  $b[3] + ")"
                Compress-Archive -Path "$appsDir\scuba-windows\current\Scuba App\" -DestinationPath "$ACQ\$fname.zip" -Force
                success "exporting AssessmentResults.js to .csv" 
                SetPythonVersion "2"
                python .\Scuba2CSV.py "$ScubaDir\Scuba App\production\AssessmentResults.js"
                Rename-Item -Path "$ACQ\ScubaCSV.csv" -NewName "$ACQ\ScubaCSV-$fname.csv"
                $null = start-Process -PassThru explorer $ACQ
            }
            else
            {
                Write-Host "Could not find any Report, please check why and try again"
            }            
            read-host "Press ENTER to continue"
            KillApp("javaw","Scuba")
     }

        #azscan
     12 {
        $ACQ = ACQ("azscan")
        $help = @"

        azscan supprts auditing of Oracle Databases versions: 7,8,9,10gR1,10gR2,11g,12c
        The steps includes running the [AZOracle.sql] script on the Oracle DB which outputs
        a result file [OScan.fil] which needs to be imported back to the azscan tool which 
        will run the tests and prepare a report with the results of the audit
        
"@
        Write-Host $help
        $input = Read-Host "Input [O] in order to audit ORACLE database (Or Enter to continue with other Platforms)"
        if ($input -eq "O") {
            $CopyToPath = Read-Host "Choose Path to Copy AZOracle.sql script to (eg. \\$DC\c$\Temp)"  
            if (Test-Path -Path $CopyToPath -PathType Any)
             {
                Copy-Item -Path $appsDir\azscan3\current\AZOracle.sql -Destination $CopyToPath
                $null = start-Process -PassThru explorer $CopyToPath
                $copyResult = Read-Host "Press [Enter] to copy OScan.fil from $CopyToPath to $ACQ"            
                Copy-Item -Path $CopyToPath\OScan.fil -Destination $ACQ
                $null = start-Process -PassThru explorer $ACQ
            }
            else {
                Write-Host "Could not connect to path $CopyToPath, Please check and try again" -ForegroundColor Red
            }
        }
        $cmd = "azscan3"
        Invoke-Expression $cmd
     }

    #Grouper2
     13 {
        cls
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
        read-host "Press ENTER to continue"
        $null = start-Process -PassThru explorer $ACQ
     }
        #Dumpert
     14 {
        cls
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
        read-host "Press ENTER to continue"
        $null = start-Process -PassThru explorer $ACQ
     }
        #runecast
     15 {
        cls
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
        $input = Read-Host "Press [R] to run the Create Role Powershell script (or Enter to contine)"
        if ($input -eq "R") {
            $ScriptToRun = $PSScriptRoot+"\CyberCreateRunecastRole.ps1"
            &$ScriptToRuns
        }
        read-host "Press ENTER to continue"
        $null = start-Process -PassThru explorer $ACQ
     }
    
         #Misc
     16 {
        Cls
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
        $ScriptToRun = $PSScriptRoot+"\CyberMisc.ps1"
        &$ScriptToRun
        read-host "Press ENTER to continue"
        $null = start-Process -PassThru explorer $ACQ
        }
    
         #IpconfigNetstat
     17 {
        Cls
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
        We recommend that you use an Import – Directory task to import the
        configuration data; the files for each device must be in a separate subdirectory of
        the specified directory (even if you are importing a single device)
                        
"@
        Write-Host $help
        $ACQ = ACQ("IpconfigNetstat")
        $ADcomputers = Get-ADComputer -Filter * | Select-Object name
        foreach ($comp in $ADcomputers)
        {
            if ( (Test-WinRM -ComputerName $comp.name).status)
            {
                $compname = $comp.name
                success "Collecting interface and routing from: $compname"
                $null = New-Item -ItemType Directory -Path "$ACQ\$compname" -Force                
                $res = Invoke-command -COMPUTER $compname -ScriptBlock {ipconfig} -ErrorAction SilentlyContinue -ErrorVariable ResolutionError
                Out-File -InputObject ($res) -FilePath "$ACQ\$compname\ipconfig.txt" -Encoding ascii
                $res = Invoke-command -COMPUTER $compname -ScriptBlock {netstat -r} -ErrorAction SilentlyContinue -ErrorVariable ResolutionError
                Out-File -InputObject ($res) -FilePath "$ACQ\$compname\netstat.txt" -Encoding ascii
            }
        }

        read-host "Press ENTER to continue"
        $null = start-Process -PassThru explorer $ACQ
        }

         #Nessus
     18 {
        Cls
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
        $ie.visible=$true
        $uri = 'https://localhost:8834'
        $ie.navigate("$uri")
        while($ie.ReadyState -ne 4) {start-sleep -m 100}
        if ($ie.document.url -Match "invalidcert")
                {
                Write-Host "Trying to Bypass SSL Certificate error page..."
                $sslbypass=$ie.Document.getElementsByTagName("a") | where-object {$_.id -eq "overridelink"}
                $sslbypass.click()
                }
        read-host "Press ENTER to continue"
        }
              
        #Printers
     19 {
        Cls
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
        $printservers = (Get-ADObject -LDAPFilter "(&(uncName=*)(objectCategory=printQueue))" -properties *|Sort-Object -Unique -Property servername).servername
        if ($printservers) {
            $printservers | Export-Csv $ACQ\PrintServers.csv
        }

        Write-Host "Getting list of installed printers from all registered domain computers"
        $computers = (Get-ADComputer -Filter *).name
        # Get printer information
        ForEach ($Printserver in $computers)
        { 
            $Printers = Get-WmiObject Win32_Printer -ComputerName $Printserver
            ForEach ($Printer in $Printers)
            {
                $Ports = Get-WmiObject Win32_TcpIpPrinterPort -Filter "name = '$($Printer.Portname)'" -ComputerName $Printserver
                if (($Printer.Name -notmatch "Microsoft") -and ($Printer.Name -notmatch "Adobe") -and ($Printer.Name -notlike "Fax*") -and ($Printer.Name -notmatch "FOXIT") -and ($Printer.Name -notmatch "OneNote"))
                {

                    Write-Host  "Server: $Printserver | IP: $Ports | Printer:" $Printer.Name | Export-Csv $ACQ\DomainPrinters.csv -NoTypeInformation -Append
                }
            }
        }

        $NetworkSegments = (Get-NetNeighbor -State "Reachable").ipaddress | foreach {[IPAddress] (([IPAddress] $_).Address -band ([IPAddress] "255.255.255.0").Address) | Select-Object IPAddressToString} | Get-Unique
        $segmentIp = $NetworkSegments.IPAddressToString
        Write-Host "Network segements found: $segmentIp"
        $input = Read-Host "Input a network subnet or [Enter] to scan $segmentIp/24 segment for printers"
        if ($input -eq "") {
            $input = "$segmentIp/24"
        }
        Write-Host "TCP Scanning for Printers... "
        nmap -p 515,631,9100 $input -oG $ACQ\PrintersTCPscan.txt
        $null = start-Process -PassThru explorer $ACQ

        Write-Host "UDP Scanning for Printers... "
        nmap -sU -p 161 $input -oG $ACQ\PrintersUDPscan.txt

        #snmpget -v 1 -O v -c public $ipaddress system.sysDescr.0

        SetPythonVersion "2"
        Push-Location $PretPath
        Write-Host "SMNP scanning for printers..."
        python .\pret.py
        $loop = {
         $input = Read-Host "Input ip address of a printer to try and hack or [Enter] to skip" 
         if ($input -ne "")
          {
                python .\pret.py $input pjl
                Start-Process powershell -ArgumentList ls
                $input = Read-Host "Press [T] to test More printers or [Enter] to finish"
                if ($input -eq "T") 
                {
                    &$loop
                }
           }
        }
        &$loop
        Pop-Location
        read-host "Press ENTER to continue"
        $null = start-Process -PassThru explorer $ACQ
        }

        #Sensitive
     20 {
        Cls
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
        $input = Read-Host "Input network share to scan for files (eg. \\FileServer\c$\Users)"
        $null = (Get-Content $iniPath\Everything.ini -Raw) -replace "\bfolders=(.*)","folders=$input" | Set-Content -Path $iniPath\Everything.ini -Force
        $null = (Get-Content $iniPath\Everything.ini -Raw) -replace "\bntfs_volume_includes=1","ntfs_volume_includes=0" | Set-Content -Path $iniPath\Everything.ini -Force
        $heb = "רשימה|סיסמה|סודי|סיסמאות|לקוחות|מסווג|רשימת|זהות|מטופלים|לקוחות|משכורות|חשבונות|כתובות|הנהלה"
        $eng = "secret|password|customer|patient|accounting|confidential"
        $ext = ".xls|.pdf|.doc|.zip|.7z|.rar|.txt"
        $cmd = "everything -first-instance -admin -reindex -s '$heb|$eng|$ext' "
        Invoke-Expression $cmd
        read-host "Press ENTER to continue"
        $null = start-Process -PassThru explorer $ACQ
        }
         #Network and Port Scanners
     21 {
        Cls
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
        read-host "Press ENTER to continue"
        $null = start-Process -PassThru explorer $ACQ
        }
   #Skybox WMI scanner and parser
     22 {
        Cls
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
        read-host "Press ENTER to continue"
        $null = start-Process -PassThru explorer $ACQ
        }

    #Menu End
    } 
 cls
 }
while ($input -ne '99')
stop-Transcript | out-null
$cmd = "everything -exit"
Invoke-Expression $cmd
