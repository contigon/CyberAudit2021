<#
    Configures scoop and its installed apps to be known by Windows, if they not installed in regular way,
    Scoop directory needs to be placed in ".\Tools\Scoop\apps\scoop".
    If you want more tools to be known, they and their shims have to be in ".\Tools\Scoop\"
    or in ".\Tools\GlobalScoopApps\" if they are global
#>
#requires -RunAsAdministrator
Import-Module $PSScriptRoot\CyberFunctions.psm1
$Tools = "$PSScriptRoot\Tools"
$7z = $null

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
            Write-Host "No $whatShims sihms found" -ForegroundColor Red
        } else {            
            Write-Host "Updating $whatShims shims with this path:" -ForegroundColor Yellow
            Write-Host "$tools$appsRelativePath" -ForegroundColor Yellow
            foreach ($item in $shimsToUpdate) {
                if (($item.Name -like '*.shim') -or ($item.Name -like '*.cmd')) {
                    write-host $item.FullName -ForegroundColor DarkMagenta
                    $file = $item.FullName
                    $regex = '.:\\.*Tools\\(GlobalScoopApps|Scoop)'
                    (Get-Content $file) -replace $regex, "$tools$appsRelativePath" | Set-Content $file
                }
            }    
        }   
    }
    read-host "Press ENTER to continue" 
    # Clear-Host
}
function Set-Vars {
    $global:scoopDir = "$tools\Scoop"
    $env:SCOOP_GLOBAL = "$tools\GlobalScoopApps"
    [Environment]::SetEnvironmentVariable("SCOOP_GLOBAL", $env:SCOOP_GLOBAL, "Machine")
    $env:SCOOP = $scoopDir
    [Environment]::SetEnvironmentVariable("SCOOP", $env:SCOOP, "MACHINE")    

    Write-Host "Done. All global veriables are set to the current absolute path:" -ForegroundColor Green
    Write-Host "$PSScriptRoot" -ForegroundColor DarkYellow
    read-host "Press ENTER to continue" 
    # Clear-Host
}
function Register-Path {    
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
    Read-Host "Press ENTER to continue" 
    # Clear-Host
}
function Import-Scoop {
    $userInput = Read-Host "Press [ENTER] if your extracted file contains whole cat and scoop, or type [Scoop] if it contains only scoop's tools folder"
    [boolean]$OnlyScoop = ($userInput -eq "Scoop")
    $7z = Get-7z | ForEach-Object { $_.replace(' ', '` ') }
    
    # Show a GUI to choose the compressed file that supposed to contain the Tools
    Write-Host "A file selection window will be opened. Select the tar.xz compressed file"
    Read-Host "Press [ENTER] to continue"
    $compressedFilePath = Get-FileName  -Extensions "tar.xz" -ExtensionsExplain "tar.xz compressed files"
    
    
    # If user pressed the cancel button in the choose-GUI, cancel the action
    if ($compressedFilePath -eq "Cancel" ) {
        return        
    }
    # Check if the Path is not empty and it's valid
    if ([string]::IsNullOrEmpty($compressedFilePath) -or !(Test-Path $compressedFilePath) ) {
        failed "File path is not vaild"
        return
    }
    
    $compressedFileTarName = ((Split-Path $compressedFilePath -Leaf) -split "\.")[0]
    
    
    # Check if the file is really a "tar.xz" archive
    $ErrorActionPreference = "SilentlyContinue"
    $itemExt = Get-CompressedFileExt $compressedFilePath
    $ErrorActionPreference = "Continue"
    if ($itemExt -ne "xz") {
        failed "The file isn't a .xz file"
        read-host "Press ENTER to return to menu" 
        #   Clear-Host
        return
    }
    # Check if archive contains a .tar file
    $7zOutput = Invoke-Expression "$7z l `"$compressedFilePath`""
    if (!((select-string " *.tar" -InputObject $7zOutput -Quiet) -and (select-string " 1 files" -InputObject $7zOutput -Quiet))) {
        failed "The file doesn't contain .tar file inside it"         
        read-host "Press ENTER to return to menu" 
        #    Clear-Host
        return
    }
    
    if ($OnlyScoop) { 
        $Description = "Choose a folder to the extracted files. Note: a new folder named `"Tools`" will be created at this directory"    
        $ExtractionDestination = Get-Folder -Description $Description -initialDirectory "$env:USERPROFILE\Desktop"
        $ExtractionDestination = New-Item -ItemType Directory -Path $ExtractionDestination -Name "Tools" -Force
    } else {
        $Description = "Choose a folder to put the extracted CAT folder. Note: The extracted output will include root folder for CAT"    
        $ExtractionDestination = Get-Folder -Description $Description -initialDirectory "$env:USERPROFILE\Desktop"
    }

    # Extract the tar from the tar.xz file, and then extract the files from that Tools.tar file
    $cmd = "$7z x `"$compressedFilePath`"  -o$ExtractionDestination -txz -aoa"
    Invoke-Expression $cmd
    # Check the exit code of the 7z execution
    if ($LASTEXITCODE -ge 2) {
        Write-Host "Error occured" -ForegroundColor Red
        return
    }
    # If the tar contains whole CAT, it supposed to include the root folder. We will need the name of this folder later
    if (!$OnlyScoop) {
        $7zOutput = Invoke-Expression "$7z l `"$ExtractionDestination\$compressedFileTarName.tar`""
        if (select-string " 1 files" -InputObject $7zOutput -Quiet) {
            $regex = '\d{4}.*D\.\..*0\ \ +0\ \ +'
            $CompressedRootFolderName = ($7zOutput | Select-String -Pattern $regex)[0] -replace $regex
        }
    }
    
    # Extract the files from the tar file to the destination
    $cmd = "$7z x $ExtractionDestination\$compressedFileTarName.tar -o$ExtractionDestination -ttar -aos" 
    Invoke-Expression $cmd
    if ($LASTEXITCODE -ge 2) {
        Write-Host "Error occured" -ForegroundColor Red
        return
    }

    Write-Host "Folders from compressed file extracted successfuly" -ForegroundColor Green
    Write-Host "Regitering the path of scoop to PATH environmental variable and updating the shims..." -ForegroundColor Green
    Remove-Item -Path "$ExtractionDestination\$compressedFileTarName.tar" -Force 
    $Tools = "$ExtractionDestination\Tools"
    if ($OnlyScoop) {
        $Tools = "$ExtractionDestination\$CompressedRootFolderName\Tools"
    }
    
    Set-Vars
    Update-Shims 
    Register-Path
    

    read-host "Press ENTER to continue"
    #   Clear-Host
}

function Export-Scoop {
    #TODO: Add a function to compress the Tools directory of an existing CAT and scoop with installed programs

    $7z = Get-7z | ForEach-Object { $_.replace(' ', '` ') }
    write-host "7z path is: $7z"
    Write-Host "`nCleaning Scoop cache..."
    Invoke-Expression "Scoop cache rm *"

    $userInput = Read-Host "Press [ENTER] to export CAT, scoop and all the tools, or type [Tools] to export only scoop and tools"
    if ($userInput -ne "Tools") {
        $FolderToArchive = "$psscriptroot".Replace(' ', '` ')
    } else {
        $FolderToArchive = "$PSScriptRoot\Tools".Replace(' ', '` ')
    }
    Write-Host "`nA window will open to choose a folder to place the compressed file"
    Read-Host "Press [ENTER] to continue"
    $ArchiveDestinationFolder = Get-Folder -Description "Select a folder for the exported archive" -ReturnCancelIfCanceled | ForEach-Object { $_.replace(' ', '` ') }
    if ($null -ne $7z) {
        $cmd = "$7z a -ttar -snl -bsp2 $ArchiveDestinationFolder\CAT.tar $FolderToArchive -x!*\cache\*"
        Invoke-Expression $cmd
        if ($LASTEXITCODE -ge 2) { Write-Host "An error occured" -ForegroundColor Red }
        else {
            $cmd = "$7z a -txz -bsp2 -sdel $ArchiveDestinationFolder\CAT.tar.xz $ArchiveDestinationFolder\CAT.tar"
            Invoke-Expression $cmd
            if ($LASTEXITCODE -le 1){
                Write-Host "Exported successfuly to this file:" -ForegroundColor Green 
                Write-Host "$ArchiveDestinationFolder\CAT.tar.xz" -ForegroundColor Green 
            }
            else {
                Write-Host "An error occured" -ForegroundColor Red
            }
        }
    }    
}
function Get-CompressedFileExt {
    param ($Path)
    $item = (Invoke-Expression "$7z l $path" | select-string "Type = ")
    return $item -replace "Type = "
}
<#
.description
    Retrun 7z.exe file
    if it doesnt exist, get it by browsing or by download it    
#>
function Get-7z {
    # Checks if 7z is installed as a cmdlet
    if (Get-Command "7z" -ErrorAction SilentlyContinue) {
        return "7z"
    }
    Write-Host "Searching for 7zip..."
    $7zexeResults = Get-ChildItem -Path $PSScriptroot -Filter "*7z*" -File -Recurse | Where-Object { $_.name -match "7za?\.exe`$" } 
    if ( $null -eq $7zexeResults ) { return Get-7zEXEManually }

    # If array is returned, means there is more than one result. So we need to search for the one that is a 7zip exe file
    # After that, we will search if there is file that placed in a folder named 64, because its the only indication that the version is for 64bit
    if ($7zexeResults.GetType().BaseType.Name -eq "Array") {
        $ResultFilteredList = New-Object System.Collections.ArrayList
        foreach ($file in $7zexeResults) {
            # Searching in the results array for exe file who is indeed a 7zip exe file and add it to the array
            if ($file.VersionInfo.InternalName -match "7za?") {
                Write-Host $file.FullName -BackgroundColor DarkCyan
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
            if ($7zExeFile -eq "Cancel") { exit }
            elseif (!((Get-ItemProperty $7zExeFile).VersionInfo.internalname -match "7za?")) {
                Write-Host "File is not a 7z exe file! Press [ENTER] to select again" -ForegroundColor Red
                Read-Host
            }
        }while (!((Get-ItemProperty $7zExeFile).VersionInfo.internalname -match "7za?"))
        return $7zExeFile 
    } else {
        # Consider to delete this else, or adding here something for the option of the user havnt typed one of the listed options
    }    
}
[Int] $userInput = 0
while ($userinput -ne 99) {
    $help = @"
  
    CAT with scoop - Import and Export
    ----------------------------------

    1. Export CAT with Scoop Tools  | Export CAT with all its installed programs to a *.tar.xz file
                                      in order to import them on another computer
    2. Import CAT with Scoop Tools  | Import an existing *.tar.xz that contains CAT with scoop and its programs
        
"@
    Write-Host $help
    $userInput = read-host "Choose an action"
    switch ($userInput) {
        1 { Import-Scoop }
        2 { Export-Scoop }
    }
} 