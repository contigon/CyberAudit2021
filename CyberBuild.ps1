<#	
	.NOTES
	===========================================================================
	 Created on:   	2/24/2020 1:11 PM
	 Created by:   	Omerf
	 Organization: 	Israel Cyber Directorate
	 Filename:     	CyberMenu
	===========================================================================
	.DESCRIPTION
		Cyber Audit Tool - Build
#>

# Imports
Set-ExecutionPolicy Unrestricted
Import-Module $PSScriptRoot\CyberFunctions.psm1

# The following function set the modules environment in the PC (copy module -> update rootModule path, functions and vars  to  export -> import the module )
function copy-ModuleToDirectory {
    [CmdletBinding()]
    [OutputType('System.Management.Automation.PSModuleInfo')]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $Name
    )
    Write-Host "starting building the dev environment...`n"
    # get the path to put the module in
    $modulePathDests = $env:PSModulePath -Split ';'
    $Destination = $modulePathDests[0]
    # get the name of the desired module to import
    $leafNameList = $Name -Split "\\"
    # leafName stands for the name of the file
    $leafName = $leafNameList[$leafNameList.Count - 1]
    $modulRealPath = (Join-Path $Destination $leafName)
    # copy the module into destionation in case not already exist
    if (-not(Test-Path $modulRealPath)) {
        Write-Host "copying module: $Name into: $Destination...`n"
        Copy-Item "$Name" -Destination "$Destination" -Recurse
        Write-Host "copied.`n"
    }
    # update the rootModule to the path of the file in the new location
    Update-ModuleManifest -Path "$modulRealPath\$leafName.psd1"  -RootModule $PSScriptRoot\$leafName.psm1 -FunctionsToExport "*" -CmdletsToExport "*" -VariablesToExport "*" -AliasesToExport "*" -Verbose
    # Import the module from the custom directory.
    Import-Module -Force $modulRealPath
    Write-Host " and... imported! `n" -ForegroundColor Green
    Write-Host "finished the dev environment build.`n"
}
function isInternetConnected {
    try {
        Invoke-RestMethod -Uri ('https://ipinfo.io/')
        return $true
    } catch {
        return $false
    }
}


function CreateDesktopShortcuts {
    Write-Host "Adding GodMode shortcut to desktop"
    $godmodeSplat = @{
        Path     = "$env:USERPROFILE\Desktop"
        Name     = "GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}"
        ItemType = "Directory"
    }
    $null = New-Item @godmodeSplat -Force

    #Creating desktop shortcuts
    if ((Test-Path -Path "$env:USERPROFILE\Desktop\Build.lnk", "$env:USERPROFILE\Desktop\Audit.lnk", "$env:USERPROFILE\Desktop\Analyze.lnk", "$env:USERPROFILE\Desktop\Attack.lnk") -match "False") {
        Write-Host "[Success] Creating desktop shorcuts for cyberAuditTool modules" -ForegroundColor Green
        $null = CreateShortcut -name "Build" -Target "$env:windir\System32\WindowsPowerShell\v1.0\powershell.exe" -Arguments "-ExecutionPolicy Unrestricted -File `"$PSScriptroot\cyberBuild.ps1`"" -OutputDirectory "C:\Users\Public\Desktop" -IconLocation "$PSScriptroot\CyberBlackIcon.ico" -Description "CyberAuditTool Powershell Edition" -Elevated
        $null = CreateShortcut -name "Audit" -Target "$env:windir\System32\WindowsPowerShell\v1.0\powershell.exe" -Arguments "-ExecutionPolicy Unrestricted -File `"$PSScriptroot\CyberAudit.ps1`"" -OutputDirectory "C:\Users\Public\Desktop" -IconLocation "$PSScriptroot\CyberRedIcon.ico" -Description "CyberAuditTool Powershell Edition" -Elevated
        $null = CreateShortcut -name "Analyze" -Target "$env:windir\System32\WindowsPowerShell\v1.0\powershell.exe" -Arguments "-ExecutionPolicy Unrestricted -File `"$PSScriptroot\cyberAnalyzers.ps1`"" -OutputDirectory "C:\Users\Public\Desktop" -IconLocation "$PSScriptroot\CyberGreenIcon.ico" -Description "CyberAuditTool Powershell Edition" -Elevated
        $null = CreateShortcut -name "Attack" -Target "$env:windir\System32\WindowsPowerShell\v1.0\powershell.exe" -Arguments "-ExecutionPolicy Unrestricted -File `"$PSScriptroot\cyberAttack.ps1`"" -OutputDirectory "C:\Users\Public\Desktop" -IconLocation "$PSScriptroot\CyberYellowIcon.ico" -Description "CyberAuditTool Powershell Edition" -Elevated
    }
}

function ShowMenu {
    $menuColor = New-Object System.Collections.ArrayList
    for ($i = 0; $i -lt 100; $i++) {
        $null = $menuColor.Add("White")
    }
    
    do {
        #Create the main menu
        Write-Host ""
        Write-Host "************************************************************************          " -ForegroundColor White
        Write-Host "*** Cyber Audit Tool (Powershell Edition) - ISRAEL CYBER DIRECTORATE ***          " -ForegroundColor White
        Write-Host "************************************************************************          " -ForegroundColor White
        Write-Host ""
        Write-Host "     install OS minimal requirements and Applications:                            " -ForegroundColor White
        Write-Host ""
        Write-Host "     Baseline folder is $PSScriptroot                                             " -ForegroundColor yellow
        Write-Host ""
        Write-Host "     0. Dev options	| Enter developers menu includes implementation & debugging options" -ForegroundColor $menuColor[0]
        Write-Host "     1. OS	    	| Check Windows version and upgrade it to latest build and update " -ForegroundColor $menuColor[1]
        Write-Host "     2. PS and .Net	| Check and Update Powershell and .Net framework versions     " -ForegroundColor $menuColor[2]
        Write-Host "     3. RSAT		| Install Microsoft Remote Server Administration Tool         " -ForegroundColor $menuColor[3]
        Write-Host "     4. PSGallery	| Install PowerShell Modules from Powershell gallery          " -ForegroundColor $menuColor[4]
        Write-Host "     5. Scoop		| Install Scoop framework                                     " -ForegroundColor $menuColor[5]
        Write-Host "     6. Utilities	| Install Buckets and utilities Applications                  " -ForegroundColor $menuColor[6]
        Write-Host "     7. Collectors	| Install Collector Applications                              " -ForegroundColor $menuColor[7]
        Write-Host "     8. Analyzers	| Install Analyzers and Reporting tools                       " -ForegroundColor $menuColor[8]
        Write-Host "     9. Attack!  	| Install attacking and Exploiting Scripts and tools          " -ForegroundColor $menuColor[9]
        Write-Host "    10. Update   	| Update scoop applications and powershell modules            " -ForegroundColor $menuColor[10]
        Write-Host "    11. Licenses   	| Install or Create Licenses to/from license files            " -ForegroundColor $menuColor[11]
        Write-Host "    12. Uninstall  	| Uninstall scoop applications and powershell modules         " -ForegroundColor $menuColor[12]
        Write-Host "    13. Backup  	| Compress and Backup all Audit folders and Files             " -ForegroundColor $menuColor[13]
        Write-Host "    14. Linux   	| Install Windows Subsystem for Linux                         " -ForegroundColor $menuColor[14]
        Write-Host "    15. RAM     	| Schedule Trimming of processes working sets and release RAM " -ForegroundColor $menuColor[15]
        Write-Host "    16. ShrinkVM   	| Shrink the VM for easy cloning or copying to another machine" -ForegroundColor $menuColor[16]
        Write-Host "    17. Offline CAT	| Export/Import CAT and fix Scoop paths                       " -ForegroundColor $menuColor[17]
        Write-Host "    18. HIBP DB    	| Download `"Have I Been Pwnd`" leaked passwords hashes DB      " -ForegroundColor $menuColor[17]
        Write-Host ""
        Write-Host "    99. Quit                                                                      " -ForegroundColor White
        Write-Host ""
        $userInput = Read-Host "Select Script Number"
    
        [boolean]$WaitForInput = $True
    
        switch ($userInput) {
            #Check Windows OS and build versions and if needed it can help upgrade an update latest build
            0 { DevMenu; $WaitForInput = $false }

            #Check Windows OS and build versions and if needed it can help upgrade an update latest build
            1 { OSCheck; $WaitForInput = $false }
    
            #Check Powershell and .Net versions and install if needed and add turn on more features
            2 { PSCheck; break }
    
            #Install RSAT
            3 { RSATInstall; break }
    
            #Install PowerShell Modules from PSGallery Online
            4 { PSGalleryInstall; break }
    
            #Install scoop
            5 { ScoopInstall; break }
    
            #Add buckets and isntall global utilities
            6 { UtilitiesInstall; break }
    
            #Install audit applications from cyberauditbucket
            7 { InstallCollectors; break }
    
            #Install Analyzers and Reporting applications from cyberauditbucket
            8 { InstallAnalyzers; break }
    
            #Install Attacking scripts and tools
            9 { InstallAttacks; break }
    
            #Update scoop, Powershell and applications
            10 { UpdateScoop; break }
    
            #Licenses
            11 { Licenses; break }
    
            #Uninstal scoop utilities, applications and scoop itself
            12 { Uninstall; $WaitForInput = $false }
    
            #Backup
            13 { BackupAudits; break }
    
            #Windows Subsystem for Linux
            14 { WindowsSubsystem; break }
            
            #RAM
            15 { RAM; break }
            
            #Shrink VM
            16 { ShrinkVM; break }

            # Export and import CAT
            17 { OfflineCAT; $WaitForInput = $false }
            
            # Download `"Have I Been Pwnd`" leaked passwords hashes DB for Get-bADPasswords script
            18 { DownloadHIBPDB }
            #Menu End
        }
        if ($WaitForInput) {
            read-host "Press ENTER to continue" 
        }
        Clear-Host
        $WaitForInput = $True
    } while ($userInput -ne '99')    
}

function DevMenu {
    $menuColor = New-Object System.Collections.ArrayList
    for ($i = 0; $i -lt 100; $i++) {
        $null = $menuColor.Add("White")
    }
    
    do {
        #Create the main menu
        Write-Host ""
        Write-Host "************************************************************************          " -ForegroundColor White
        Write-Host "*** Cyber Audit Tool (Powershell Edition) - ISRAEL CYBER DIRECTORATE ***          " -ForegroundColor White
        Write-Host "************************************************************************          " -ForegroundColor White
        Write-Host ""
        Write-Host "     install Developer Features:                            " -ForegroundColor White
        Write-Host ""
        Write-Host "     Baseline folder is $PSScriptroot                                             " -ForegroundColor yellow
        Write-Host ""
        Write-Host "     1. Export cyberFunctions | create all cyberFunctions methods global and readable by IDE." -ForegroundColor $menuColor[1]
        Write-Host ""
        Write-Host "    99. Quit                                                                      " -ForegroundColor White
        Write-Host ""
        $userInput = Read-Host "Select Script Number"
    
        [boolean]$WaitForInput = $True
    
        switch ($userInput) {
            # copy local cyber functions module into the PSModulePath, update the rootModule and import the module
            1 { copy-ModuleToDirectory -Name "$PSScriptRoot\CyberFunctions"; $WaitForInput = $false }
        }
        if ($WaitForInput) {
            read-host "Press ENTER to continue" 
        }
        Clear-Host
        $WaitForInput = $True
    } while ($userInput -ne '99')        
}

function OSCheck() {
    <#
    .SYNOPSIS
            Check Windows OS and build versions and if needed it can help upgrade an update latest build
    .DESCRIPTION
            Check Windows OS and build versions and if needed it can help upgrade an update latest build
    #>

    $help = @"

        OS
        --

        Checks Windows version and upgrade it to latest build and update.
                
"@

    Write-Host $help
    $menuColor[1] = "Yellow"
    if (!(isInternetConnected)) {
        # internet is down or corporation Firewall is blocking ICMP protocol
        Write-Host "Internet is down, Please connect and try again" -ForegroundColor Red
    } else {
        Write-Host "Internet is up, you can continue with installation" -ForegroundColor Green
    }
    if (([System.Environment]::OSVersion.Version.Major -lt 10)) {
        write-host "CyberAuditTool requires Windows 10 or later Operating systems, your system does not qualify with that, please upgrade the OS before continuing" -ForegroundColor Red
    } else {
        write-host "Operating System Version is OK so we now test Build number" -ForegroundColor Green
    }
    if (((Get-WmiObject -class Win32_OperatingSystem).Version -lt "10.0.17763")) {
        write-host "Minimal Windows 10 build version was not detected, please upgrade the OS before continuing" -ForegroundColor Red
    } else {
        write-host "OS build version is OK, you can continue installation without upgrade" -ForegroundColor Green
    }
    $update = Read-Host "Press [R] to Upgrade or [U] to update windows (Enter to continue doing nothing)"
    if ($update -eq "U") {
        Install-Module -Name PSWindowsUpdate -Scope AllUsers
        Import-Module -Name PSWindowsUpdate
        Add-WUServiceManager -ServiceID "7971f918-a847-4430-9279-4a52d1efe18d" -AddServiceFlag 7
        Get-WindowsUpdate
        Get-WUInstall -AcceptAll -IgnoreReboot
    }
    if ($update -eq "R") {
        try {

            # Declarations
            [string]$DownloadDir = 'C:\Temp\Windows_FU\packages'
            [string]$LogDir = 'C:\Temp\Logs'
            [string]$LogFilePath = [string]::Format("{0}\{1}_{2}.log", $LogDir, "$( get-date -format `"yyyyMMdd_hhmmsstt`" )", $MyInvocation.MyCommand.Name.Replace(".ps1", ""))
            [string]$Url = 'https://go.microsoft.com/fwlink/?LinkID=799445'
            [string]$UpdaterBinary = "$( $DownloadDir )\Win10Upgrade.exe"
            [string]$UpdaterArguments = '/quietinstall /skipeula /auto upgrade /copylogs $LogDir'
            [System.Net.WebClient]$webClient = New-Object System.Net.WebClient

            # Here the music starts playing .. 
            Write-Log -Message ([string]::Format("Info: Script init - User: {0} Machine {1}", $env:USERNAME, $env:COMPUTERNAME))
            Write-Log -Message ([string]::Format("Current Windows Version: {0}", [System.Environment]::OSVersion.ToString()))

            # Check if folders exis
            if (!(Test-Path $DownloadDir)) {
                New-Item -ItemType Directory -Path $DownloadDir
            }
            if (!(Test-Path $LogDir)) {
                New-Item -ItemType Directory -Path $LogDir
            }
            if (Test-Path $UpdaterBinary) {
                Remove-Item -Path $UpdaterBinary -Force
            }
            # Download the Windows Update Assistant
            Write-Log -Message "Will try to download Windows Update Assistant.."
            $webClient.DownloadFile($Url, $UpdaterBinary)

            # If the Update Assistant exists -> create a process with argument to initialize the update process
            if (Test-Path $UpdaterBinary) {
                Start-Process -FilePath $UpdaterBinary -ArgumentList $UpdaterArguments -Wait
                Write-Log "Fired and forgotten?"
            } else {
                Write-Log -Message ([string]::Format("ERROR: File {0} does not exist!", $UpdaterBinary))
            }
        } catch {
            Write-Log -Message $_.Exception.Message
            Write-Error $_.Exception.Message
        }
    }
}

function PSCheck {
    <# 
    .SYNOPSIS
        Check Powershell and .Net versions and install if needed and add turn on more features
     #>
    $menuColor[2] = "Yellow"
    CheckPowershell             # check and ask for upgrading in case required
    CheckDotNet                 # check  and install in case required
    # install .net fit version
    Write-Host "Downloading and installing .NET Core 3.1 SDK (v3.1.201) Windows x64"
    &powershell -NoProfile -ExecutionPolicy unrestricted -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; &([scriptblock]::Create((Invoke-WebRequest -UseBasicParsing 'https://dot.net/v1/dotnet-install.ps1')))"
    activateWinOptFeatures      # enable required optional features according to the installed OS
}

function RSATInstall {
    <# 
    .SYNOPSIS
        Install RSAT
    #>
    $help = @"

        RSAT
        ----

        Remote Server Administration Tools for Windows 10 includes Server Manager,
        Microsoft Management Console (MMC) snap-ins, consoles, Windows PowerShell cmdlets and providers,
        and command-line tools for managing roles and features that run on Windows Server.

        Starting with Windows 10 October 2018 Update, you can manually add RSAT tools right from Windows 10.
        Just go to "Manage optional features" in Settings and click "Add a feature" to see the list of available RSAT tools.

        The downloadable packages above can still be used to install RSAT on Windows 10 versions prior to the October 2018 Update.
        https://www.microsoft.com/en-us/download/details.aspx?id=45520

        This script can automatically install RSAT features for Windows 10 1809/1903/1909/2004/20H2
        with all features online from Microsoft Update site.

"@
    Write-Host $help
    $menuColor[3] = "Yellow"

    $userInput = Read-Host "Press [A] to install RSAT automatically or [Enter] to skip and manually install it"
    if ($userInput -eq "A") {

        $ScriptToRun = $PSScriptRoot + "\CyberInstall-RSATv1809v1903v1909v2004v20H2.ps1"
        &$ScriptToRun -ALL
        $testPendingReboot = Test-PendingRebootRegistry
        if ($testPendingReboot -eq $true) {
            Write-Host "Reboots are pending after RSAT was installed, Please restart the computer and continue with C.A.T next build phase " -ForegroundColor Yellow
        }
    } else {
        failed "You have decided to manually install RSAT, please note that if you will not install is C.A.T will not operate properly"
    }
}

function PSGalleryInstall {
    <# 
    .SYNOPSIS
        Install PowerShell Modules from PSGallery Online
    #>
    $help = @"

        PSGallery
        ---------

        Install PowerShell Modules from Powershell gallery.

        Modules that will be Installed:

"@
    Write-Host $help
    foreach ($psm in $PSGModules) {
        write-host "        - $psm"
    }
    $menuColor[4] = "Yellow"
    Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
    Install-PackageProvider Nuget -Force
    Install-Module -Name PowerShellGet -Force -AllowClobber -Scope AllUsers
    
    foreach ($PSGModule in $PSGModules) {
        if ($PSGModule -eq "7Zip4PowerShell") {
            Write-Host "installing standard lib package"
            #Install-Package PowerShellStandard.Library -Version 5.1.0
            Write-Host "Installing module $PSGModule"
            Install-Module -Name 7Zip4Powershell -Scope AllUsers -AllowClobber -Force 
            Import-Module "$PSGModule"
            Write-Host "Imported module: $PSGModule"
        } else {
            Write-Host "Installing module $PSGModule"
            Install-Module -Name $PSGModule -AllowClobber -Force -Scope AllUsers
            Import-Module "$PSGModule"
            Write-Host "Imported module: $PSGModule"
        }
    }

    #Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false
    #success "These powershell modules are installed"
    #Get-Module
    #Write-Host "Saving powershell modules needed for offline running on remote machines"
    #foreach ($PSGModule in $PSGModulesOffline)
    #{
    #
    #    Save-Module -Name $PSGModulesOffline -Path $PowerShellsDir -Repository PSGallery -Force
    #}
    #$null = Start-Process -PassThru explorer $PowerShellsDir
}

function ScoopInstall {
    <# 
    .SYNOPSIS
        Install scoop
    #>
    $help = @"

        Scoop
        ---------

        installs programs from the command line with a minimal amount of friction.

        Tries to eliminate things like:
        - Permission popup windows
        - GUI wizard-style installers
        - Path pollution from installing lots of programs
        - Unexpected side-effects from installing and uninstalling programs
        - The need to find and install dependencies
        - The need to perform extra setup steps to get a working program

        Minimal requirement is PowerShell 5 (or later, include PowerShell Core) and .NET Framework 4.5 (or later).

"@
    Write-Host $help
    $menuColor[5] = "Yellow"
    Write-Host "Backing up Environment Variables before installing scoop"
    regedit /e $PSScriptRoot\HKEY_CURRENT_USER.reg "HKEY_CURRENT_USER\Environment"
    regedit /e $PSScriptRoot\HKEY_LOCAL_MACHINE.reg "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
    $env:SCOOP_GLOBAL = "$tools\GlobalScoopApps"
    [Environment]::SetEnvironmentVariable("SCOOP_GLOBAL", $env:SCOOP_GLOBAL, "Machine")
    $env:SCOOP = $scoopDir
    [Environment]::SetEnvironmentVariable("SCOOP", $env:SCOOP, "MACHINE")
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-Expression (new-object net.webclient).downloadstring("https://get.scoop.sh")
    $Reg = "Registry::HKLM\System\CurrentControlSet\Control\Session Manager\Environment"
    $OldPath = (Get-ItemProperty -Path $Reg -Name PATH).Path
    $NewPath = "$OldPath;$scoopDir\shims"
    Set-ItemProperty -Path $Reg -Name PATH -Value $NewPath
    $CurrentValue = [Environment]::GetEnvironmentVariable("PSModulePath", "Machine")
    [Environment]::SetEnvironmentVariable("PSModulePath", "$CurrentValue;$scoopDir\modules", "Machine")
    scoop install aria2 7zip innounp dark -g
    scoop config aria2-enabled false
    scoop install git -g
    #Write-Host "We will not install openssh untill there is a fix with bucket!!!!" -ForegroundColor Red
    scoop install win32-openssh -g
    #scoop install OpenSSH -g
    scoop install sudo -g
    [environment]::setenvironmentvariable('GIT_SSH', (resolve-path (scoop which ssh)), 'MACHINE')
    Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value 1
    scoop checkup
    scoop status
    scoop update
    #sudo Add-MpPreference -ExclusionPath 'C:\CAT2020\Tools\GlobalScoopApps'
        
    
}

function UtilitiesInstall {
    <# 
    .SYNOPSIS
        Add buckets and isntall global utilities
    #>
    $help = @"

        Scoop buckets and Utilities
        ---------------------------

        In Scoop, buckets are collections of applications.
        a bucket is a Git repository containing JSON app manifests
        which describe how to install an applications.

        In order to support the functionality of the Cyber Audit tool,
        we will install some utilities.

        Utilities installed:
"@
    Write-Host $help
    foreach ($utility in $utilities) {
        write-host "- $utility"
    }
    $menuColor[6] = "Yellow"

    scoop bucket add extras
    scoop bucket add java
    scoop bucket add versions
    scoop bucket add CyberAuditBucket https://github.com/contigon/CyberAuditBucket.git
    scoop bucket list
    foreach ($utility in $utilities) {
        scoop install $utility -g
    }

    #intall python third party modules required for some scripts
    SetPythonVersion "2"
    python -m pip install --upgrade pip --progress-bar = off
    foreach ($pip in $pips) {
        pip install $pip --progress-bar = off
    }
}

function InstallCollectors() {
    <# 
    .SYNOPSIS
        Install audit applications from cyberauditbucket
    #>
    $help = @"

        Applications
        ------------

        The next phase will install the audit applications.

        Audit applications will collect the data which will be offline analyzed
        in the Analyzers phase in order to create the audit report.

        Applications installed:
"@
    Write-Host $help
    foreach ($CollectorApp in $CollectorApps) {
        write-host "- $CollectorApp"
    }
    $menuColor[7] = "Yellow"
    #(Get-ChildItem $scoopDir\buckets\CyberAuditBucket -Filter *.json).BaseName|ForEach-Object {scoop install $_ -g}
    foreach ($CollectorApp in $CollectorApps) {
        if ( $CollectorApp -ne "LynisPacked") {
            scoop install $CollectorApp -g
        } else {
            try {
                $LynisDownloadURL = "https://raw.githubusercontent.com/contigon/Downloads/master/lynis-remote.tgz"
                dl $LynisDownloadURL "$psscriptroot\Tools\Lynis\lynis-remote.tgz"
                Write-Host "Lynis downloaded successfully"
            } catch {
                Write-Host "Error at Lynis downloading" -ForegroundColor Red                
            }
        }
    }
    $c = scoop list 6>&1
    $i = 0
    foreach ($f in $c) {
        $i++
        if ($( $foreach.current ) -match 'failed') {
            if ($c[$i - 2].ToString() -match "global") {
                Write-Host $c[$i - 4].ToString() "--> global app installation failed, we will try to Uninstall and reinstall"
                scoop Uninstall $c[$i - 4].ToString() -g
                scoop install $c[$i - 4].ToString() -g
            } else {
                Write-Host $c[$i - 3].ToString() "--> app installation failed, we will try to Uninstall and reinstall"
                scoop Uninstall $c[$i - 3].ToString()
                scoop install $c[$i - 3].ToString()
            }
        }
    }
}

function InstallAnalyzers {
    <# 
    .SYNOPSIS
        Install Analyzers and Reporting applications from cyberauditbucket
    #>
    $help = @"

        Analyzers
        ---------

        The next phase will install the Analyzers applications.

        Analyzer applications will be used to process the data collected during
        the audit phase.

        Applications installed:
"@
    Write-Host $help
    foreach ($AnalyzerApp in $AnalyzerApps) {
        write-host "- $AnalyzerApp"
    }
    $menuColor[8] = "Yellow"
    #(Get-ChildItem $scoopDir\buckets\CyberAuditBucket -Filter *.json).BaseName|ForEach-Object {scoop install $_ -g}
    foreach ($AnalyzerApp in $AnalyzerApps) {
        if ($AnalyzerApp -eq "vista_proba_free") {
            $userInput = Read-Host "Press [Y] to download $AnalyzerApp rainbow table for Ophcrack (or Enter to continue and download it later)"
            if ($userInput -eq "Y") {
                scoop install $AnalyzerApp -g
                scoop update $AnalyzerApp -g
            } else {
                Write-Host "You can download any rainbow table for Ophcrack manually from:" -ForegroundColor Yellow
                Write-Host "https://ophcrack.sourceforge.io/tables.php" -ForegroundColor Yellow
            }
        } else {
            scoop install $AnalyzerApp -g
            scoop update $AnalyzerApp -g
        }
    }
    foreach ($GPOBaseline in $GPOBaselines) {
        scoop install $GPOBaseline -g
    }
    $c = scoop list 6>&1
    $i = 0
    foreach ($f in $c) {
        $i++
        if ($( $foreach.current ) -match 'failed') {
            if ($c[$i - 2].ToString() -match "global") {
                Write-Host $c[$i - 4].ToString() "--> global app installation failed, we will try to Uninstall and reinstall"
            } else {
                Write-Host $c[$i - 3].ToString() "--> app installation failed, we will try to Uninstall and reinstall"
            }
        }
    }
    $c = scoop list 6>&1
    $i = 0; foreach ($f in $c) {
        $i++
        if ($( $foreach.current ) -match 'failed') {
            if ($c[$i - 2].ToString() -match "global") {
                scoop Uninstall $c[$i - 4].ToString() -g
                scoop install $c[$i - 4].ToString() -g
            } else {
                scoop Uninstall $c[$i - 3].ToString()
                scoop install $c[$i - 3].ToString()
            }

            Write-Host "Installing Microtosft AppInspector tool"
            if ((dotnet --version) -ge "3.1.200") {
                $a = appdir("appinspector")
                push-Location $a
                $cmd1 = "dotnet build"
                $cmd2 = "dotnet.exe tool install --global Microsoft.CST.ApplicationInspector.CLI --version 1.4.7" 
                Invoke-Expression $cmd1
                Invoke-Expression $cmd2
                Pop-Location            

            } else {
                Write-Host "[Failed] You dont have .Net core SDK installed, Please install and try again" -ForegroundColor Red
            }
        }
    }
}
function InstallAttacks {
    <# 
    .SYNOPSIS
        Install Attacking scripts and tools
    #>
    $menuColor[9] = "Yellow"
    #(Get-ChildItem $scoopDir\buckets\CyberAuditBucket -Filter *.json).BaseName|ForEach-Object {scoop install $_ -g}
    foreach ($AttackApp in $AttackApps) {
        scoop install $AttackApp -g
    }
    $c = scoop list 6>&1
    $i = 0
    foreach ($f in $c) {
        $i++
        if ($( $foreach.current ) -match 'failed') {
            if ($c[$i - 2].ToString() -match "global") {
                Write-Host $c[$i - 4].ToString() "--> global app installation failed, we will try to Uninstall and reinstall"
                scoop Uninstall $c[$i - 4].ToString() -g
                scoop install $c[$i - 4].ToString() -g
            } else {
                Write-Host $c[$i - 3].ToString() "--> app installation failed, we will try to Uninstall and reinstall"
                scoop Uninstall $c[$i - 3].ToString()
                scoop install $c[$i - 3].ToString()
            }
        }
    }    
}

function UpdateScoop {
    <# 
    .SYNOPSIS
        Update scoop, Powershell and applications
    #>
    $help = @"

    Update
    ------
    
    - Update core audit scripts
    - Update scoop and buckets
    - Update Powershell modules
    - Check if there is a newer powershell version
    - AutoUpdate PingCastle

"@
    Write-Host $help
    $menuColor[10] = "Yellow"
    Write-Host "Updating the core CyberAuditTool scripts"
    $FileName = "go.pdf"
    $zipURLB = ""
    $zipURLA = "https://raw.githubusercontent.com/contigon/CATInstall/master/$FileName"
    $FilesToUpdate = (
        "cyberAnalyzers.ps1",
        "cyberAudit.ps1",
        "cyberAuditRemote.ps1",
        "cyberBuild.ps1",
        "cyberAttack.ps1",
        "CyberCollectNetworkConfig.ps1",
        "CyberCollectNetworkConfigV2.ps1",
        "CyberCompressGo.ps1",
        "CyberCreateRunecastRole.ps1",
        "CyberFunctions.ps1",
        "CyberLicenses.ps1",
        "CyberPasswordStatistics.ps1",
        "CyberUserDumpStatistics.ps1",
        "CyberPingCastle.ps1",
        "go.ps1",
        "CyberMisc.ps1",
        "CyberReport.ps1",
        "CyberOfflineNTDS.ps1",
        "CyberGPLinkReport.ps1",
        "CyberInstall-RSATv1809v1903v1909v2004v20H2.ps1",
        "CyberRamTrimmer.ps1",
        "Scuba2CSV.py",
        "CyberRiskCompute.xlsx",
        "CyberAuditPrep.xlsx",
        "CyberAuditDevelopersHelp.txt",
        "CyberBginfo.bgi",
        "Bginfo64.exe",
        "CyberRedIcon.ico",
        "CyberBlackIcon.ico",
        "CyberGreenIcon.ico",
        "CyberYellowIcon.ico"
    )

    #Remove-Item "$PSScriptRoot\$FileName" -Force
    try {
        $zipfile = "$PSScriptRoot\$FileName"
        Write-Host "Trying to Download Cyber Audit Tool Updates from $zipurlA to $PSScriptRoot"
        dl $zipurlA $zipfile
    } catch {
        Write-Host "[Failed] Error connecting to 1st download site, trying 2nd download option"
        $zipfile = "$PSScriptRoot\$FileName"
        Write-Host "Trying to Download Cyber Audit Tool Updates from $zipurlB to $PSScriptRoot"
        dl $zipurlB $zipfile
    }
    Write-Output 'Extracting Cyber Audit Tool core files updates...'
    New-Item -Path "$PSScriptRoot\update" -ItemType directory | Out-Null
    Add-Type -Assembly "System.IO.Compression.FileSystem"
    [IO.Compression.ZipFile]::ExtractToDirectory($zipfile, "$PSScriptRoot\update")

    #replace only newer files
    $FilesToUpdate | ForEach-Object {
        if ((Get-Item $psscriptroot\$_).LastWriteTime -lt (Get-Item $psscriptroot\update\$_).LastWriteTime) {
            Write-host "[Update Available] $_" -ForegroundColor Red; Copy-Item "$psscriptroot\update\$_" -Destination "$psscriptroot\$_" -Force
        } else {
            Write-host "[No Updates] $_" -ForegroundColor Green
        }
    }
    Remove-Item -Path "$PSScriptRoot\update" -Recurse -Confirm:$false -Force

    Write-Output 'Updating Scoop and applications...'
    scoop status
    scoop update * --global
    scoop checkup
    scoop cleanup * --cache

    Write-Output 'Checking and installing Updates of Powershell Modules, This can take some time...'
    Get-InstalledModule | ForEach-Object {
        $PSModule = (find-module $_.name).version; if ($PSModule -ne $_.version) {
            Write-host "Module:$( $_.name ) Installed Version:$( $_.version ) Last Version:$PSModule" -ForegroundColor Yellow; Update-Module $_.name -Force
        } else {
            Write-Host "$( $_.name ) $( $_.version ) is the latest" -ForegroundColor Green
        }
    }

    Write-Output 'checking .Net version so you can update it manually...'
    detect

    $pingcastlePath = scoop prefix pingcastle
    Push-Location $pingcastlePath
    PingCastleAutoUpdater
    Pop-Location

    #update metasploit
    Write-Host "In order to update Metasploit framework please make sure you disable any AntiMalware protection" -ForegroundColor Yellow
    $userInput = Read-Host "Press [M] if you want to update Metasploit framework or [Enter] to skip"
    if ($userInput -eq "M") {
        try {
            msfupdate
        } catch {
            failed "Metasploit is not installed so we can not update it"
        }
    }    
}

function Licenses {
    <# 
    .SYNOPSIS
        Install or Create Licenses to/from license files
    #>
    $help = @"

    Licenses
    --------
    
    Licenses will be stored in base64 encoding and then encrypted using a password that
    is specific for the encrypted Licenses file (Please write it down and do not forget!!!)

    All Licenses will be store in a compressed file downloaded from external URL before installed.

    During Installation phase you will be asked for the encryption password 
    and then the file will be encoded to the original license file which will then be copied
    to the correct application path.

    New Licenses can be added by editing the $PSScriptRoot\CyberLicenses.ps1 file.

"@
    Write-Host $help
    $menuColor[11] = "Yellow"
    scoop install CATLicenses --global
    $ScriptToRun = $PSScriptRoot + "\CyberLicenses.ps1"
    &$ScriptToRun    
}

function Uninstall {
    <# 
    .SYNOPSIS
        Uninstall scoop applications and powershell modules
    #>

    
    $help = @"

    Uninstall
    --------

    You are leaving us? o_O

    Ok, Choose script to Uninstall:
    1. Scoop utilities
    2. Scoop itself
    3. Audit, Analyzer and Attack applications
    4. Powershell Modules
    5. neo4j service
    6. use restore point to remove all installations
       and changes to the operating system and registry keys.

    99. nothing

"@
    Write-Host $help
    $userInput = Read-Host "Select Script Number (you can combine scripts numbers and they all will be run continously)" 
    $menuColor[12] = "Yellow"
    $UninstallDoWhileFlag = $true
    do {
        switch -Wildcard ($userInput) {
            '*1*' {
                (Get-ChildItem $bucketsDir\CyberAuditBucket -Filter *.json).BaseName | ForEach-Object { scoop Uninstall $_ -g }
                foreach ($utility in $utilities) {
                    scoop Uninstall $utility -g
                }
            }
            '*2*' {
                scoop Uninstall scoop
                Remove-Item $scoopDir -Recurse -ErrorAction Ignore
            }
            '*3*' {
                $AtLeastOneLinkRemoved = $false
                # Delete desktop shorcuts
                if (Test-Path -Path "$env:USERPROFILE\Desktop\GodMode.'{ED7BA470-8E54-465E-825C-99712043E01C}'") {
                    $cmd = "Remove-Item $env:USERPROFILE\Desktop\GodMode.'{ED7BA470-8E54-465E-825C-99712043E01C}'"
                    Invoke-Expression $cmd
                    $AtLeastOneLinkRemoved = $true
                }
                foreach ($link in $DesktopLinks) {                
                    if (Test-Path -Path "$env:USERPROFILE\Desktop\$link.lnk") {
                        $cmd = "Remove-Item $env:USERPROFILE\Desktop\$link.lnk -Force"
                        Invoke-Expression $cmd
                        $AtLeastOneLinkRemoved = $true
                    }
                }
                if ( $AtLeastOneLinkRemoved) {
                    Write-Host '`nLinks removed seccessfuly' -ForegroundColor Green
                } else {
                    Write-Host 'No links found to remove ¯\_(ツ)_/¯' -ForegroundColor DarkYellow
                }
            }
            '*4*' {

                $TestimoModules = @('Testimo', 'PSWinDocumentation.AD', 'PSWinDocumentation.DNS', 'ADEssentials', 'PSSharedGoods', 'PSWriteColor', 'Connectimo', 'DSInternals', 'Emailimo', 'PSWriteHTML' )
                foreach ($Module in $TestimoModules) {
                    Uninstall-Module $Module -Force -AllVersions
                }
                Remove-Module Microsoft.ActiveDirectory.Management -Verbose
                if (Test-Path $PSScriptRoot\HKEY_CURRENT_USER.reg) {
                    reg import $PSScriptRoot\HKEY_CURRENT_USER.reg
                    reg import $PSScriptRoot\HKEY_LOCAL_MACHINE.reg
                }
                $a = appdir("appinspector")
                Set-Location $a
                $cmd = "dotnet.exe tool Uninstall --global Microsoft.CST.ApplicationInspector.CLI"
                Invoke-Expression $cmd
                Pop-Location
            }
            '*5*' {
                $cmd = "neo4j uninstall-service"
                Invoke-Expression $cmd
            }
            '*6*' {
                Get-ComputerRestorePoint
                $resPoint = Read-Host "Input the Sequence Number of the restore point you want to revert to (or Enter to continue)"
                if ($resPoint -gt 0) {
                    Restore-Computer -RestorePoint $resPoint -Confirm -ErrorAction SilentlyContinue
                }
                Get-ComputerRestorePoint -LastStatus   
            }
            Default {
                Write-Host "`nOK, we are glad to see you are stiil like us"
            }
        }
        $userInput = Read-Host "
Want to delete another things?
Enter the scripts numbers to continue
Or leave it blank for exit to main menu"
        if ($userInput -notlike "") {
            $UninstallDoWhileFlag = $false
        }
    }while ($UninstallDoWhileFlag)     
}

function BackupAudits {
    <# 
    .SYNOPSIS
        Compress and Backup all Audit folders and Files
    #>
    $src = "$PSScriptRoot\$env:Computername\"
    $dst = "$PSScriptRoot\Backup\"
    $dt = CurrentDate
    $file = "$env:Computername(", $dt, ").7z" -join ""
    New-Item -Path $dst -ItemType Directory -Force
    Add-Type -AssemblyName 'System.Web'
    $minLength = 18 ## characters
    $maxLength = 24 ## characters
    $length = Get-Random -Minimum $minLength -Maximum $maxLength
    $nonAlphaChars = 5
    $pass = [System.Web.Security.Membership]::GeneratePassword($length, $nonAlphaChars)
    $compress = @{
        Path             = $src
        CompressionLevel = "Fastest"
        DestinationPath  = "$dst\$file"
    }

    $help = @"

        Backup
        ------
        
        This script will backup all collected audit files in order
        to analyze them later on.

        Source back up folder: $src
        Destination folder   : $dst 
        File Name            : $file

        ***********************************************
        Zip File is password protected, the password is

                -->    $pass    <--
                                          
        ***********************************************
"@
    Write-Host $help
    $menuColor[13] = "Yellow"
    #Compress-Archive @compress -Force
    $verify = Compress-7Zip -Path $src -ArchiveFileName "$dst\$file" -Format SevenZip -Password $pass -EncryptFilenames
    Write-Host "Backup file Password is: $pass" -ForegroundColor Yellow
    Get-7ZipInformation "$dst\$file" -Password $pass
    Write-Host $verify
    read-host "Press ENTER to continue"
    $null = start-Process -PassThru explorer $dst
    
}

function WindowsSubsystem {
    <# 
    .SYNOPSIS
        Install Windows Subsystem for Linux
    #>
    $help = @"

    Install the Windows Subsystem for Linux
    ---------------------------------------

    Install your Linux distribution of choice

"@
    Write-Host $help
    $menuColor[14] = "Yellow"
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
    wsl --set-default-version 2
}
function RAM {
    <# 
    .SYNOPSIS
        Schedule Trimming of processes working sets and release RAM
    #>
    $help = @"

    Reclaiming Unused Memory
    ------------------------

    processes can grab memory but not necessarily actually need to use it.

    Memory trimming is where the OS forces processes to empty their working sets.
    They don't just discard this memory, since the processes may need it at a later 
    juncture and it could already contain data,  instead the OS writes it to the page file
    for them such that it can be retrieved at a later time if required.

    https://guyrleech.wordpress.com/2018/03/15/memory-control-script-reclaiming-unused-memory/

"@
    Write-Host $help
    $menuColor[15] = "Yellow"
    $userInput = read-host "Input [T] to Trim RAM (Enter to continue doing nothing)"
    if ($userInput -eq "T") {
        $scripttorun = $PSScriptRoot + "\CyberRamTrimmer.ps1"
        &$scripttorun
    }    
}

function ShrinkVM {
    <# 
    .SYNOPSIS
        Shrink the VM for easy cloning or copying to another machine
    #>
    $help = @"

    Shrink VM disk image
    --------------------

    In order to shrink the VM disk size these steps will be executed:
    
    1. Deleting scoop old applications version 
    2. Deleting scoop cached applications downloads
    3. Clear all windows event logs
    4. Run windows Disk Cleanup tool 
    5. Run ccleaner tool to clean registry and Temp files
    6. Manually clean and shrink the VM disk from the VMWARE Workstation menu: VM-->Manage-->Clean Up Disks
"@
    Write-Host $help
    $menuColor[16] = "Yellow"
    Write-Host "Deleting scoop old applications version"
    scoop cleanup * -g
    scoop cleanup *
    Write-Host "Deleting scoop cached applications downloads"
    scoop cache rm * -g
    scoop cache rm *
    Write-Host "Clearing all windows event logs"
    Wevtutil el | ForEach-Object { wevtutil cl $_ }
    write-host "Running the windows Disk Cleanup tool and removing files from the previous Windows installations/upgrades"
    $userInput = Read-Host "Press [M] for manually selecting what to clean or [A] for automatically cleaning"
    if ($userInput -eq "A") {
        cleanmgr.exe /autoclean
    } else {
        cleanmgr.exe
    }
    write-host "Running ccleaner tool to clean registry and Temp files"
    $userInput = Read-Host "Press [M] for manually selecting what to clean or [A] for automatically cleaning"
    if ($userInput -eq "A") {
        ccleaner /audo
    } else {
        ccleaner
    }
    Write-Host "Shut Down the VM and then from the VMWARE menu select: VM-->Manage-->Clean Up Disks" -ForegroundColor Yellow    
}
function OfflineCAT {
    & $PSScriptRoot\CyberExportCAT.ps1    
}

function DownloadHIBPDB {
    try {
        $GBPAppPath = Invoke-Expression "scoop prefix getbadpasswords"
        if (!(Test-Path $GBPAppPath)) {
            Write-Host "Get-bADPasswords is not installed. Please install it and come back after that" -ForegroundColor Red
            return
        }
        Write-Host "To download by torrent press [T], or press [H] to download by https"
        $userInput = Read-Host
        if ($userInput -eq "H") {
            $DBURL = 'https://downloads.pwnedpasswords.com/passwords/pwned-passwords-ntlm-ordered-by-hash-v8.7z'
        } elseif ($userInput -eq "T") {
            $DBURL = 'https://downloads.pwnedpasswords.com/passwords/pwned-passwords-ntlm-ordered-by-hash-v8.7z.torrent'
        } else {
            return
        }
        $dest = Join-Path -Path $GBPAppPath -ChildPath "Accessible\PasswordLists"
        DownloadWithAria2 -URL $DBURL -destFolder $dest
    } catch {
        Write-Host "error"
    }
    read-host "Press ENTER to continue"
}

$runningScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "Cyber Audit Tool 2021 [$runningScriptName]"

if (![Environment]::Is64BitProcess) {
    failed "OS architecture must be 64 bit, exiting ..."
    exit
}

CyberBginfo
DisableFirewall
DisableAntimalware
Set-ExecutionPolicy Unrestricted
. $PSScriptRoot\CyberInstall-RSATv1809v1903v1909v2004v20H2  # For Write-Log function
# Hide status bar of installing progress to reduce I/O calls for better performance
$global:progressPreference = 'SilentlyContinue'
proxydetect
Write-Host "Setting power scheme to High performance"
$cmd = "powercfg -s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
Invoke-Expression $cmd


#Checkpoint-Computer -Description 'before installing CyberAuditTool'

#InitializeVariables
#Create or Set the Script directory tree
$scoopDir = New-Item -Path $Tools -Name "\Scoop" -ItemType "directory" -Force
$SVNDir = New-Item -Path $Tools -Name "\SVN" -ItemType "directory" -Force
$PowerShellsDir = New-Item -Path $Tools -Name "\PowerShells" -ItemType "directory" -Force
$DownloadsDir = New-Item -Path $Tools -Name "\Downloads" -ItemType "directory" -Force

#Powershell Modules, Utilities and Applications that needs to be installed
#$PSGModules = @("Testimo","ImportExcel","Posh-SSH","7Zip4PowerShell","FileSplitter","PSWindowsUpdate","VMware.PowerCLI")
$PSGModules = @("Testimo", "ImportExcel", "Posh-SSH", "7Zip4PowerShell", "FileSplitter", "PSWindowsUpdate", "DSInternals")
$PSGModulesOffline = @("Testimo", "ImportExcel", "Posh-SSH", "7Zip4PowerShell", "FileSplitter")
$utilities = @("dotnet-sdk", "Net_Framework_Installed_Versions_Getter", "python27", "python39", "zulu11-jdk", "putty", "winscp", "vcredist2013", "nmap-portable", "rclone", "everything", "VoidToolsCLI", "notepadplusplus", "googlechrome", "firefox", "foxit-reader", "irfanview", "grepwin", "sysinternals", "snmpget", "wireshark")
$CollectorApps = @("ntdsaudit", "RemoteExecutionEnablerforPowerShell", "PingCastle", "goddi", "SharpHound", "Red-Team-Scripts", "Scuba-Windows", "azscan3", "LGPO", "grouper2", "Outflank-Dumpert", "lantopolog", "nessus", "NetScanner64", "AdvancedPortScanner", "skyboxwmicollector", "skyboxwmiparser", "skyboxwsuscollector", "PDQDeploy", "masscan", "LynisPacked", "zBang")
$GPOBaselines = @("PolicyAnalyzerSecurityBaseline")
$AnalyzerApps = @("PolicyAnalyzer", "SetObjectSecurity", "LGPO", "BloodHoundAD", "neo4j", "ophcrack", "hashcat", "rockyou", "vista_proba_free", "AppInspector")
$AttackApps = @("nirlauncher", "ruler", "ncat", "metasploit", "infectionmonkey")
$pips = @("colorama", "pysnmp", "win_unicode_console")
$pythonScripts = @("colorama", "pysnmp", "win_unicode_console")
$Licenses = @("AZScanKey.enc")
$DesktopLinks = @("Build", "Audit", "Analyze", "Attack")

CreateDesktopShortcuts

read-host "Press ENTER to continue (or Ctrl+C to quit)"

start-Transcript -path $PSScriptRoot\CyberBuildPhase.Log -Force -append

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Clear-Host

ShowMenu

stop-Transcript | out-null
