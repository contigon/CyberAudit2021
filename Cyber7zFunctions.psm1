function Get-7z {
    Write-Host "Searching for 7zip..."
    Write-Host ""
    $7zexeResults = Get-ChildItem -Path $PSScriptroot -Filter "*7za*" -File -Recurse -Depth 10 | Where-Object { $_.name -match "7za\.exe`$" } 
    # If 7za.exe is not found, extract it from the zip
    if ($null -eq $7zexeResults ) {
        if (Test-Path -Path "$PSScriptroot\Tools\7z.zip") {
            Expand-Archive "$PSScriptroot\Tools\7z.zip" -DestinationPath "$PSScriptroot\Tools\7z\" -Force
            return "$PSScriptroot\Tools\7z\x64\7za.exe"
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
        dl 'https://raw.githubusercontent.com/contigon/Downloads/master/7z1900.zip' "$PSScriptroot\Tools\7z.zip"
        Expand-Archive -Path "$PSScriptroot\Tools\7z.zip" -DestinationPath "$psscriptroot\Tools\7z\" -Force
        if (($?) -and (Test-Path "$PSScriptroot\Tools\7z\x64\7za.exe")) {
            Remove-Item "$PSScriptroot\Tools\7z.zip" -Force
            return "$PSScriptroot\Tools\7z\x64\7za.exe"
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

<#
.SYNOPSIS
Returns the real compression type of an archive file, in case of wrong file postfix
#>
function Get-CompressedFileExt {
    param ([Parameter(Mandatory = $true)]
        $Path
    )
    $item = (Invoke-Expression "$7z l $path" | select-string "Type = ")
    return $item -replace "Type = "
}

<#
.SYNOPSIS
The function make sure that the drive which the archive file is in it, has enough space to contain the exported data

.DESCRIPTION


.NOTES
Works only if compressed file has only one file in it
#>
function Test-DriveStorage {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $packageFilePath,
		
        [string]
        $7z
    )
    $DestinationDrive = [System.IO.Path]::GetPathRoot($packageFilePath) -replace "\\"
    $Drive = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $DestinationDrive }
    $DriveFreeSpace = [Math]::Round($Drive.FreeSpace / 1MB)
    
    if (!$7z) { $7z = Get-7z }
    Write-Host "Checking file size..."
    $cmd = "$7z l $packageFilePath"
    $7zOutput = Invoke-Expression $cmd
    if ($LASTEXITCODE -le 1) {
        $DecompressedSize = [Math]::Round((($7zOutput | select-string -Pattern 'files$') -split '\s+')[2] / 1MB)
    } else {
        Write-Host "Error occurred" -ForegroundColor Red
        return $false
    }
    # If the file is tar.xz, the needed space calculation is made by the inner file size (real uncompressed size) 2 times,
    # because first the tar file needs to be extracted, and then all its data extracted from it.
    if ((Split-Path -Path $packageFilePath -Leaf) -like "tar.xz") { $mulFactor = 2 }
    else { $mulFactor = 1 }

    if (($DriveFreeSpace - (($DecompressedSize) * $mulFactor)) -lt 0) {
        Write-Host "Error: Not enough space left in drive" -ForegroundColor Red
        Write-Host "The real size of the compressed file is $DecompressedSize MB" -ForegroundColor Red
        Write-Host "Drive $DestinationDrive has only $DriveFreeSpace free MB" -ForegroundColor Red
        
        return $false
    }
    $Output = "Great, there is enough space in drive " + $Drive.DeviceID
    Write-Host $Output -ForegroundColor Green
    return $true
}