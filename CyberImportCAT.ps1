<#
    Import CAT and its Scoop, Scoop's tools, modules, and non-portable apps from a pre-made archive

    Configures scoop and its installed apps to be known by Windows, if they not installed in regular way,
    Scoop directory needs to be placed in ".\Tools\Scoop\apps\scoop".
    If you want more tools to be known, they and their shims have to be in ".\Tools\Scoop\"
    or in ".\Tools\GlobalScoopApps\" if they are global
#>
#requires -RunAsAdministrator
#Requires -Version 5.1
$Tools = "$PSScriptRoot\Tools"
$7z = $null

<#
.SYNOPSIS
Updates all shims in Tools\scoop and Tools\GlobalScoopApps path to the current absolute path
#>
function Update-Shims {
    for ($i = 0; $i -lt 2; $i++) {
        if ($i -eq 0) {
            $appsRelativePath = "\GlobalScoopApps"
            $whatShims = "global"
        } else {
            $appsRelativePath = "\Scoop"
            $whatShims = "local"
        }
        $shimsPath = "$tools$appsRelativePath\shims"
        $shimsToUpdate = Get-ChildItem -Path $shimsPath\* -Include *.shim, *.cmd 
        if ($shimsToUpdate.Length -eq 0) {
            Write-Host "Error: No $whatShims shims found" -ForegroundColor Red
        } else {            
            Write-Host "Updating $whatShims shims with this path:" -ForegroundColor Yellow
            Write-Host "$tools$appsRelativePath" -ForegroundColor Yellow
            foreach ($item in $shimsToUpdate) {
                if (($item.Name -like '*.shim') -or ($item.Name -like '*.cmd')) {
                    write-host $item.FullName -ForegroundColor Cyan
                    $file = $item.FullName
                    $regex = '.:\\.*Tools\\(GlobalScoopApps|Scoop)'
                    (Get-Content $file) -replace $regex, "$tools$appsRelativePath" | Set-Content $file
                }
            }    
        }   
    }
}
<#
.SYNOPSIS
Sets environmental variables $env:SCOOP_GLOBAL and $env:SCOOP to current absolute path
#>
function Set-Vars {
    Write-Host "Configuring environment variables..."
    $global:scoopDir = "$tools\Scoop"
    $env:SCOOP_GLOBAL = "$tools\GlobalScoopApps"
    [Environment]::SetEnvironmentVariable("SCOOP_GLOBAL", $env:SCOOP_GLOBAL, "Machine")
    $env:SCOOP = $scoopDir
    [Environment]::SetEnvironmentVariable("SCOOP", $env:SCOOP, "MACHINE")    

    Write-Host "Done. All global veriables are set to current absolute path:" -ForegroundColor Green
    Write-Host "$Tools" -ForegroundColor Green
}
<#
.SYNOPSIS
Update the PATH environmental variable to current scoop path
#>
function Register-Path {
    Write-Host "Removing previous scoop paths from PATH variable"
    $NewUserPATH = ([System.Environment]::GetEnvironmentVariable("Path", "user") -split ';' | Select-String -NotMatch "scoop") -join ';'
    $NewMachinePATH = ([System.Environment]::GetEnvironmentVariable("Path", "machine") -split ';' | Select-String -NotMatch "scoop") -join ';'
    # For this session
    $env:PATH = ($env:PATH -split ';' | Select-String -NotMatch "scoop") -join ';'
    # Globaly
    [environment]::setEnvironmentVariable("PATH", $NewMachinePATH, 'Machine')
    [environment]::setEnvironmentVariable("PATH", $NewUserPATH, 'user')

    Write-Host "Registering paths in PATH variable"
    try {
        . "$Tools\Scoop\apps\scoop\current\lib\core.ps1"
        . "$Tools\Scoop\apps\scoop\current\lib\install.ps1"
        Write-Host "Scoop modules imported" -ForegroundColor Green
    } catch {
        Write-Host "Scoop was not found where it supposed to be" -ForegroundColor Red
        Write-Host "Please place scoop folder in " -ForegroundColor Red -NoNewline
        Write-Host "$Tools\Scoop\apps\" -ForegroundColor Yellow
    }
    ensure_in_path $env:SCOOP_GLOBAL\shims $true
    ensure_in_path $env:SCOOP\shims

    Write-Host "Done. PATH environmental variable updated" -ForegroundColor Green
}
<#
.SYNOPSIS
The main function manages all importation proccess
#>
function Import-Scoop {
    Write-Host "`n"
    Write-Host "This will import CAT from a tar.xz file, and will register all Scoop's dependencies"
    Write-Host "------------------------------------------------------------------------------------"
    Write-Host ""

    $7z = Get-7z | ForEach-Object { $_.replace(' ', '` ') }

    
    # Show a GUI to choose the compressed file that supposed to contain the Tools
    Write-Host "A file selection window will be opened. Select the tar.xz compressed file"
    Read-Host "Press [ENTER] to continue"
    $compressedFilePath = Get-FileName  -Extensions "tar.xz" -ExtensionsExplain "tar.xz compressed files"
    
    # If user pressed the cancel button in the choosing-GUI, cancel the action
    if ($compressedFilePath -eq "Cancel" ) {
        Clear-Host
        return        
    }
    # Check if the Path is not empty and it's valid
    if ([string]::IsNullOrEmpty($compressedFilePath) -or !(Test-Path $compressedFilePath) ) {
        failed "File path is not vaild"
        return
    }
    if (!(Test-DriveStorage $compressedFilePath) ) {
        Read-Host "Press [ENTER] to continue"
        Clear-Host
        return
    }

    $compressedFileTarName = ((Split-Path $compressedFilePath -Leaf) -split "\.")[0]
    
    # Check if the file is really a "tar.xz" archive
    $ErrorActionPreference = "SilentlyContinue"
    $itemExt = Get-CompressedFileExt $compressedFilePath
    $ErrorActionPreference = "Continue"
    if ($itemExt -ne "xz") {
        Write-Host "Error: The file isn't a .xz file" -ForegroundColor Red
        read-host "Press ENTER to return to menu" 
        Clear-Host
        return
    }
    # Check if archive contains a .tar file
    $7zOutput = Invoke-Expression "$7z l `"$compressedFilePath`""
    if (!((select-string " *.tar" -InputObject $7zOutput -Quiet) -and (select-string " 1 files" -InputObject $7zOutput -Quiet))) {
        Write-Host "Error: The file doesn't contain .tar file inside it" -ForegroundColor Red
        read-host "Press ENTER to return to menu" 
        Clear-Host
        return
    }   

    $Description = "Choose a folder to put the extracted CAT folder. Note: The extracted output will include root folder for CAT"    
    $ExtractionDestination = Get-Folder -Description $Description -initialDirectory "$env:USERPROFILE\Desktop" -ReturnCancelIfCanceled
    if ($ExtractionDestination -eq "Cancel") {
        Clear-Host
        return
    }
    Write-Host "Extracting files to $ExtractionDestination..."

    # Extract the tar from the tar.xz file, and then extract the files from that tar file
    # -bs0 hide all output for the proccess
    # -aoa means overwrite All existing files without prompt
    $cmd = "$7z x `"$compressedFilePath`"  -o$ExtractionDestination -txz -aoa -bso0"
    Invoke-Expression $cmd
    # Check the exit code of the 7z execution
    if ($LASTEXITCODE -ge 2) {
        Write-Host "Error occurred" -ForegroundColor Red
        read-host "Press ENTER to continue"
        Clear-Host
        return
    }
    # After we extracted the tar file from the tar.xz, we dont need the tar.xz anyomre
    Remove-Item -Path "$compressedFilePath" -Force 

    # The tar supposed to include the root folder. We need the name of this folder for further use of $Tools parametr
    $7zOutput = Invoke-Expression "$7z l `"$ExtractionDestination\$compressedFileTarName.tar`""
    $regex = '\d{4}.*D\.\..*0\ \ +0\ \ +'
    $CompressedRootFolderName = ($7zOutput | Select-String -Pattern $regex)[0] -replace $regex
    
    # Extract the files from the tar file to the destination
    # -aos skips extracting of existing files
    $cmd = "$7z x $ExtractionDestination\$compressedFileTarName.tar -o$ExtractionDestination -ttar -aos -bso0" 
    Invoke-Expression $cmd
    if ($LASTEXITCODE -ge 2) {
        Write-Host "Error occurred" -ForegroundColor Red
        return
    }

    Write-Host "Folders from compressed file extracted successfully" -ForegroundColor Green
    Write-Host "Regitering the path of scoop to PATH environmental variable and updating the shims..." -ForegroundColor Green
    Remove-Item -Path "$ExtractionDestination\$compressedFileTarName.tar" -Force 

    $Tools = "$ExtractionDestination\$CompressedRootFolderName\Tools"
    Set-Vars
    Update-Shims 
    Register-Path
    Install-ExternalModules
    Install-NonPortableApps

    write-host "" -BackgroundColor Yellow -ForegroundColor Black
    write-host "Note: Any other sessions of Powershell needs to be closed and reopen to apply the changes" -BackgroundColor Yellow -ForegroundColor Black
    write-host "" -BackgroundColor Yellow -ForegroundColor Black
    read-host "Press ENTER to continue"
    Clear-Host
}

<#
.SYNOPSIS
Returns the extension of an archive file
#>
function Get-CompressedFileExt {
    param ([Parameter(Mandatory = $true)]
        $Path
    )
    $item = (Invoke-Expression "$7z l $path" | select-string "Type = ")
    return $item -replace "Type = "
}
<#
.description
    Retrun 7za.exe file
    if it doesnt exist, get it by browsing or by download it    
#>
function Get-7z {
    if (($null -ne $7z) -and ( Test-Path $7z)) {
        return $7z
    }
    Write-Host "Searching for 7zip..."
    Write-Host ""
    $7zexeResults = Get-ChildItem -Path $PSScriptroot -Filter "*7za*" -File -Recurse -Depth 10 | Where-Object { $_.name -match "7za\.exe`$" } 
    # If 7za.exe is not found, extract it from the zip
    if ($null -eq $7zexeResults ) {
        if (Test-Path -Path "$PSScriptroot\7z.zip") {
            Expand-Archive "$PSScriptroot\7z.zip" -DestinationPath $PSScriptroot\7z\ -Force
            return "$PSScriptroot\7z\x64\7za.exe"
        } else {
            return Get-7zEXEManually 
        }
    }

    # If array is returned, means there is more than one result. So we need to search for the one that is a 7zip exe file
    # After that, we will search if there is file that placed in a folder named 64, because its the only indication that the version is for 64bit
    if ($7zexeResults.GetType().BaseType.Name -eq "Array") {
        $ResultFilteredList = New-Object System.Collections.ArrayList
        foreach ($file in $7zexeResults) {
            # Searching in the results array for exe file who is indeed a 7zip exe file and add it to the array
            if ($file.VersionInfo.InternalName -match "7za?") {
                $ResultFilteredList.Add($file) | Out-Null
            }
        }
        if ($ResultFilteredList.Count -gt 0) {
            # Check if there is 64bit version, and if it does, return it
            foreach ($file in $ResultFilteredList) {
                if ($file.Directory.Name -match ".?64") {
                    return $file.FullName
                }   
            }
            return $ResultFilteredList[0].FullName
        } else { return Get-7zEXEManually }
    } 
    
    # If there is only one exe file called 7z or 7za
    elseif ($7zexeResults.VersionInfo.InternalName -match "7za?") { 
        return $7zexeResults.FullName
    } else {
        return Get-7zEXEManually
    }
}
<#
.DESCRIPTION
If 7z cannot be found automatically in root or subfolders, then user can provide it manually
Or it can be downloaded automatically from the internet
#>
function Get-7zEXEManually {
    write-host "Cannot find 7z, if you have it, type [S] to select it. If not, type [D] and it will be downloaded automatically"
    $userInput = Read-Host
    if ($userInput -eq "D") {
        dl 'https://raw.githubusercontent.com/contigon/Downloads/master/7z1900.zip' "$PSScriptroot\7z.zip"
        Expand-Archive -Path "$PSScriptroot\7z.zip" -DestinationPath "$psscriptroot\7z\" -Force
        if (($?) -and (Test-Path "$PSScriptroot\7z\x64\7za.exe")) {
            Remove-Item "$PSScriptroot\7z.zip" -Force
            return "$PSScriptroot\7z\x64\7za.exe"
        }
        # Manually search for 7zip.exe by user
    } elseif ($userInput -eq "S") {
        do {
            $7zExeFile = Get-FileName "exe"
            if ($7zExeFile -eq "Cancel") { Clear-Host; exit }
            elseif (!((Get-ItemProperty $7zExeFile).VersionInfo.internalname -match "7za?")) {
                Write-Host "File is not a 7z exe file! Press [ENTER] to select again" -ForegroundColor Red
                Clear-Host
                return
            }
        }while (!((Get-ItemProperty $7zExeFile).VersionInfo.internalname -match "7za?"))
        return $7zExeFile 
    } else {
        # Consider to delete this else, or adding here something for the option of the user havnt typed one of the listed options
    }    
}
function Update-ScoopPath {
    Write-Host "`n"
    Write-Host "This will update Scoop path in all necessary environmental things"
    Write-Host "------------------------------------------------------------------------------------"
    Write-Host ""
    $Description = "Choose the folder of the tools, where scoop and GlobalScoopApps are located"    
    $ToolsFolder = Get-Folder -Description $Description -initialDirectory "$PSScriptRoot"

    if (!(Test-Path -Path "$ToolsFolder\GlobalScoopApps")) {
        Write-Host "Error, folder `"GlobalScoopApps`" wasn't found in directory $ToolsFolder"  -ForegroundColor Red
        read-host "Press ENTER to continue"
        Clear-Host
        return
    }

    $Tools = $ToolsFolder
    Set-Vars
    Update-Shims 
    Register-Path
    
    write-host "" -BackgroundColor Yellow -ForegroundColor Black
    write-host "Note: Any other sessions of Powershell needs to be closed and reopen to apply the changes" -BackgroundColor Yellow -ForegroundColor Black
    write-host "" -BackgroundColor Yellow -ForegroundColor Black
    read-host "Press ENTER to continue"
    Clear-Host    
}

<#
.SYNOPSIS
The function make sure that the drive which the archive file in, has enough space to contain the exported data

.DESCRIPTION
The needed space calculation is made by the inner (tar) file size (real uncompressed size) 2 times,
because first the tar file needs to be extracted, and then all its data extracted from it.
#>
function Test-DriveStorage {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $TarXzPath
    )
    $DestinationDrive = ($TarXzPath -split '\\')[0]
    $Drive = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $DestinationDrive }
    $DriveFreeSpace = [Math]::Round($Drive.FreeSpace / 1MB)
    
    $7z = Get-7z
    Write-Host "Checking file size..."
    $cmd = "$7z l $TarXzPath"
    $7zOutput = Invoke-Expression $cmd
    if ($LASTEXITCODE -le 1) {
        $DecompressedSize = [Math]::Round((($7zOutput | select-string -Pattern '.*tar$').toString() -split " " | select-string -Pattern '\d').Line[0] / 1MB)
    } else {
        Write-Host "Error occurred" -ForegroundColor Red
        return $false
    }
    if (($DriveFreeSpace - (($DecompressedSize) * 2)) -lt 0) {
        Write-Host "The real size of the compressed file is $DecompressedSize MB" -ForegroundColor Red
        Write-Host "Error: Not enough space left in drive" -ForegroundColor Red
        return $false
    }
    $Output = "It's OK, there is enough space for the imported CAT and its tools in drive " + $Drive.DeviceID
    Write-Host $Output -ForegroundColor Green
    return $true
}
function Get-FileName {
    # $Extensions param is a strings array of requested extensions
    # The function take this extensions list and set it in the filter of the file chooser
    # If this paramter is empty, the file chooser set the filter to "All files"
    param (
        [string[]]
        $Extensions,

        [string]
        $ExtensionsExplain
    )
    $FileFilter = "All files (*.*)| *.*"
    if ($Extensions.Count -gt 0) {
        [string]$extsString = ($Extensions -join ";*.")
        $extsString = $extsString.Insert(0, '*.')
        $FileFilter = $FileFilter.Insert(0, "$extsString|")
        $FileFilter = $FileFilter.Insert(0, "$ExtensionsExplain|")
    } 

    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.filter = $FileFilter
    $cancel = $OpenFileDialog.ShowDialog()
    if ( $cancel -ne "Cancel") {
        return $OpenFileDialog.filename   
    } else {
        return $cancel 
    } 
}
Function Get-Folder {
    param (
        $initialDirectory,        
        # You can add a description to the folder choose window
        $Description,
        # An option to disable the "Add new folder button"
        [switch] $DisableNewFolder,
        # If paramter is present, return "Cancel" if user pressed the Cancel or "X" buttons
        [switch] $ReturnCancelIfCanceled
    ) 
    [void] [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
    $FolderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $FolderBrowserDialog.RootFolder = 'MyComputer'
    $FolderBrowserDialog.ShowNewFolderButton = !$DisableNewFolder
    if (![string]::IsNullOrEmpty($Description)) { $FolderBrowserDialog.Description = $Description }
    if ($initialDirectory) { $FolderBrowserDialog.SelectedPath = $initialDirectory }
    $Topmost = New-Object System.Windows.Forms.Form
    $Topmost.TopMost = $True
    $Topmost.MinimizeBox = $True
    $ButtonPressed = $FolderBrowserDialog.ShowDialog($Topmost) 
    if ($ReturnCancelIfCanceled -and ($ButtonPressed -eq "Cancel")) { return "Cancel" }
    return $FolderBrowserDialog.SelectedPath
}
function Install-NonPortableApps {
    Import-Module "FileSplitter"
    Rename-Item "$Tools\scoop\Cache" -NewName 'OldCache' -Force
    Rename-Item "$Tools\scoop\TempCache" -NewName 'cache' -Force
    if (Test-Path -Path "$Tools\scoop\InstalledApps.txt") {
        $ToolsToExport = Get-Content -Path "$Tools\scoop\InstalledApps.txt" -Encoding String
        $ScoopExport = (Invoke-Expression "Scoop export") -join "`n"
        $ToolsToExport.foreach({
                if ($ScoopExport -match "$_.*\*global\*") {
                    Invoke-Expression "scoop uninstall $_ -g"    
                } elseif ($ScoopExport -match "$_") {
                    Invoke-Expression "scoop uninstall $_ " 
                }                 
                Invoke-Expression "scoop install $_ -g"    
            })
    }
    
}

<#
.SYNOPSIS
Add Scoop customed extensions of download to cache

.DESCRIPTION
These extension add scoop the feature of download an app's installation files to the cache only,
without the installation procees that supposed to come after that in normal scoop's "install" feature
#>
function Add-ScoopCustomExts {
    Write-Host "Inserting customed files into Scoop..."
    Get-ChildItem "$PSScriptRoot\ScoopAddOns" -Recurse -File | ForEach-Object { 
        if ($_.Name -eq "download.ps1") {
            Copy-Item $_.FullName -Destination "$tools\scoop\apps\Scoop\current\lib" -Force  
        } elseif (($_.Name -eq "scoop-download.ps1")) {
            Copy-Item $_.FullName -Destination "$tools\scoop\apps\Scoop\current\libexec" -Force
        } 
    }    
}
function Install-ExternalModules {
    if (Test-Path "$tools\ExternalModules") {
        Write-Host "Copying modules to user's modules path..."
        $dest = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules"
        Invoke-Expression "robocopy $tools\ExternalModules $dest /mir /copyall /nfl /ndl /njh /njs"
        if ($LASTEXITCODE -le 1) {
            Write-Host "Copied successfully" -ForegroundColor Green
        } else {
            Write-Host "Error occurred in modules copying" -ForegroundColor Red            
        }
    }    
}

Import-Scoop
