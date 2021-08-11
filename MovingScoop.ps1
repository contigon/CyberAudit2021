
<#
    Configures scoop and its installed apps to be known by Windows, if they not installed in regular way
    Scoop directory needs to be placed in ".\Tools\Scoop\apps\scoop"
    If you want more tools to be known they and their shims have to be in ".\Tools\Scoop\apps\scoop"
        or in ".\Tools\GlobalScoopApps" if they are global
#>
$tools = "$PSScriptRoot\Tools"
try {
    . "$psscriptroot\Tools\Scoop\apps\scoop\current\lib\core.ps1"
    . "$psscriptroot\Tools\Scoop\apps\scoop\current\lib\install.ps1"
} catch {
    Write-Host "Scoop was not found where it supposed to be" -ForegroundColor Red
    Write-Host "Please place scoop folder in " -ForegroundColor Red -NoNewline
    Write-Host "$psscriptroot\Tools\Scoop\apps\" -ForegroundColor Yellow
}
Import-Module $PSScriptRoot\CyberFunctions.psm1
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
    Clear-Host
}
function Set-Vars {
    $global:scoopDir = "$tools\Scoop"
    $env:SCOOP_GLOBAL = "$tools\GlobalScoopApps"
    [Environment]::SetEnvironmentVariable("SCOOP_GLOBAL", $env:SCOOP_GLOBAL, "Machine")
    $env:SCOOP = $scoopDir
    [Environment]::SetEnvironmentVariable("SCOOP", $env:SCOOP, "MACHINE")    

    Write-Host "Done. All veriables are set to the current absolute path:" -ForegroundColor Yellow
    Write-Host "$PSScriptRoot" -ForegroundColor DarkYellow
    read-host "Press ENTER to continue" 
    Clear-Host
}
function Register-Path {    
    ensure_in_path $env:SCOOP_GLOBAL\shims $true
    ensure_in_path $env:SCOOP\shims
    Read-Host "Press ENTER to continue" 
    Clear-Host
}
function Import-Scoop {
    #Expand-Archive -Path "$PSScriptRoot\7z.zip" -DestinationPath "$PSScriptRoot"
    $compressedFilePath = Get-FileName "tar.xz"
    $compressedFileParentPath = Split-Path $compressedFilePath
    try {
        if (!(Test-Path $compressedFilePath) ) {
            throw "ERROR: File path is not vaild"
        }
    } catch {
        write-host "EEERRRROOORR"
        return
    }
    $7z = "$PSScriptRoot\7z\x64\7za.exe"

    $cmd = "$7z x $compressedFilePath  -o$compressedFileParentPath -txz"
    Invoke-Expression $cmd
    $cmd = "$7z x $compressedFileParentPath\Tools.tar -o$psscriptroot\YaaniTools -ttar -aos"
    Invoke-Expression $cmd

    <#TODO: Finish the function :
    - Add more bdikot mikrei katze
    - Change from YaaniTools to Tools after the tests
    - Check if the chosen compressed file is realy contains a Tool Directory
    #>
    #TODO: Test the function with a real Tools directory
    #TODO: Add a function to compress the Tools directory of an existing CAT and scoop with installed programs
    
    read-host "Press ENTER to continue" 
    Clear-Host
}

[Int] $userInput = 0
while ($userinput -ne 99) {
    $help = @"
  
        Fix scoop and its tools if you copied them from another computer,
        and want them be accessible by CMD and Powershell

        Baseline folder is $PSScriptroot 

        1. Variables        | Set environments variables
        2. Shims            | Update all shims to the current absolute address of Tool
        3. Ensure in PATH   | ensure scoop and scoop_global in PATH
        4. Import Scoop     | Import an existing Tools.tar.xz that contains scoop with programs
        5. Export Scoop     | Export the installed programs to a tar.xz file in order to import them in another computer
        
        - it's recommended to run all commands one by one by order

"@
    Write-Host $help -ForegroundColor Yellow
    $userInput = read-host "Choose an action"
    switch ($userInput) {
        1 { Set-Vars }
        2 { Update-Shims }
        3 { Register-Path }
        4 { Import-Scoop }
    }
    #TODO: Improve the ugly menu
    #TODO: Implement an Export-Scoop function

    #TODO: add an option to compress all of the apps, and option to extract them to the right place
    <#
    #$7z = "C:\Users\Me\Desktop\7z\7za.exe"
$7z = "7z"
$desktop = "$env:USERPROFILE\Desktop"

$cmd = "$7z a -ttar -snl $desktop\test\archive.tar $desktop\CyberAudit2021\Tools\*"
Invoke-Expression $cmd
$cmd = "$7z a -txz $desktop\test\archive.tar.xz $desktop\test\archive.tar"
Invoke-Expression $cmd

#cmd1 = "$7z a -so 'C:\Users\Me\Desktop\localshim'"
#$cmd2 = "$7z a -txz -si 'C:\Users\Me\desktop\f\c\archive.tgz'"
#Invoke-Expression $cmd1 | Invoke-Expression $cmd2

#$cmd1 = "$7z x -txz -so C:\Users\Me\Desktop\a\archive.tar.xz" 
#$cmd2 = "$7z x -ttar -si -oC:\Users\Me\Desktop\a\"
#Invoke-Expression $cmd1 | Invoke-Expression $cmd2

#$cmd = "$7z x $desktop\test\archive.tar.xz  -o$desktop\test\1\ -txz"
#iex $cmd
#$cmd = "$7z x $desktop\test\1\archive.tar -o$desktop\test\1\ -ttar"
#iex $cmd
  
    
    
    #>
} 
    