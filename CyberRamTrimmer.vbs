Dim objShell,strArgs , i
for i = 0 to WScript.Arguments.length - 1
    strArgs = strArgs & WScript.Arguments(i) & " "
next
Set objShell = CreateObject("WScript.Shell")
objShell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -File ""C:\CyberAuditPS2020\CyberRamTrimmer.ps1"" -ThisSession -scheduled " & strArgs , 0
