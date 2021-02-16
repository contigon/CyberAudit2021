<#	
	.NOTES
	===========================================================================
	 Created on:   	2/24/2020 1:11 PM
	 Created by:   	Omerf
	 Organization: 	Israel Cyber Directorate
	 Filename:     	CyberAnalyzers
	===========================================================================
	.DESCRIPTION
		Cyber Audit Tool - Aduti Data Analyzers tools 
#>

. $PSScriptRoot\CyberFunctions.ps1
ShowIncd
DisableFirewall
DisableAntimalware
CyberBginfo
$Host.UI.RawUI.WindowTitle = "Cyber Audit Tool 2020 - Analyzers"

Write-Host " "

#Set the Audit Acquisition folders
do
{
    Write-Host "Choose the root folder with the audit data you want to analyze" -ForegroundColor Yellow
    $AcqABaseFolder = Get-Folder
    if ($AcqABaseFolder -eq "")
    {
        failed "No folder was choosen, Please try again"
    }
    else
    {
        success $AcqABaseFolder
    }
}
while ($AcqABaseFolder -eq "") 

Function ACQA{
    Param ($dir)
    $ACQdir = ("$AcqABaseFolder\$dir").Replace("//","/")
    if (Test-Path -Path $ACQdir) 
        {
            Write-Host "[Note] $ACQdir folder already exsits, this will not affect the process" -ForegroundColor Gray
        }
     else        
        {
        $ACQdir = New-Item -Path $AcqABaseFolder -Name $dir -ItemType "directory" -Force
        write-host "$ACQdir was created successfuly" -ForegroundColor Green
        }
    Return $ACQdir
}

$ACQLog = ACQA("")
start-Transcript -path $ACQLog\CyberAnalyzersPhase.Log -Force -append

cls

do {
#Create the main menu
Write-Host ""
Write-Host "************************************************************************                " -ForegroundColor White
Write-Host "*** Cyber Audit Tool (Powershell Edition) - ISRAEL CYBER DIRECTORATE ***                " -ForegroundColor White
Write-Host "************************************************************************                " -ForegroundColor White
Write-Host ""
Write-Host "     Audit Data Analysis:                                                               " -ForegroundColor White
Write-Host "" 
Write-Host "     Data folder is: $AcqABaseFolder                                                     " -ForegroundColor yellow
Write-Host ""
Write-Host "     1. hash dumping   | Process NTDS/SYSTEM files and export the password hashes       " -ForegroundColor White
Write-Host "     2. Ophcrack       | Password cracker based on rainbow tables                       " -ForegroundColor White
Write-Host "     3. Hashcat        | Password cracker based on dictionaries                         " -ForegroundColor White
Write-Host "     4. BloodHound     | Find attack vectors within Active Directory                    " -ForegroundColor White
Write-Host "     5. PolicyAnalizer | Compare GPO to Microdoft Security configuration baselines      " -ForegroundColor White
Write-Host "     6. statistics     | Cracked Enterprise & Domain Admin passwords statistics         " -ForegroundColor White
Write-Host "     7. Dsinternals    | Password cracking using haveibeenpawned NTLM v5 file           " -ForegroundColor White
Write-Host "     8. AppInspector   | Software source code analysis to identify good or bad patterns " -ForegroundColor White
Write-Host "     9. XlsCharts      | Generate an excel Risk and remediation efforts charts          " -ForegroundColor White
Write-Host "    10. NTDS-Offline   | Mount ndts.dit file and SYSVOL for offline audit               " -ForegroundColor White
Write-Host ""
Write-Host "    99. Quit                                                                            " -ForegroundColor White
Write-Host ""
$input=Read-Host "Select Script Number"

switch ($input) {
     #Analyze the NTDS and SYSTEM hive (ntdsaudit, DSInternals)
     1 {
        cls
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
        $bk=Get-BootKey -SystemHivePath $ACQ\SYSTEM
        #$fileFormat = @("Ophcrack","HashcatNT","HashcatLM","JohnNT","JohnLM")
        $fileFormat = @("Ophcrack")
        foreach ($f in $fileFormat) 
        {
            Write-Host "[Success] Exporting hashes to $f format" -ForegroundColor Green
            Get-ADDBAccount -All -DBPath $ACQ\ntds.dit -BootKey $bk|Format-Custom -View $f|Out-File $ACQ\hashes-$f.txt -Encoding ASCII
        }
        
        Success "Creating the DomainStatistics.txt report from CyberAnalyzersPhase.Log"
        Select-String "Account stats for:" $ACQLog\CyberAnalyzersPhase.Log -Context 0,20 | % { 
            $_.context.PreContext + $_.line + $_.Context.PostContext
            } | Out-File $ACQ\DomainStatistics.txt


        Write-Host "Searching for installed Microsoft Excel"
        $excelVer = Get-WmiObject win32_product | where{$_.Name -match "Excel"} | select Name,Version
        if ($excelVer) 
        {
            success $excelVer[0].name "is already installed"
            if (Test-Path -Path "$ACQ\user-dump.csv")
            {
                Success "Generating the statistics excel file"
                $ScriptToRun = $PSScriptRoot+"\CyberUserDumpStatistics.ps1"
                &$ScriptToRun
            }
            else 
            {
                Failed "Check that user-dump.csv is located in the $ACQ folder and try again"
                Start-Process iexplore $ACQ
            }
        }
        else
        {
             Write-Host "[Failure] Please install Microsoft Excel before continuing running this analysis" -ForegroundColor Red
             read-host "úPress [Enter] if you installed Excel (or Ctrl + c to quit)"ù
        }
        
        read-host "úPress ENTER to continue"ù
        $null = start-Process -PassThru explorer $ACQ
     }

     #Ophcrack
     2 {
        CLS
        $ACQ = ACQA("NTDS")
        $help = @"
        
        Ophcrack
        --------

        Ophcrack is a free Windows password cracker based on rainbow tables.
        It is a very efficient implementation of rainbow tables done by the inventors of the method

        - Cracks LM and NTLM hashes
        - Free tables available
        - Brute-force module for simple passwords
        - Audit mode and CSV export
        - Real-time graphs to analyze the passwords
        - Dumps and loads hashes from encrypted SAM recovered from a Windows partition

        In order to run the hashed passwords cracking process, we will upload the
        $ACQ\hashes-Ophcrack.txt into ophcrack.
       
        Next step you will need to Press the [Crack] button to start the process.

"@
        write-host $help
        if (Test-Path -Path $ACQ\hashes-Ophcrack.txt)
        {
            Write-Host "[Success] The file $ACQ\hashes-Ophcrack.txt was found" -ForegroundColor Green
            $cmd = "ophcrack -d $appsDir\vista_proba_free\current -t $appsDir\vista_proba_free\current -f $ACQ\hashes-Ophcrack.txt -n 4"
            Invoke-Expression $cmd
        }
        else 
        {
            Write-Host "[Failed] The file $ACQ\hashes-Ophcrack.txt was not found, please check and try again" -ForegroundColor Red
        }
        read-host "úPress ENTER to continue"ù
     }
       #hashcat
     3 {
        CLS
        $help = @"
        
        hashcat
        --------

        advanced password recovery using GPU and CPU.

        Attack types:
        - Brute-force
        - Combinator
        - Dictionary
        - Fingerprint
        - Hybrid
        - Mask
        - Permutation attack
        - Rule-based
        - Table-Lookup attack
        - Toggle-Case attack
        - PRINCE attack

"@
        write-host $help
        $ACQ = ACQ("NTDS")
        #check if not Virtual Machine
        $ComputerSystemInfo = Get-WmiObject -Class Win32_ComputerSystem
        $GPU = (Get-WmiObject Win32_VideoController).VideoProcessor
        switch ($ComputerSystemInfo.Model) { 
        # Check for Hyper-V Machine Type 
        "Virtual Machine" { 
            $MachineType="VM" 
            } 
        # Check for VMware Machine Type 
        "VMware Virtual Platform" { 
            $MachineType="VM" 
            }  
        # Check for Oracle VM Machine Type 
        "VirtualBox" { 
            $MachineType="VM"             } 
        # Otherwise it is a physical Box 
        default { 
            $MachineType="Physical" 
            } 
        } 
        
        if ($MachineType -ne "Physical")
        {
            $help = @"

        [Failed] Your Virtualization graphics adapter is : $GPU

        hashcat needs OpenCL drivers which will operate best on physical GPU

        or try searching for help about GPU passthru for you virtualization environment.

"@

            Write-Host $help -ForegroundColor Red
        }
        else
        {
            $hashcatPath = scoop prefix hashcat
            $dumpFile = "pwdump.txt"
            Push-Location $hashcatPath
            $help = @"
        
        Hashcat will try now to crack the hashes extracted from Active Directory database file.

        You are running hashcat using this GPU: $GPU 
        It is best using a PC with GPU such as Nvidia 1080Ti GPU for faster cracking.
        
        We will be using the Rockyou.txt dictionary file.

        More dictionaries can be downloaded from:
        https://github.com/danielmiessler/SecLists/tree/master/Passwords
        https://www.blacktraffic.co.uk/pw-dict-public/dict/

        We will be using the l33tpasspro rule file.

        More rules can be downloaded from:
        https://github.com/nccgroup/hashcrack

        Other cracking tools recommended:
        hashcrack - Automatic tool that Guesses hash types, picks some sensible dictionaries and rules for hashcat
        https://github.com/nccgroup/hashcrack

"@
            write-host $help
            if (Test-Path -Path $ACQ\$dumpFile)
            {
                    Write-Host "[Success] The file $ACQ\$dumpFile was found" -ForegroundColor Green
                    $cmd = "hashcat -a 0 -m 1000 --username $ACQ\$dumpFile $appsDir\rockyou\current\rockyou.txt -r $appsDir\rockyou\current\l33tpasspro.rule.txt  --loopback  -O -w3 --force  -o $ACQ\pwdump_cracked.txt  --potfile-path $ACQ\hashcat-rockyou-lm.pot"
                    Invoke-Expression $cmd -WarningAction SilentlyContinue
                    $cmd = "hashcat -a 0 -m 1000 --username $ACQ\$dumpFile $appsDir\rockyou\current\rockyou.txt -r $appsDir\rockyou\current\l33tpasspro.rule.txt  --loopback  -O -w3 --force  -o $ACQ\pwdump_show_cracked.txt  --potfile-path $ACQ\hashcat-rockyou-lm.pot --show"
                    Invoke-Expression $cmd -WarningAction SilentlyContinue
                    $cracked = (Get-Content $ACQ\pwdump_show_cracked.txt).Split("\")
                    for ($i = 1 ; $i -lt (Get-Content .\cracked.txt).count;$i+=2)
                    {
                        Add-Content -Path $ACQ\found_cracked.txt  -value $cracked[$i]
                    }
                    $a = (Get-Content -Path  $ACQ\$dumpFile).count
                    $b = (Get-Content -Path  $ACQ\pwdump_show_cracked.txt).count
                    Add-Content -Path $ACQ\left_uncracked.txt  -value ($a - $b)
                    Start-Process iexplore $ACQ
            }
            else 
            {
                Write-Host "[Failed] The file $ACQ\pwdump.txt was not found, please check and try again" -ForegroundColor Red
            }
        }
     Pop-Location
     read-host "úPress ENTER to continue"ù
     }
     #BloodHound
     4 {
        CLS
        $ACQ = ACQA("Sharphound")
        $help = @"
        
        BloodHound
        ----------

        visualising attack paths using graph theory to reveal the hidden and often unintended relationships
        within an Active Directory environment and dentify highly complex attack paths.

        Data Includes:
        - Users          The users on the network extracted from active directory
        - Computers      The different endpoints on the network, servers, workstations and other devices
        - Groups         The different AD groups extracted from AD
        - Sessions       The amount of user sessions on computers on the network that the ingestor has extracted
        - ACLs           Access control lists, the different permissions and access that users and groups have against each other
        - Relationships  The different relations that all of the other aspects have to each other such as 
                          group memberships, users, user sessions and other related information

        Please wait untill the neo4j database is running, this can take some time,
        on 1st run you need to change the default login password in the neo4j web interface:
        User:     neo4j
        password: neo4j (change this to BloodHound)

        Bloodhound application login will be:
        User:    neo4j
        Password BloodHound

        After logging in to the bloodhound application you will need to upload the
        sharphound collected .json or .zip files in $ACQ

"@
        write-host $help -ForegroundColor Yellow
	    if (Get-Service -Name "neo4j" -ErrorAction SilentlyContinue) 
            {
	            $stat = invoke-expression "neo4j status"
                if ($stat -ne "Neo4j is running")
                {
                    #$j = Start-Job -ScriptBlock {Start-service "neo4j" -Verbose}
                    Write-Host "Starting neo4j service"
                    $j = Start-Job -ScriptBlock {neo4j start}
                    $j | Wait-Job
                    write-host "User:     neo4j" -ForegroundColor Yello
                    write-host "Password: BloodHound" -ForegroundColor Yello
                    invoke-expression "BloodHound"
                }
                else
                {
                    Success "neo4j is running, we can launce Bloodhound"
                    write-host "User:     neo4j" -ForegroundColor Yello
                    write-host "Password: BloodHound" -ForegroundColor Yello
                    invoke-expression "BloodHound"
                }
        }
        else {
                $cmd = "neo4j install-service"
                Invoke-Expression $cmd
                #Copy-Item "$appsDir\BloodHoundExampleDB\current\BloodHoundExampleDB.db\" "$appsDir\neo4j\current\data\databases\BloodHoundExampleDB.db" -Recurse -Force      
                #(Get-Content -Path  $appsDir\neo4j\current\conf\neo4j.conf -Raw) -replace "#dbms.active_database=graph.db","dbms.active_database=BloodHoundExampleDB.graphdb" | set-content -Path $appsDir\neo4j\current\conf\neo4j.conf
                #(Get-Content -Path  $appsDir\neo4j\current\conf\neo4j.conf -Raw) -replace "#dbms.allow_upgrade=true","dbms.allow_upgrade=true" | set-content -Path $appsDir\neo4j\current\conf\neo4j.conf
                $j = Start-Job -ScriptBlock {Start-service "neo4j" -Verbose}
                $j | Wait-Job
	            write-host "If you have problem with service starting, please start it manually from services.msc"
                Write-Host "and if problem is not resolved run from elevated console:"
                Write-Host "neo4j uninstall-service"
	            write-host "Verify neo4j is running(web console should show up in your browser"
                Write-Host "Starting Internet Explorer in background..."
                $ie = New-Object -com InternetExplorer.Application
                $ie.visible=$true
                $uri = 'http://localhost:7474/'
                $ie.navigate("$uri")
                while($ie.ReadyState -ne 4) {start-sleep -m 10}
                #start explorer http://localhost:7474/
	            write-host "User:     neo4j" 
	            write-host "Password: neo4j"
	            write-host "Please change default password to: BloodHound" -ForegroundColor Red
                read-host  "úAfter password is changed, Press ENTER to continue"ù
                write-host "Login to the BloodHound application using:"
                write-host "User:     neo4j" -ForegroundColor Yello
                write-host "Password: BloodHound" -ForegroundColor Yello
                invoke-expression "BloodHound"
        }
        Start-Process iexplore $ACQ
        read-host "úPress ENTER to continue"ù
     }
     #PolicyAnalizer
     5 {
        CLS
        $ACQ = ACQA("GPO")
        $SamplePolicyRulesPath =  scoop prefix PolicyAnalyzer
        $baselinePath =  scoop prefix PolicyAnalyzerSecurityBaseline
        Copy-Item -Path $baselinePath\* -Destination $SamplePolicyRulesPath\SamplePolicyRules -Exclude *.json -Recurse
        $help = @"
        
        In order to add the GPO backup please follow this help:
        1. Press ADD
        2. Choose File --> Add Files From GPO
        3. Path for GPO files is:  $ACQ
        4. Save this GPO (you will 1st need to give a name for this GPO)

        In order to compare to baselines:
        5. Set the Policy Rule Set path to: $SamplePolicyRulesPath
        6. Import matching policies such as: $SamplePolicyRulesPath\Windows 10 Version 2004 and Windows Server Version 2004 Security Baseline

"@
        write-host $help
        $analyzerPath = scoop prefix policyanalyzer
        $docsPath = [environment]::getfolderpath("mydocuments")
        [xml]$xml = get-content $ACQ\GPO\manifest.xml
        $auditDomain = ($xml.DocumentElement.ChildNodes.gpodomain)[1].InnerText
        Remove-Item $docsPath\PolicyAnalyzer\*.PolicyRules
        Write-Host "Copying policy rule sets to $docsPath\PolicyAnalyzer"
        Copy-Item "$analyzerPath\Policy Rules\*.PolicyRules" $docsPath\PolicyAnalyzer\
        Write-Host "Converting audited GPO to PolicyRules..."
        $cmd = "GPO2PolicyRules.exe $ACQ\GPO $docsPath\PolicyAnalyzer\$auditDomain.PolicyRules"
        Invoke-Expression $cmd
        Write-Host "Splitting policy rules to multiple gpo's"
        $ScriptToRun = $analyzerPath + "\Split-PolicyRules.ps1"
        &$ScriptToRun $docsPath\PolicyAnalyzer\$auditDomain.PolicyRules $docsPath\PolicyAnalyzer\$auditDomain
        $cmd = "policyanalyzer"
        Invoke-Expression $cmd
        read-host "Press Enter to continue"
     }
     #Statistics
     6 {     
        CLS
        $ACQ = ACQA("Statistics")
        $help = @"
        
        In order to create the password statistics excel we need 4 files
        ----------------------------------------------------------------
        Files From hashview or hashcat application after cracking the pwdump file
        You need export and copy them to $ACQ :
        1 - found_*.txt
        2 - left_*.txt
       
        Files that were created using the goddi applications
        we will try to copy them automatically:
        3 - Domain_Users_Domain Admins.csv
        4 - Domain_Users_Enterprise Admins.csv

"@

        Write-Host "Searching for installed Microsoft Excel"
        $excelVer = Get-WmiObject win32_product | where{$_.Name -match "Excel"} | select Name,Version
        if ($excelVer) 
        {
            success $excelVer[0].name "is already installed"
            $files = @("found_","left_","Domain_Users_Domain Admins.csv","Domain_Users_Enterprise Admins.csv")
            $hashcat = ACQA("NTDS")
            $found = $hashcat + "\" + $files[0].ToString()
            Copy-Item -Path $found*.txt -Destination $ACQ -Force
            $left = $hashcat + "\" + $files[1].ToString()
            Copy-Item -Path $left*.txt -Destination $ACQ -Force
            $goddi = ACQA("goddi")
            $DomainAdmins = $goddi + "\" + $files[2].ToString()
            Copy-Item -Path $DomainAdmins -Destination $ACQ -Force
            $EntAdmins = $goddi + "\" + $files[3].ToString()
            Copy-Item -Path $EntAdmins -Destination $ACQ -Force
            Write-Host $help -ForegroundColor Yellow
            Start-Process iexplore $ACQ
            $input  = Read-Host "Press [Enter] if all files are located in $ACQ (or Ctrl + C to quit)"
            $folderFiles = Get-ChildItem -Path $ACQ -Recurse -File -Name
            $i = 0
            foreach ($f in $files) {
                if ($folderFiles -match $f) { 
                    success "File $f*.txt was found"
                    $i++
                } else { 
                    failed "File $f*.txt was not found"
                }
            }
            if ($i -eq 4)
            {
                Success "Generating the statistics excel file"
                $ScriptToRun = $PSScriptRoot+"\CyberPasswordStatistics.ps1"
                &$ScriptToRun
            }
            else 
            {
                Failed "Check that all files are copied to the $ACQ folder and try again"
                Start-Process iexplore $ACQ
            }
        }
        else
        {
             Write-Host "[Failure] Please install Microsoft Excel before continuing running this analysis" -ForegroundColor Red
             read-host "úPress [Enter] if you installed Excel (or Ctrl + c to quit)"ù
        }
        read-host "úPress ENTER to continue"ù
     }

    #DSInternals
     7 {
        CLS
        $ACQ = ACQA("NTDS")
        $help = @"
        
        DSInternals
        -----------

        Performs an offline credential hygiene audit of AD database against HIBP (Have I Been Pawned file)

        This script uses the ntds.dit and SYSTEM hive to export the hashes from AD database,
        and then tries finding the password of already pawned hashes.

        Downloading the Pwned Passwords list file can be done from:
        https://haveibeenpwned.com/Passwords
        https://downloads.pwnedpasswords.com/passwords/pwned-passwords-ntlm-ordered-by-hash-v5.7z
        https://downloads.pwnedpasswords.com/passwords/pwned-passwords-ntlm-ordered-by-hash-v5.7z.torrent

"@
        write-host $help -ForegroundColor Yellow
        $input = Read-Host "Press [B] to browse for the location of pwned-passwords-ntlm-ordered-by-hash-v5.txt file"
        if ($input -eq "B") 
        {
            Import-Module DSInternals
            $bk=Get-BootKey -SystemHivePath $ACQ\SYSTEM
            $pwndfile = Get-FileName
            Get-ADDBAccount -All -DatabasePath $ACQ\ntds.dit -BootKey $bk | Test-PasswordQuality -WeakPasswordHashesSortedFile $pwndfile
         }
        read-host "úPress ENTER to continue"ù     
     }
     #appInspector
     8 {
        CLS
        $ACQ = ACQ("AppInspect")
        $help = @"
        
        appInspector
        ------------

        Application Inspector's primary objective is to identify source code features in a systematic and scalable way 
        not found elsewhere in typical static analyzers. This enables developer and security professionals to validate 
        purported component objectives.

        Application Inspector will scan projects with supported languages including projects with mixed languages 
        i.e. those that contain multiple languages in the same directory or sub-directories for well-known identifying features.

        more information:
        https://github.com/Microsoft/ApplicationInspector/wiki

        Steps:
        ------
        1. Compress the content of the source code
        2. Browse and select the source code compressed file
        3. The analyze process will start automatically
        4. Review the report that will be shown in your browser

"@
        write-host $help -ForegroundColor Yellow
        $fileName = Get-FileName
        $a = appdir("appinspector")
        push-Location $a
        $cmd = "appinspector analyze -s $fileName"
        Invoke-Expression $cmd
        Start-Process iexplore $ACQ
        Pop-Location    
        read-host "úPress ENTER to continue"ù     
     }
     #Remediation Efforts and Risk Charts
     9 {
        CLS
        $ACQ = ACQA("EffortsChart")
        $help = @"
        
        Remediation Efforts and Risk Charts
        -----------------------------------

        Generate Remediation Efforts and Risk Charts based on scoring of 
        audited categories and the risks found in each category.

        The effort scorings  is based on:
        1 = Low
        2 = Medium
        3 = High
        
        The Risk scoring is based on:
        80-125 = Critical
        45-79  = High
        25-44  = Medium
        1-24   = Low

        Requirements: 
        You need to have Microsoft Excel installed
"@
        write-host $help -ForegroundColor Yellow
        Write-Host "Searching for installed Microsoft Excel"
        $excelVer = Get-WmiObject win32_product | where{$_.Name -match "Excel"} | select Name,Version
        if ($excelVer) 
        {
            success $excelVer[0].name" is already installed"
            Copy-Item -Path $PSScriptRoot\CyberRiskCompute.xlsx -Destination $ACQ
            Start-Process "$ACQ\CyberRiskCompute.xlsx"
            Start-Process iexplore $ACQ
        }
        else
        {
             failed " Please install Microsoft Excel before running this analysis"
        }
        read-host "úPress ENTER to continue"ù
     }
     #Offline NTDS
     10 {
        CLS
        $ACQ = ACQA("NTDS")
        $help = @"

        Offline NTDS
        ------------
        
        Run Active Directory from ntds.dit file.

        requirements: Active Directory server 

        Option 1 - mounting ntds.dit remotely on the Domain server
        ----------------------------------------------------------
        The script will copy the ntds.dit to the domain controller 
        and try to mout it using dsamain.exe command

        Steps:
        1- Browse and Choose the ntds.dit file to load
        2- Check ntds.dit integrity
        3- Upgrade the ntds.dit database      
        4- Run the AD on port 10389
        5- Get the domain name from the mounted database
        6- Browse the AD using the sysinternals tool adexplorer (connect to $AD port 10389)

        Option 2 - mounting ntds.dit directly on the Domain server
        ----------------------------------------------------------
        run this script directly on the domain server

        $upg = "dsamain.exe /dbpath <path to ntds.dit> /ldapport 10389  /allowupgrade"
        $null = Invoke-Expression $upg
        $cmd = "/c dsamain.exe /dbpath <path to ntds.dit> /ldapport 10389  /allownonadminaccess"
        Start-Process "cmd.exe" $cmd

        
        Running Sharphound on mounted AD
        --------------------------------
        Import-Module SharpHound.ps1
        Invoke-BloodHound -DomainController <server name or IP> -LdapPort 10389 -Domain <full Domain name of the organization>

        (BloodHound needs the net-sessions in order to create the attack paths, so offline is not that relevant :-)

        Running pingcastle on mounted AD
        --------------------------------               
        pingCastle --no-enum-limit --carto --healthcheck --server <server name or ip> --port 10389
        pingCastle --hc-conso

        (pingcastle needs the SYSVOL from the original domain in order to create the complete report)

        
"@
        write-host $help
        $ScriptToRun = $PSScriptRoot+"\CyberOfflineNTDS.ps1"
        &$ScriptToRun
        read-host "úPress ENTER to continue"ù     
     }

#End Menu
    }
 cls
 }
while ($input -ne '99')

Stop-Transcript | out-null
#on exit stop neo4j service
Stop-Service "neo4j" -Verbose
