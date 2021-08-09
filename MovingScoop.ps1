
<#
    Configures scoop and its installed apps to be known by Windows, if they not installed in regular way
    Scoop directory needs to be placed in ".\Tools\Scoop\apps\scoop"
    If you want more tools to be known they and their shims have to be in ".\Tools\Scoop\apps\scoop"
        or in ".\Tools\GlobalScoopApps" if they are global
#>
. "$psscriptroot\Tools\Scoop\apps\scoop\current\lib\core.ps1"
. "$psscriptroot\Tools\Scoop\apps\scoop\current\lib\install.ps1"
Import-Module $PSScriptRoot\CyberFunctions.psm1
function updateShims {
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
            Write-Host "Updating $whatShims shims:"
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
function setVars {
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
function ensureInPath {    
    ensure_in_path $env:SCOOP_GLOBAL\shims $true
    ensure_in_path $env:SCOOP\shims
    read-host "Press ENTER to continue" 
    Clear-Host
}

$tools = "$PSScriptRoot\Tools"
[Int] $userInput = 0
while ($userinput -ne 99) {
    $help = @"
  
        Fix scoop and its tools if you copied them from another computer,
        and want them be accessible by CMD and Powershell

        Baseline folder is $PSScriptroot 

        1. Variables        | Set environments variables
        2. Shims            | Update all shims to the current absolute address of Tool
        3. Ensure in PATH   | ensure scoop and scoop_global in PATH
        
        - it's recommended to all commands one by one by order

"@
    Write-Host $help -ForegroundColor Yellow
    $userInput = read-host "Choose an action"
    switch ($userInput) {
        1 { setVars }
        2 { updateShims }
        3 { ensureInPath }
    }
    
} 
    