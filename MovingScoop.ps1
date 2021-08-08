
<#
    Configures scoop and its installed apps to be known by Windows
    Scoop directory needs to be place in ".\Tools\Scoop\apps\scoop"
    If you want more tools to be known they and their shims have to be in ".\Tools\Scoop\apps\scoop"
        or in ".\Tools\GlobalScoopApps" if they are global
#>
. "$psscriptroot\Tools\Scoop\apps\scoop\current\lib\core.ps1"
. "$psscriptroot\Tools\Scoop\apps\scoop\current\lib\install.ps1"
Import-Module $PSScriptRoot\CyberFunctions.psm1
function updateShims {
    for ($i = 0; $i -lt 2; $i++) {
        if ($i -eq 0) {
            $shimsPath = "$tools\GlobalScoopApps\shims"
        } else {
            $shimsPath = "$tools\Scoop\shims"
        }
        Get-ChildItem $shimsPath | ForEach-Object {
            write-host $_.FullName -ForegroundColor DarkMagenta
            if ($_.Name -like '*.shim') {
                $file = $_.FullName
                $regex = '.:\\.*Tools'
                (Get-Content $file) -replace $regex, $tools | Set-Content $file
            }
        }    
    }   
}

function setVars {
    $global:scoopDir = "$tools\Scoop"
    $env:SCOOP_GLOBAL = "$tools\GlobalScoopApps"
    [Environment]::SetEnvironmentVariable("SCOOP_GLOBAL", $env:SCOOP_GLOBAL, "Machine")
    $env:SCOOP = $scoopDir
    [Environment]::SetEnvironmentVariable("SCOOP", $env:SCOOP, "MACHINE")    
}
function ensure {    
    ensure_in_path $env:SCOOP_GLOBAL\shims $true
    ensure_in_path $env:SCOOP\shims
}
$tools = "$PSScriptRoot\Tools"

do {
    $help = @"
        The options - it's recommended to do them on by one by order:
        1 - set environments variables
        2 - update shims
        3 - ensure scoop and scoop_global in PATH
"@
    Write-Host $help
    $userInput = read-host "Choose an action: "
    switch ($userInput) {
        1 { setVars }
        2 { updateShims }
        3 { ensure }
    }

}while ($userinput -ne 99) 
    