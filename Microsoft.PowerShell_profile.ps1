$block = @"
 _____ __   _ _______ ______ 
   |   | \  | |       |     \
 __|__ |  \_| |_____  |_____/ Israel National Cyber Directorate
               
"@
Write-Host $block -ForegroundColor Green
Set-Alias ll Get-ChildItem
function pro {notepad $profile}
function apex {Set-Location -Path .\Tools\RedTeam\Invoke-Apex-master\;Import-Module .\Invoke-Apex.psd1}
#Set-PSReadLineOption -EditMode Emacs
function gg {git add .;git commit -m "new app";git push}
function scc($URL) {scoop create $URL;notepad (Get-ChildItem . -Recurse  -Filter *.json | Sort-Object -Property LastWriteTime -Descending | select -First 1).name}
function sci($appname) {scoop install $appname -g}
function scs {scoop uninstall scoop}
function scu($appname) {scoop uninstall (($appname -replace '.json') -replace '.\\') -g}
function cdp() {cd 'C:\CyberAudit-ProEdition\Tools\CyberAuditBucket'}
function cdsg() {cd 'C:\CyberAuditPS2020\Tools\GlobalScoopApps\apps'}
function cdd() {cd 'C:\CyberAuditPS2020'}
function ss($path,$pattern){Select-String -Path $path -Pattern $pattern}
function bf(){$x="";$files = Get-ChildItem . -Name -Include *.exe;foreach ($f in $files){$x += "[""" + $f + """," + """imp-" + ($f).split(".")[0] + """],"};Write-Host ("[" + ($x).TrimEnd(",") + "]")}
function scn(){Get-ChildItem $env:scoop\cache\*|% {$_.Name.Split('#')[0]}}
function go() {Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/contigon/Downloads/master/go.ps1')}